---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

-- If App property "LuaLoadAllEngineAPI" is FALSE, use this to load and check for required APIs
-- This can improve performance of garbage collection
local availableAPIs = require('Communication/MultiTCPIPServer/helper/checkAPIs') -- check for available APIs
-----------------------------------------------------------
local nameOfModule = 'CSK_MultiTCPIPServer'
--Logger
_G.logger = Log.SharedLogger.create('ModuleLogger')
local json = require("Communication.MultiTCPIPServer.helper.Json")
local scriptParams = Script.getStartArgument() -- Get parameters from model

local multiTCPIPServerInstanceNumber = scriptParams:get('multiTCPIPServerInstanceNumber') -- number of this instance
local multiTCPIPServerInstanceNumberString = tostring(multiTCPIPServerInstanceNumber) -- number of this instance as string

-- Event to forward content from this thread to Controller to show e.g. on UI
Script.serveEvent("CSK_MultiTCPIPServer.OnNewValueToForward".. multiTCPIPServerInstanceNumberString, "MultiTCPIPServer_OnNewValueToForward" .. multiTCPIPServerInstanceNumberString, 'string, auto')
-- Event to forward update of e.g. parameter update to keep data in sync between threads
Script.serveEvent("CSK_MultiTCPIPServer.OnNewValueUpdate" .. multiTCPIPServerInstanceNumberString, "MultiTCPIPServer_OnNewValueUpdate" .. multiTCPIPServerInstanceNumberString, 'int, string, auto, int:?')

local handleTCPIPServer -- TCPIP server handle
local connectedClientsIPs = {} -- array of the IP addresses of the connected clients
local conHandles = {} -- table with connection handles and info of the connected clients
local clientWhitelistsEventsAny = {} -- list of events to be notified when data is received from any clients
local clientWhitelistsEventsFiltered = {} -- list of events to be notified when data is received from clients in the filter of client whitelist
local ipToClientWhitelistNameMap = { -- table containing map of filtered IP addresses to message names for event notification convenience 
  notFiltered = {}
}

local log = {} -- Log of TCP/IP communication

local processingParams = {}
processingParams.listenState = scriptParams:get('listenState')
processingParams.activeInUI = scriptParams:get('activeInUI')
processingParams.interface = scriptParams:get('interface')
processingParams.port = scriptParams:get('port')
processingParams.framing = json.decode(scriptParams:get('framing'))
processingParams.framingBufferSize = json.decode(scriptParams:get('framingBufferSize'))
processingParams.maxConnections = scriptParams:get('maxConnections')
processingParams.transmitAckTimeout = scriptParams:get('transmitAckTimeout')
processingParams.transmitBufferSize = scriptParams:get('transmitBufferSize')
processingParams.transmitTimeout = scriptParams:get('transmitTimeout')
processingParams.clientWhitelists = json.decode(scriptParams:get('clientWhitelists'))
processingParams.clientBroadcasts = json.decode(scriptParams:get('clientBroadcasts'))
processingParams.onReceivedDataEventName = scriptParams:get('onReceivedDataEventName')
processingParams.sendDataFunctionName = scriptParams:get('sendDataFunctionName')
processingParams.forwardEvents = {}
processingParams.broadcastFunction = {}

Script.serveEvent(processingParams.onReceivedDataEventName, processingParams.onReceivedDataEventName, 'string:1:,string:1:,int:1:')

--- Function to notify latest log messages, e.g. to show on UI
local function sendLog()
  local tempLog = ''
  for i=1, #log do
    tempLog = tempLog .. tostring(log[i]) .. '\n'
  end
  if processingParams.activeInUI then
    Script.notifyEvent("MultiTCPIPServer_OnNewValueToForward" .. multiTCPIPServerInstanceNumberString, 'MultiTCPIPServer_OnNewLog', tostring(tempLog))
  end
end

--- Function to forward dynamic table content with connected clients and their quantity to UI.
local function showClientsTable()
  local clientsTable = {}
  if #connectedClientsIPs == 0 then
    clientsTable = {
      {
        DTC_ConnectedClientIPAddress = '-'
      }
    }
  else
    for _, ipAddress in pairs(connectedClientsIPs) do
      table.insert(clientsTable,
        {
          DTC_ConnectedClientIPAddress = ipAddress
        }
      )
    end
  end
  Script.notifyEvent("MultiTCPIPServer_OnNewValueToForward" .. multiTCPIPServerInstanceNumberString, "MultiTCPIPServer_OnNewConnectedClientsTable", json.encode(clientsTable))
  Script.notifyEvent("MultiTCPIPServer_OnNewValueToForward" .. multiTCPIPServerInstanceNumberString, "MultiTCPIPServer_OnNewConnectedClientsNumber", #connectedClientsIPs)
end

local function getConnectedClientsIPs()
  connectedClientsIPs = {}
  for clientIPAddress, _ in pairs(conHandles) do
    table.insert(connectedClientsIPs, clientIPAddress)
  end
  if processingParams.activeInUI then
    showClientsTable()
  end
  return connectedClientsIPs
end
Script.serveFunction("CSK_MultiTCPIPServer.getConnectedClientsIPs" .. multiTCPIPServerInstanceNumberString, getConnectedClientsIPs, "","string:*:")

--- Function called when a new client is connected.
---@param newConHandle TCPIPServer.Connection New connection handle.
local function handleOnConnectionAccepted(newConHandle)
  local conHandleIP, _ = TCPIPServer.Connection.getPeerAddress(newConHandle)
  conHandles[conHandleIP] = newConHandle
  getConnectedClientsIPs()
end

--- Function called when client is disconnected.
---@param oldConHandle TCPIPServer.Connection Disconnected connection handle.
local function handleOnConnectionClosed(oldConHandle)
  local conHandleIP, _ = TCPIPServer.Connection.getPeerAddress(oldConHandle)
  conHandles[conHandleIP] = nil
  if conHandles == nil then
    conHandles = {}
  end
  getConnectedClientsIPs()
end

-- Function called when data is received from client.
---@param conHandle TCPIPServer.Connection Connection handle of a client that sent the data.
---@param data string Received data
local function handleOnReceiveData(conHandle, data)

  local timestamp1 = DateTime.getTimestamp()
  local ipAddress = TCPIPServer.Connection.getPeerAddress(conHandle)
  _G.logger:fine(nameOfModule .. ": Received data from " .. tostring(ipAddress) .. "= " .. data)

  table.insert(log, 1, DateTime.getTime() .. ' - RECV from ' .. tostring(ipAddress) .. ' = ' .. tostring(data))
  if #log == 100 then
    table.remove(log, 100)
  end
  sendLog()

  local timestamp2 = DateTime.getTimestamp()
  for _, eventName in ipairs(clientWhitelistsEventsAny) do
    Script.notifyEvent(eventName, data, ipAddress, timestamp2-timestamp1)
  end
  if clientWhitelistsEventsFiltered[ipAddress] then
    for _, eventName in ipairs(clientWhitelistsEventsFiltered[ipAddress]) do
      Script.notifyEvent(eventName, data, ipAddress, timestamp2-timestamp1)
    end
  end
  Script.notifyEvent(processingParams.onReceivedDataEventName, data, ipAddress, timestamp2-timestamp1)
end

-- Function called to set the messages expected from any or some specific clients and register the respected events.
local function setClientWhitelists()
  ipToClientWhitelistNameMap = {
    notFiltered = {}
  }

  clientWhitelistsEventsAny = {}
  clientWhitelistsEventsFiltered = {}
  for messageName, messageInfo in pairs(processingParams.clientWhitelists) do
    if not Script.isServedAsEvent(messageInfo.eventName) then
      Script.serveEvent(messageInfo.eventName, messageInfo.eventName, 'string:1:,string:1:,int:1:')
    end
    if messageInfo.ipFilterInfo then
      for _, ipAddress in ipairs(messageInfo.ipFilterInfo.filteredIPs) do
        if not clientWhitelistsEventsFiltered[ipAddress] then
          clientWhitelistsEventsFiltered[ipAddress] = {}
        end
        table.insert(clientWhitelistsEventsFiltered[ipAddress], messageInfo.eventName)
        if not ipToClientWhitelistNameMap[ipAddress] then
          ipToClientWhitelistNameMap[ipAddress] = {}
        end
        table.insert(ipToClientWhitelistNameMap[ipAddress], messageName)
      end
    else
      table.insert(ipToClientWhitelistNameMap.notFiltered, messageName)
      table.insert(clientWhitelistsEventsAny, messageInfo.eventName)
    end
  end
end

local function sendData(dataToSend, clientsIPs)
  if not clientsIPs or type(clientsIPs) ~= 'table' then
    clientsIPs = connectedClientsIPs
  else
    if #clientsIPs == 0 then
      clientsIPs = connectedClientsIPs
    end
  end

  local totalNumberOfBytesTransmitted = 0
  for _, ipAddress in ipairs(clientsIPs) do
    if conHandles[ipAddress] then
      local numberOfBytesTransmitted = TCPIPServer.Connection.transmit(conHandles[ipAddress], dataToSend)
      totalNumberOfBytesTransmitted = totalNumberOfBytesTransmitted + numberOfBytesTransmitted

      _G.logger:fine(nameOfModule .. ': Try to send to ' .. tostring(ipAddress) .. ' = ' .. tostring(dataToSend))
      table.insert(log, 1, DateTime.getTime() .. ' - Try to send to ' .. tostring(ipAddress) .. ' = ' .. tostring(dataToSend))
      if #log == 100 then
        table.remove(log, 100)
      end
      sendLog()
    end
  end
  if totalNumberOfBytesTransmitted == 0 then
    _G.logger:warning(nameOfModule.. ': Sending failed instance: ' .. multiTCPIPServerInstanceNumberString .. '; No clients to send data to')

    table.insert(log, 1, DateTime.getTime() .. ' - Sending failed instance: ' .. multiTCPIPServerInstanceNumberString)
    if #log == 100 then
      table.remove(log, 100)
    end
    sendLog()
    return false, 'No clients to send data to'
  end
  return true
end
Script.serveFunction(processingParams.sendDataFunctionName, sendData, "string:1:,string:*:","bool:1:,string:?:")

--- Function only used to forward the content from events to the served function.
--- This is only needed, as deregistering from the event would internally release the served function and would make it uncallable from external.
---@param dataToSend string Data to transmit
---@param clientsIPs string? Optional list of IP addresses of the clients to send the data to. 
local function tempSendData(dataToSend, clientsIPs)
  if clientsIPs then
    sendData(dataToSend, clientsIPs)
  else
    sendData(dataToSend)
  end
end

--- Function called to set the messages to be written to any or some specific clients and serve the respected functions.
local function setClientBroadcasts()
  for messageName, messageInfo in pairs(processingParams.clientBroadcasts) do
    local function sendMessage(dataToWrite)
      if dataToWrite == nil then
        dataToWrite = ''
      end
      local timestamp1 = DateTime.getTimestamp()
      local success, errorMessage
      if processingParams.clientBroadcasts[messageName].ipFilterInfo then
        success, errorMessage = sendData(tostring(dataToWrite), processingParams.clientBroadcasts[messageName].ipFilterInfo.filteredIPs)
      else
        success, errorMessage = sendData(tostring(dataToWrite))
      end
      local timestamp2 = DateTime.getTimestamp()
      return success, timestamp2-timestamp1, errorMessage
    end

    if not Script.isServedAsFunction(messageInfo.functionName) then
      Script.serveFunction(messageInfo.functionName, sendMessage, 'auto:1:', 'bool:1:,int:1:,string:?:')
      processingParams.broadcastFunction[messageName] = sendMessage
    end
    processingParams.clientBroadcasts[messageName].forwardEvents = {}
  end
end

--- Function to start the TCP/IP server
local function startServer()
  handleTCPIPServer = TCPIPServer.create()
  handleTCPIPServer:setPort(processingParams.port)
  handleTCPIPServer:setFraming(
    processingParams.framing[1],
    processingParams.framing[2],
    processingParams.framing[3],
    processingParams.framing[4]
  )
  handleTCPIPServer:setFramingBufferSize(
    processingParams.framingBufferSize[1],
    processingParams.framingBufferSize[2]
  )
  if Engine.getTypeName() ~= 'SICK AppEngine' and Engine.getTypeName() ~= 'Webdisplay' then
    handleTCPIPServer:setInterface(processingParams.interface)
  end
  handleTCPIPServer:setMaxConnections(processingParams.maxConnections)
  handleTCPIPServer:setTransmitAckTimeout(processingParams.transmitAckTimeout)
  handleTCPIPServer:setTransmitBufferSize(processingParams.transmitBufferSize)
  handleTCPIPServer:setTransmitTimeout(processingParams.transmitTimeout)
  handleTCPIPServer:register("OnConnectionAccepted", handleOnConnectionAccepted)
  handleTCPIPServer:register("OnConnectionClosed", handleOnConnectionClosed)
  handleTCPIPServer:register("OnReceive", handleOnReceiveData)
  local listenSuc = handleTCPIPServer:listen()
  _G.logger:fine(nameOfModule .. ": Success to start listening: " .. tostring(listenSuc))
end

--- Function to stop the TCP-IP server
local function stopServer()
  if handleTCPIPServer then
    handleTCPIPServer:deregister("OnConnectionAccepted", handleOnConnectionAccepted)
    handleTCPIPServer:deregister("OnConnectionClosed", handleOnConnectionClosed)
    handleTCPIPServer:deregister("OnReceive", handleOnReceiveData)
    conHandles = {}
    getConnectedClientsIPs()
    Script.releaseObject(handleTCPIPServer)
    handleTCPIPServer = nil
    _G.logger:fine(nameOfModule .. ": Stopped server.")
  end
end

--- Function to handle updates of processing parameters from Controller
---@param multiTCPIPServerNo int Number of instance to update
---@param parameter string Parameter to update
---@param value auto Value of parameter to update
---@param internalValue auto? Custom value
local function handleOnNewProcessingParameter(multiTCPIPServerNo, parameter, value, internalValue)
  if multiTCPIPServerNo == multiTCPIPServerInstanceNumber then -- set parameter only in selected script
    _G.logger:fine(nameOfModule .. ": Update parameter '" .. parameter .. "' of multiTCPIPServerInstanceNo." .. tostring(multiTCPIPServerNo) .. " to value = " .. tostring(value))

    if parameter == 'listenState' then
      processingParams.listenState = value
      if value == true then
        startServer()
      else
        stopServer()
      end
    elseif parameter == 'framingBufferSize' then
      processingParams.framingBufferSize = json.decode(value)
    elseif parameter == 'framing' then
      processingParams.framing =  json.decode(value)
    elseif parameter == 'clientWhitelists' then
      processingParams.clientWhitelists = json.decode(value)
      setClientWhitelists()
    elseif parameter == 'clientBroadcasts' then
      processingParams.clientBroadcasts = json.decode(value)
      setClientBroadcasts()
    elseif parameter == 'addEvent' then

      if internalValue then -- Broadcast info
        -- Check if subTable exists, otherwise create
        if not processingParams.clientBroadcasts[internalValue].forwardEvents then
          processingParams.clientBroadcasts[internalValue].forwardEvents = {}
        end

        if processingParams.clientBroadcasts[internalValue].forwardEvents[value] then
          Script.deregister(processingParams.clientBroadcasts[internalValue].forwardEvents[value], processingParams.broadcastFunction[internalValue])
        end
        processingParams.clientBroadcasts[internalValue].forwardEvents[value] = value
        local suc = Script.register(value, processingParams.broadcastFunction[internalValue])
        _G.logger:fine(nameOfModule .. ": Added event to forward content = " .. value .. " on instance No. " .. multiTCPIPServerInstanceNumberString .. ' to broadcast ' .. tostring(internalValue))
      else
        if processingParams.forwardEvents[value] then
          Script.deregister(processingParams.forwardEvents[value], tempSendData)
        end
        processingParams.forwardEvents[value] = value
        local suc = Script.register(value, tempSendData)
        _G.logger:fine(nameOfModule .. ": Added event to forward content = " .. value .. " on instance No. " .. multiTCPIPServerInstanceNumberString)
      end
    elseif parameter == 'removeEvent' then
      if internalValue then -- Broadcast info
        processingParams.clientBroadcasts[internalValue].forwardEvents[value] = nil
        local suc = Script.deregister(value, processingParams.broadcastFunction[internalValue])
        _G.logger:fine(nameOfModule .. ": Deleted event = " .. tostring(value) .. " on instance No. " .. multiTCPIPServerInstanceNumberString .. ' of broadcast ' .. tostring(internalValue))
      else
        processingParams.forwardEvents[value] = nil
        local suc = Script.deregister(value, tempSendData)
        _G.logger:fine(nameOfModule .. ": Deleted event = " .. tostring(value) .. " on instance No. " .. multiTCPIPServerInstanceNumberString)
      end
    elseif parameter == 'deregisterBroadcast' then
      for eventName, _ in pairs(processingParams.clientBroadcasts[value].forwardEvents) do
        Script.deregister(eventName, processingParams.broadcastFunction[value])
      end
    elseif parameter == 'clearAll' then
      for forwardEvent in pairs(processingParams.forwardEvents) do
        processingParams.forwardEvents[forwardEvent] = nil
        Script.deregister(forwardEvent, tempSendData)
      end
      -- Clear all broadcast functions as well
      for broadcastName, _ in pairs(processingParams.clientBroadcasts) do
        if type(processingParams.clientBroadcasts[broadcastName].forwardEvents) == 'table' then
          for eventName, _ in pairs(processingParams.clientBroadcasts[broadcastName].forwardEvents) do
            Script.deregister(eventName, processingParams.broadcastFunction[broadcastName])
          end
        end
      end
    else
      processingParams[parameter] = value
    end
  elseif parameter == 'activeInUI' then
    processingParams[parameter] = false
  end
end
Script.register("CSK_MultiTCPIPServer.OnNewProcessingParameter", handleOnNewProcessingParameter)
