---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

-- If App property "LuaLoadAllEngineAPI" is FALSE, use this to load and check for required APIs
-- This can improve performance of garbage collection
-- local availableAPIs = require('Mainfolder/Subfolder/helper/checkAPIs') -- check for available APIs
-----------------------------------------------------------
local nameOfModule = 'CSK_MultiTCPIPServer'
--Logger
_G.logger = Log.SharedLogger.create('ModuleLogger')
local json = require("Communication.MultiTCPIPServer.helper.Json")
local scriptParams = Script.getStartArgument() -- Get parameters from model

local multiTCPIPServerInstanceNumber = scriptParams:get('multiTCPIPServerInstanceNumber') -- number of this instance
local multiTCPIPServerInstanceNumberString = tostring(multiTCPIPServerInstanceNumber) -- number of this instance as string


-- Event to notify result of processing
Script.serveEvent("CSK_MultiTCPIPServer.OnNewResult" .. multiTCPIPServerInstanceNumberString, "MultiTCPIPServer_OnNewResult" .. multiTCPIPServerInstanceNumberString, 'bool') -- Edit this accordingly
-- Event to forward content from this thread to Controller to show e.g. on UI
Script.serveEvent("CSK_MultiTCPIPServer.OnNewValueToForward".. multiTCPIPServerInstanceNumberString, "MultiTCPIPServer_OnNewValueToForward" .. multiTCPIPServerInstanceNumberString, 'string, auto')
-- Event to forward update of e.g. parameter update to keep data in sync between threads
Script.serveEvent("CSK_MultiTCPIPServer.OnNewValueUpdate" .. multiTCPIPServerInstanceNumberString, "MultiTCPIPServer_OnNewValueUpdate" .. multiTCPIPServerInstanceNumberString, 'int, string, auto, int:?')

local handleTCPIPServer
local connectedClientsIPs = {}
local conHandles = {}
local receiveDataQueue = Script.Queue.create()
local sendDataQueue = Script.Queue.create()
local readMessagesEventsAny = {}
local readMessagesEventsFiltered = {}
local latestReceivedData = {
  data = '',
  ipAddress = ''
}
local ipToReadMessageNameMap = {
  notFiltered = {}
}
local latestReadMessagesData = {}

local latestSentData = {
  data = '',
  success = false
}
local latestWriteMessagesData = {}

local processingParams = {}
processingParams.listenState = scriptParams:get('listenState')
processingParams.registeredEvent = scriptParams:get('registeredEvent')
processingParams.activeInUI = scriptParams:get('activeInUI')
processingParams.interface = scriptParams:get('interface')
processingParams.port = scriptParams:get('port')
processingParams.framing = json.decode(scriptParams:get('framing'))
processingParams.framingBufferSize = json.decode(scriptParams:get('framingBufferSize'))
processingParams.maxConnections = scriptParams:get('maxConnections')
processingParams.transmitAckTimeout = scriptParams:get('transmitAckTimeout')
processingParams.transmitBufferSize = scriptParams:get('transmitBufferSize')
processingParams.transmitTimeout = scriptParams:get('transmitTimeout')
processingParams.readMessages = json.decode(scriptParams:get('readMessages'))
processingParams.writeMessages = json.decode(scriptParams:get('writeMessages'))
processingParams.onRecevedDataEventName = scriptParams:get('onRecevedDataEventName')
Script.serveEvent(processingParams.onRecevedDataEventName, processingParams.onRecevedDataEventName, 'string:1:,string:1:,int:1:,int:1:,string:?:')
processingParams.sendDataFunctionName = scriptParams:get('sendDataFunctionName')

-- Function to forward dynamic table content with connected clients and their quantity to UI.
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

-- Function to get list of IP addresses of the connected clients.
---@return table? connectedClientsIPs Array with IP addresses of the connected clients.
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

-- Function called when a new client is connected.
---@param newConHandle TCPIPServer.Connection New connection handle.
local function handleOnConnectionAccepted(newConHandle)
  local conHandleIP, _ = TCPIPServer.Connection.getPeerAddress(newConHandle)
  conHandles[conHandleIP] = newConHandle
  getConnectedClientsIPs()
end

-- Function called when client is disconnected.
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
  latestReceivedData = {
    data = data,
    ipAddress = ipAddress
  }
  local queueSize = receiveDataQueue:getSize()
  local errorMessage
  if queueSize > 10 then
    errorMessage = 'Queue is building up: ' .. tostring(queueSize) ..' clearing the queue'
    receiveDataQueue:clear()
  end
  for _, messageName in ipairs(ipToReadMessageNameMap.notFiltered) do
    latestReadMessagesData[messageName] = {
      data = data,
      ipAddress = ipAddress
    }
  end
  if ipToReadMessageNameMap[ipAddress] then
    for _, messageName in pairs(ipToReadMessageNameMap[ipAddress]) do
      latestReadMessagesData[messageName] = {
        data = data,
        ipAddress = ipAddress
      }
    end
  end
  local timestamp2 = DateTime.getTimestamp()
  for _, eventName in ipairs(readMessagesEventsAny) do
    Script.notifyEvent(eventName, data, ipAddress, queueSize, timestamp2-timestamp1, errorMessage)
  end
  if readMessagesEventsFiltered[ipAddress] then
    for _, eventName in ipairs(readMessagesEventsFiltered[ipAddress]) do
      Script.notifyEvent(eventName, data, ipAddress, queueSize, timestamp2-timestamp1, errorMessage)
    end
  end
  Script.notifyEvent(processingParams.onRecevedDataEventName, data, ipAddress, queueSize, timestamp2-timestamp1, errorMessage)
end
receiveDataQueue:setFunction({handleOnReceiveData})

---Get information about the latest received data.
---@return string ipAddress IP address of the client.
---@return string data Latest received data.
local function getLatestGenericReceivedData()
  return latestReceivedData.ipAddress, latestReceivedData.data
end
Script.serveFunction("CSK_MultiTCPIPServer.getLatestGenericReceivedData" .. multiTCPIPServerInstanceNumberString, getLatestGenericReceivedData, '', 'string:1:,string:1:')

---Get information about the latest received data of the specified message.
---@param messageName string Name of the message.
---@return string ipAddress IP address of the client.
---@return string data Latest received data.
local function getLatestReadMessageData(messageName)
  if latestReadMessagesData[messageName] then
    return latestReadMessagesData[messageName].ipAddress, latestReadMessagesData[messageName].data
  else
    return "", ""
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.getLatestReadMessageData" .. multiTCPIPServerInstanceNumberString, getLatestReadMessageData, 'string:1:', 'string:1:,string:1:')


-- Function called to set the messages expected from any or some specific clients and register the respected events.
local function setReadMessages()
  ipToReadMessageNameMap = {
    notFiltered = {}
  }
  latestReadMessagesData = {}
  readMessagesEventsAny = {}
  readMessagesEventsFiltered = {}
  for messageName, messageInfo in pairs(processingParams.readMessages) do
    if not Script.isServedAsEvent(messageInfo.eventName) then
      Script.serveEvent(messageInfo.eventName, messageInfo.eventName, 'string:1:,string:1:,int:1:,int:1:,string:?:')
    end
    if messageInfo.ipFilterInfo and messageInfo.ipFilterInfo.used == true then
      for _, ipAddress in ipairs(messageInfo.ipFilterInfo.filteredIPs) do
        if not readMessagesEventsFiltered[ipAddress] then
          readMessagesEventsFiltered[ipAddress] = {}
        end
        table.insert(readMessagesEventsFiltered[ipAddress], messageInfo.eventName)
        if not ipToReadMessageNameMap[ipAddress] then
          ipToReadMessageNameMap[ipAddress] = {}
        end
        table.insert(ipToReadMessageNameMap[ipAddress], messageName)
      end
    else
      table.insert(ipToReadMessageNameMap.notFiltered, messageName)
      table.insert(readMessagesEventsAny, messageInfo.eventName)
    end
  end
end

-- Function to send the data to clients.
---@param dataToSend string Data to be sent.
---@param clientsIPs table? List of IP addresses of the clients to send the data to. 
---@return bool success Success of sending the data.
---@return string? details Details if sending failed.
local function sendData(dataToSend, clientsIPs)
  if not clientsIPs or #clientsIPs == 0 then
    clientsIPs = connectedClientsIPs
  end
  local totalNumberOfBytesTransmitted = 0
  for _, ipAddress in ipairs(clientsIPs) do
    if conHandles[ipAddress] then
      local numberOfBytesTransmitted = TCPIPServer.Connection.transmit(conHandles[ipAddress], dataToSend)
      totalNumberOfBytesTransmitted = totalNumberOfBytesTransmitted + numberOfBytesTransmitted
    end
  end
  if totalNumberOfBytesTransmitted == 0 then
    _G.logger:warning(nameOfModule.. ' sending failed instance: ' .. multiTCPIPServerInstanceNumberString .. '; No clients to send data to')
    latestSentData = {
      success = false,
      data = dataToSend
    }
    return false, 'No clients to send data to'
  end
  latestSentData = {
    success = true,
    data = dataToSend
  }
  return true
end
Script.serveFunction(processingParams.sendDataFunctionName, sendData, "string:1:,string:*:","bool:1:,string:?:")

-- Function called to set the messages to be written to any or some specific clients and serve the respected functions.
local function setWriteMessages()
  latestWriteMessagesData = {}
  local queueFunctions = {}
  print(json.encode(processingParams.writeMessages))
  for messageName, messageInfo in pairs(processingParams.writeMessages) do
    local function sendMessage(dataToWrite)
      local timestamp1 = DateTime.getTimestamp()
      local success, errorMessage
      if processingParams.writeMessages[messageName].ipFilterInfo and processingParams.writeMessages[messageName].ipFilterInfo.used == true then
        success, errorMessage = sendData(tostring(dataToWrite), processingParams.writeMessages[messageName].ipFilterInfo.filteredIPs)
      else
        success, errorMessage = sendData(tostring(dataToWrite))
      end
      latestWriteMessagesData[messageName] = {
        data = dataToWrite,
        success = success
      }
      local queueSize = sendDataQueue:getSize()
      if queueSize > 10 then
        errorMessage = 'Queue is building up: ' .. tostring(queueSize) ..' clearing the queue'
        sendDataQueue:clear()
      end
      local timestamp2 = DateTime.getTimestamp()
      return success, queueSize, timestamp2-timestamp1, errorMessage
    end
--    local functionName = "CSK_MultiTCPIPServer.sendData" .. multiTCPIPServerInstanceNumberString .. messageName
    if not Script.isServedAsFunction(messageInfo.functionName) then
      Script.serveFunction(messageInfo.functionName, sendMessage, 'auto:1:', 'bool:1:,int:1:,int:1:,string:?:')
    end
    table.insert(queueFunctions, messageInfo.functionName)
  end
  sendDataQueue:setFunction(queueFunctions)
end

---Get information about the latest sent data.
---@return bool ipAddress IP address of the client.
---@return string data Latest received data.
local function getLatestGenericSentData()
  return latestSentData.success, latestSentData.data
end
Script.serveFunction("CSK_MultiTCPIPServer.getLatestGenericSentData" .. multiTCPIPServerInstanceNumberString, getLatestGenericSentData, '', 'bool:1:,string:1:')

---Get information about the latest sent data of the specified message.
---@param messageName string Name of the message.
---@return bool success Success of sending the data.
---@return string data Latest received data.
local function getLatestWriteMessageData(messageName)
  if latestWriteMessagesData[messageName] then
    return latestWriteMessagesData[messageName].success, latestWriteMessagesData[messageName].data
  else
    return false, ""
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.getLatestWriteMessageData" .. multiTCPIPServerInstanceNumberString, getLatestWriteMessageData, 'string:1:', 'bool:1:,string:1:')


-- Function to start the TCP-IP server
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
  handleTCPIPServer:listen()
end

-- Function to stop the TCP-IP server
local function stopServer()
  handleTCPIPServer:deregister("OnConnectionAccepted", handleOnConnectionAccepted)
  handleTCPIPServer:deregister("OnConnectionClosed", handleOnConnectionClosed)
  handleTCPIPServer:deregister("OnReceive", handleOnReceiveData)
  conHandles = {}
  getConnectedClientsIPs()
  Script.releaseObject(handleTCPIPServer)
  handleTCPIPServer = nil
end


local function handleOnNewProcessing(object)
  _G.logger:info(nameOfModule .. ": Check object on instance No." .. multiTCPIPServerInstanceNumberString)
  Script.releaseObject(object)
end
Script.serveFunction("CSK_MultiTCPIPServer.processInstance"..multiTCPIPServerInstanceNumberString, handleOnNewProcessing, 'object:?:Alias', 'bool:?') -- Edit this according to this function

--- Function to handle updates of processing parameters from Controller
---@param multiTCPIPServerNo int Number of instance to update
---@param parameter string Parameter to update
---@param value auto Value of parameter to update
---@param internalObjectNo int? Number of object
local function handleOnNewProcessingParameter(multiTCPIPServerNo, parameter, value, internalObjectNo)
  if multiTCPIPServerNo == multiTCPIPServerInstanceNumber then -- set parameter only in selected script
    _G.logger:info(nameOfModule .. ": Update parameter '" .. parameter .. "' of multiTCPIPServerInstanceNo." .. tostring(multiTCPIPServerNo) .. " to value = " .. tostring(value))
    if parameter == 'registeredEvent' then
      _G.logger:info(nameOfModule .. ": Register instance " .. multiTCPIPServerInstanceNumberString .. " on event " .. value)
      if processingParams.registeredEvent ~= '' then
        Script.deregister(processingParams.registeredEvent, handleOnNewProcessing)
      end
      processingParams.registeredEvent = value
      Script.register(value, handleOnNewProcessing)
    elseif parameter == 'listenState' then
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
    elseif parameter == 'readMessages' then
      processingParams.readMessages = json.decode(value)
      setReadMessages()
    elseif parameter == 'writeMessages' then
      processingParams.writeMessages = json.decode(value)
      setWriteMessages()
    else
      processingParams[parameter] = value
    end
  elseif parameter == 'activeInUI' then
    processingParams[parameter] = false
  end
end
Script.register("CSK_MultiTCPIPServer.OnNewProcessingParameter", handleOnNewProcessingParameter)
