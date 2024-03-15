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

-- Event to forward content from this thread to Controller to show e.g. on UI
Script.serveEvent("CSK_MultiTCPIPServer.OnNewValueToForward".. multiTCPIPServerInstanceNumberString, "MultiTCPIPServer_OnNewValueToForward" .. multiTCPIPServerInstanceNumberString, 'string, auto')
-- Event to forward update of e.g. parameter update to keep data in sync between threads
Script.serveEvent("CSK_MultiTCPIPServer.OnNewValueUpdate" .. multiTCPIPServerInstanceNumberString, "MultiTCPIPServer_OnNewValueUpdate" .. multiTCPIPServerInstanceNumberString, 'int, string, auto, int:?')

local handleTCPIPServer -- TCPIP server handle
local connectedClientsIPs = {} -- array of the IP addresses of the connected clients
local conHandles = {} -- table with connection handles and info of the connected clients
local receiveDataQueue = Script.Queue.create() -- queue to track the calls when the data is received
local sendDataQueue = Script.Queue.create() -- queue to track the calls when the data is sent
local readMessagesEventsAny = {} -- list of events to be notified when data is received from any clients
local readMessagesEventsFiltered = {} -- list of events to be notified when data is received from clients in the fileter of read messages
local latestReceivedData = { -- table with info about the latest received data and IP address of the client it was received from
  data = '',
  ipAddress = ''
}
local ipToReadMessageNameMap = { -- table containing map of filtered IP addresses to message names for event notification convenience 
  notFiltered = {}
}
local latestReadMessagesData = {} -- table with latest received data from all read messages

local latestSentData = { -- table with info about the latest sent data and success
  data = '',
  success = false
}
local latestWriteMessagesData = {} -- table with latest sent data for all write messages

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
processingParams.readMessages = json.decode(scriptParams:get('readMessages'))
processingParams.writeMessages = json.decode(scriptParams:get('writeMessages'))
processingParams.onReceivedDataEventName = scriptParams:get('onReceivedDataEventName')
processingParams.sendDataFunctionName = scriptParams:get('sendDataFunctionName')

Script.serveEvent(processingParams.onReceivedDataEventName, processingParams.onReceivedDataEventName, 'string:1:,string:1:,int:1:,int:1:,string:?:')

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
  Script.notifyEvent(processingParams.onReceivedDataEventName, data, ipAddress, queueSize, timestamp2-timestamp1, errorMessage)
end
receiveDataQueue:setFunction({handleOnReceiveData})

local function getLatestGenericReceivedData()
  return latestReceivedData.ipAddress, latestReceivedData.data
end
Script.serveFunction("CSK_MultiTCPIPServer.getLatestGenericReceivedData" .. multiTCPIPServerInstanceNumberString, getLatestGenericReceivedData, '', 'string:1:,string:1:')

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

local function sendData(dataToSend, clientsIPs)
  if not clientsIPs or #clientsIPs == 0 then
    clientsIPs = connectedClientsIPs
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
  for messageName, messageInfo in pairs(processingParams.writeMessages) do
    local function sendMessage(dataToWrite)
      if dataToWrite == nil then
        dataToWrite = ''
      end
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

    if not Script.isServedAsFunction(messageInfo.functionName) then
      Script.serveFunction(messageInfo.functionName, sendMessage, 'auto:1:', 'bool:1:,int:1:,int:1:,string:?:')
    end
    table.insert(queueFunctions, messageInfo.functionName)
  end
  sendDataQueue:setFunction(queueFunctions)
end

local function getLatestGenericSentData()
  return latestSentData.success, latestSentData.data
end
Script.serveFunction("CSK_MultiTCPIPServer.getLatestGenericSentData" .. multiTCPIPServerInstanceNumberString, getLatestGenericSentData, '', 'bool:1:,string:1:')

local function getLatestWriteMessageData(messageName)
  if latestWriteMessagesData[messageName] then
    return latestWriteMessagesData[messageName].success, latestWriteMessagesData[messageName].data
  else
    return false, ""
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.getLatestWriteMessageData" .. multiTCPIPServerInstanceNumberString, getLatestWriteMessageData, 'string:1:', 'bool:1:,string:1:')

--- Function to start the TCP-IP server
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
  if Engine.getTypeName() ~= 'SICK AppEngine' and Engine.getTypeName() ~= 'Webdisplay' then --TODO check this
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
  handleTCPIPServer:deregister("OnConnectionAccepted", handleOnConnectionAccepted)
  handleTCPIPServer:deregister("OnConnectionClosed", handleOnConnectionClosed)
  handleTCPIPServer:deregister("OnReceive", handleOnReceiveData)
  conHandles = {}
  getConnectedClientsIPs()
  Script.releaseObject(handleTCPIPServer)
  handleTCPIPServer = nil
  _G.logger:fine(nameOfModule .. ": Stopped server.")
end

--- Function to handle updates of processing parameters from Controller
---@param multiTCPIPServerNo int Number of instance to update
---@param parameter string Parameter to update
---@param value auto Value of parameter to update
---@param internalObjectNo int? Number of object
local function handleOnNewProcessingParameter(multiTCPIPServerNo, parameter, value, internalObjectNo)
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
