---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the MultiTCPIPServer_Model and _Instances
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_MultiTCPIPServer'
local helperFuncs = require('Communication/MultiTCPIPServer/helper/funcs')
local json = require('Communication/MultiTCPIPServer/helper/Json')
local funcs = {}

-- Timer to update UI via events after page was loaded
local tmrMultiTCPIPServer = Timer.create()
tmrMultiTCPIPServer:setExpirationTime(400)
tmrMultiTCPIPServer:setPeriodic(false)

local multiTCPIPServer_Model -- Reference to model handle
local multiTCPIPServer_Instances -- Reference to instances handle
local selectedInstance = 1 -- Which instance is currently selected
local selectedTab = 0 -- selected tab ID in UI
local selectedReadMessage = '' -- name of the selected read message
local selectedWriteMessage = '' -- name of the selected write message
local testSendData = '' -- generic test data string to send
local testWriteMessageSendData = '' -- test data string to send as selected write message

-- ************************ UI Events Start ********************************
-- Only to prevent WARNING messages, but these are only examples/placeholders for dynamically created events/functions
----------------------------------------------------------------

Script.serveEvent("CSK_MultiTCPIPServer.OnNewResultNUM", "MultiTCPIPServer_OnNewResultNUM")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewValueToForwardNUM", "MultiTCPIPServer_OnNewValueToForwardNUM")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewValueUpdateNUM", "MultiTCPIPServer_OnNewValueUpdateNUM")
----------------------------------------------------------------

-- Real events
--------------------------------------------------
-- Script.serveEvent("CSK_MultiTCPIPServer.OnNewEvent", "MultiTCPIPServer_OnNewEvent")
Script.serveEvent('CSK_MultiTCPIPServer.OnNewResult', 'MultiTCPIPServer_OnNewResult')

Script.serveEvent('CSK_MultiTCPIPServer.OnNewStatusRegisteredEvent', 'MultiTCPIPServer_OnNewStatusRegisteredEvent')

Script.serveEvent("CSK_MultiTCPIPServer.OnNewStatusLoadParameterOnReboot", "MultiTCPIPServer_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_MultiTCPIPServer.OnPersistentDataModuleAvailable", "MultiTCPIPServer_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewParameterName", "MultiTCPIPServer_OnNewParameterName")

Script.serveEvent("CSK_MultiTCPIPServer.OnNewInstanceList", "MultiTCPIPServer_OnNewInstanceList")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewProcessingParameter", "MultiTCPIPServer_OnNewProcessingParameter")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewSelectedInstance", "MultiTCPIPServer_OnNewSelectedInstance")
Script.serveEvent("CSK_MultiTCPIPServer.OnDataLoadedOnReboot", "MultiTCPIPServer_OnDataLoadedOnReboot")

Script.serveEvent("CSK_MultiTCPIPServer.OnUserLevelOperatorActive", "MultiTCPIPServer_OnUserLevelOperatorActive")
Script.serveEvent("CSK_MultiTCPIPServer.OnUserLevelMaintenanceActive", "MultiTCPIPServer_OnUserLevelMaintenanceActive")
Script.serveEvent("CSK_MultiTCPIPServer.OnUserLevelServiceActive", "MultiTCPIPServer_OnUserLevelServiceActive")
Script.serveEvent("CSK_MultiTCPIPServer.OnUserLevelAdminActive", "MultiTCPIPServer_OnUserLevelAdminActive")

Script.serveEvent('CSK_MultiTCPIPServer.OnNewSelectedTab', 'MultiTCPIPServer_OnNewSelectedTab')
Script.serveEvent("CSK_MultiTCPIPServer.OnNewACKTimeout", "MultiTCPIPServer_OnNewACKTimeout")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewConnectedClientsTable", "MultiTCPIPServer_OnNewConnectedClientsTable")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewTestSendData", "MultiTCPIPServer_OnNewTestSendData")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewConnectedClientsNumber", "MultiTCPIPServer_OnNewConnectedClientsNumber")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewInterface", "MultiTCPIPServer_OnNewInterface")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewInterfaceList", "MultiTCPIPServer_OnNewInterfaceList")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewListenState", "MultiTCPIPServer_OnNewListenState")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewLogBuffer", "MultiTCPIPServer_OnNewLogBuffer")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewMaxConnections", "MultiTCPIPServer_OnNewMaxConnections")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewPort", "MultiTCPIPServer_OnNewPort")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewRxFraming", "MultiTCPIPServer_OnNewRxFraming")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewRxFramingBufferSize", "MultiTCPIPServer_OnNewRxFramingBufferSize")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewRxFramingList", "MultiTCPIPServer_OnNewRxFramingList")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewRxStart", "MultiTCPIPServer_OnNewRxStart")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewRxStop", "MultiTCPIPServer_OnNewRxStop")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewServerIP", "MultiTCPIPServer_OnNewServerIP")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewTransmitBuffer", "MultiTCPIPServer_OnNewTransmitBuffer")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewTransmitTimeout", "MultiTCPIPServer_OnNewTransmitTimeout")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewTxFraming", "MultiTCPIPServer_OnNewTxFraming")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewTxFramingBufferSize", "MultiTCPIPServer_OnNewTxFramingBufferSize")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewTxFramingList", "MultiTCPIPServer_OnNewTxFramingList")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewTxStart", "MultiTCPIPServer_OnNewTxStart")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewTxStop", "MultiTCPIPServer_OnNewTxStop")
Script.serveEvent("CSK_MultiTCPIPServer.OnRxFramingDisabled", "MultiTCPIPServer_OnRxFramingDisabled")
Script.serveEvent("CSK_MultiTCPIPServer.OnTxFramingDisabled", "MultiTCPIPServer_OnTxFramingDisabled")
Script.serveEvent('CSK_MultiTCPIPServer.OnNewGenericReceivedDataEventName', 'MultiTCPIPServer_OnNewGenericReceivedDataEventName')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewGenericSendDataFunctionName', 'MultiTCPIPServer_OnNewGenericSendDataFunctionName')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewGenericLatestReceivedIPAddress', 'MultiTCPIPServer_OnNewGenericLatestReceivedIPAddress')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewGenericLatestReceivedData', 'MultiTCPIPServer_OnNewGenericLatestReceivedData')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewGenericLatestSentData', 'MultiTCPIPServer_OnNewGenericLatestSentData')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewGenericLatestSentDataSuccess', 'MultiTCPIPServer_OnNewGenericLatestSentDataSuccess')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewTestDataSendingSuccess', 'MultiTCPIPServer_OnNewTestDataSendingSuccess')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewTestDataToSend', 'MultiTCPIPServer_OnNewTestDataToSend')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewListReadMessages', 'MultiTCPIPServer_OnNewListReadMessages')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewReadMessageEventName', 'MultiTCPIPServer_OnNewReadMessageEventName')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewReadMessageFilterTableContent', 'MultiTCPIPServer_OnNewReadMessageFilterTableContent')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewReadMessageSelectedStatus', 'MultiTCPIPServer_OnNewReadMessageSelectedStatus')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewSelectedReadMessage', 'MultiTCPIPServer_OnNewSelectedReadMessage')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewUseReadMessageIPFilterState', 'MultiTCPIPServer_OnNewUseReadMessageIPFilterState')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewReadMessageLatestReceivedData', 'MultiTCPIPServer_OnNewReadMessageLatestReceivedData')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewReadMessageLatestReceivedIPAddress', 'MultiTCPIPServer_OnNewReadMessageLatestReceivedIPAddress')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewListWriteMessages', 'MultiTCPIPServer_OnNewListWriteMessages')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewWriteMessageFunctionName', 'MultiTCPIPServer_OnNewWriteMessageFunctionName')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewWriteMessageFilterTableContent', 'MultiTCPIPServer_OnNewWriteMessageFilterTableContent')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewWriteMessageSelectedStatus', 'MultiTCPIPServer_OnNewWriteMessageSelectedStatus')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewSelectedWriteMessage', 'MultiTCPIPServer_OnNewSelectedWriteMessage')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewUseWriteMessageIPFilterState', 'MultiTCPIPServer_OnNewUseWriteMessageIPFilterState')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewWriteMessageLatestSentDataSuccess', 'MultiTCPIPServer_OnNewWriteMessageLatestSentDataSuccess')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewWriteMessageLatestSentData', 'MultiTCPIPServer_OnNewWriteMessageLatestSentData')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewTestWriteMessageDataSendingSuccess', 'MultiTCPIPServer_OnNewTestWriteMessageDataSendingSuccess')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewTestWriteMessageDataToSend', 'MultiTCPIPServer_OnNewTestWriteMessageDataToSend')


-- ************************ UI Events End **********************************

---Function to create a list of available interfaces.
---@return string interfaces String list of interfaces.
local function createInterfaceList()
  local interfaceList = {}
  if multiTCPIPServer_Instances[1].currentDevice == 'Webdisplay' then
    table.insert(interfaceList, 'ETH1')
  elseif multiTCPIPServer_Instances[1].currentDevice == 'SICK AppEngine' then
    table.insert(interfaceList, "")
  else
    interfaceList = Ethernet.Interface.getInterfaces()
  end
  return json.encode(interfaceList)
end

---Function to get IP address of the selected interface.
---@return string ipAddress IP address of the interface.
local function getInterfaceIP()
  if multiTCPIPServer_Instances[1].currentDevice == 'SICK AppEngine' or multiTCPIPServer_Instances[1].currentDevice == 'Webdisplay' then return '' end
  local _, ipAddress = Ethernet.Interface.getAddressConfig(multiTCPIPServer_Instances[selectedInstance].parameters.interface)
  return ipAddress
end
Script.serveFunction('CSK_MultiTCPIPServer.getInterfaceIP', getInterfaceIP)

---Function to get list of keys of the lua table as a JSON string.
---@return string keyList List of keys of the lua table as a JSON string.
local function getTableKeyList(someTable)
  local keyList = {}
  for key, _ in pairs(someTable) do
    table.insert(keyList, key)
  end
  table.sort(keyList)
  return json.encode(keyList)
end

---Function to get create a dynamic table content out of the strings list.
---@param dynamicTableColumnName string Column name of the dynamic table
---@param list string+ List of the strings to show as rows of the table
---@return string tableContent Table content as a JSON string.
local function makeDynamicTableOutOfList(dynamicTableColumnName, list)
  local tableContent = {}
  for _, value in ipairs(list) do
    table.insert(tableContent, 
      {
        [dynamicTableColumnName] = tostring(value)
      }
    )
  end
  return json.encode(tableContent)
end

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

-- Functions to forward logged in user roles via CSK_UserManagement module (if available)
-- ***********************************************
--- Function to react on status change of Operator user level
---@param status boolean Status if Operator level is active
local function handleOnUserLevelOperatorActive(status)
  Script.notifyEvent("MultiTCPIPServer_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("MultiTCPIPServer_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("MultiTCPIPServer_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("MultiTCPIPServer_OnUserLevelAdminActive", status)
end
-- ***********************************************

--- Function to forward data updates from instance threads to Controller part of module
---@param eventname string Eventname to use to forward value
---@param value auto Value to forward
local function handleOnNewValueToForward(eventname, value)
  Script.notifyEvent(eventname, value)
end

--- Optionally: Only use if needed for extra internal objects -  see also Model
--- Function to sync paramters between instance threads and Controller part of module
---@param instance int Instance new value is coming from
---@param parameter string Name of the paramter to update/sync
---@param value auto Value to update
---@param selectedObject int? Optionally if internal parameter should be used for internal objects
local function handleOnNewValueUpdate(instance, parameter, value, selectedObject)
    multiTCPIPServer_Instances[instance].parameters.internalObject[selectedObject][parameter] = value
end

--- Function to get access to the multiTCPIPServer_Model object
---@param handle handle Handle of multiTCPIPServer_Model object
local function setMultiTCPIPServer_Model_Handle(handle)
  multiTCPIPServer_Model = handle
  Script.releaseObject(handle)
end
funcs.setMultiTCPIPServer_Model_Handle = setMultiTCPIPServer_Model_Handle

--- Function to get access to the multiTCPIPServer_Instances object
---@param handle handle Handle of multiTCPIPServer_Instances object
local function setMultiTCPIPServer_Instances_Handle(handle)
  multiTCPIPServer_Instances = handle
  if multiTCPIPServer_Instances[selectedInstance].userManagementModuleAvailable then
    -- Register on events of CSK_UserManagement module if available
    Script.register('CSK_UserManagement.OnUserLevelOperatorActive', handleOnUserLevelOperatorActive)
    Script.register('CSK_UserManagement.OnUserLevelMaintenanceActive', handleOnUserLevelMaintenanceActive)
    Script.register('CSK_UserManagement.OnUserLevelServiceActive', handleOnUserLevelServiceActive)
    Script.register('CSK_UserManagement.OnUserLevelAdminActive', handleOnUserLevelAdminActive)
  end
  Script.releaseObject(handle)

  for i = 1, #multiTCPIPServer_Instances do
    Script.register("CSK_MultiTCPIPServer.OnNewValueToForward" .. tostring(i) , handleOnNewValueToForward)
  end

  for i = 1, #multiTCPIPServer_Instances do
    Script.register("CSK_MultiTCPIPServer.OnNewValueUpdate" .. tostring(i) , handleOnNewValueUpdate)
  end

end
funcs.setMultiTCPIPServer_Instances_Handle = setMultiTCPIPServer_Instances_Handle

--- Function to update user levels
local function updateUserLevel()
  if multiTCPIPServer_Instances[selectedInstance].userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    CSK_UserManagement.pageCalled()
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("MultiTCPIPServer_OnUserLevelAdminActive", true)
    Script.notifyEvent("MultiTCPIPServer_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("MultiTCPIPServer_OnUserLevelServiceActive", true)
    Script.notifyEvent("MultiTCPIPServer_OnUserLevelOperatorActive", true)
  end
end

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrMultiTCPIPServer()
  updateUserLevel()

  Script.notifyEvent('MultiTCPIPServer_OnNewSelectedInstance', selectedInstance)
  Script.notifyEvent("MultiTCPIPServer_OnNewInstanceList", helperFuncs.createStringListBySize(#multiTCPIPServer_Instances))

  Script.notifyEvent("MultiTCPIPServer_OnNewStatusLoadParameterOnReboot", multiTCPIPServer_Instances[selectedInstance].parameterLoadOnReboot)
  Script.notifyEvent("MultiTCPIPServer_OnPersistentDataModuleAvailable", multiTCPIPServer_Instances[selectedInstance].persistentModuleAvailable)
  Script.notifyEvent("MultiTCPIPServer_OnNewParameterName", multiTCPIPServer_Instances[selectedInstance].parametersName)

  local serverIsActive = multiTCPIPServer_Instances[selectedInstance].parameters.listenState

  Script.notifyEvent("MultiTCPIPServer_OnNewListenState", serverIsActive)

  Script.notifyEvent("MultiTCPIPServer_OnNewInterface", multiTCPIPServer_Instances[selectedInstance].parameters.interface)
  Script.notifyEvent("MultiTCPIPServer_OnNewInterfaceList", createInterfaceList())
  Script.notifyEvent("MultiTCPIPServer_OnNewServerIP", getInterfaceIP())
  Script.notifyEvent("MultiTCPIPServer_OnNewPort", multiTCPIPServer_Instances[selectedInstance].parameters.port)

  Script.notifyEvent("MultiTCPIPServer_OnNewSelectedTab", selectedTab)
  if selectedTab == 0 then
    Script.notifyEvent("MultiTCPIPServer_OnNewRxFramingList", json.encode(multiTCPIPServer_Instances[selectedInstance].RxFramingList))
    Script.notifyEvent("MultiTCPIPServer_OnNewRxFraming", multiTCPIPServer_Instances[selectedInstance].parameters.RxFrameMode)
    Script.notifyEvent("MultiTCPIPServer_OnRxFramingDisabled", serverIsActive or multiTCPIPServer_Instances[selectedInstance].parameters.RxFrameMode ~= 'Custom')
    Script.notifyEvent("MultiTCPIPServer_OnNewTxFramingList", json.encode(multiTCPIPServer_Instances[selectedInstance].TxFramingList))
    Script.notifyEvent("MultiTCPIPServer_OnNewTxFraming", multiTCPIPServer_Instances[selectedInstance].parameters.TxFrameMode)
    Script.notifyEvent("MultiTCPIPServer_OnTxFramingDisabled", serverIsActive or multiTCPIPServer_Instances[selectedInstance].parameters.TxFrameMode ~= 'Custom')
    Script.notifyEvent("MultiTCPIPServer_OnNewRxStart", helperFuncs.convertHex2String(multiTCPIPServer_Instances[selectedInstance].parameters.framing[1]))
    Script.notifyEvent("MultiTCPIPServer_OnNewRxStop", helperFuncs.convertHex2String(multiTCPIPServer_Instances[selectedInstance].parameters.framing[2]))
    Script.notifyEvent("MultiTCPIPServer_OnNewTxStart", helperFuncs.convertHex2String(multiTCPIPServer_Instances[selectedInstance].parameters.framing[3]))
    Script.notifyEvent("MultiTCPIPServer_OnNewTxStop", helperFuncs.convertHex2String(multiTCPIPServer_Instances[selectedInstance].parameters.framing[4]))

    Script.notifyEvent("MultiTCPIPServer_OnNewMaxConnections", multiTCPIPServer_Instances[selectedInstance].parameters.maxConnections)
    Script.notifyEvent("MultiTCPIPServer_OnNewTransmitTimeout", multiTCPIPServer_Instances[selectedInstance].parameters.transmitTimeout)
    Script.notifyEvent("MultiTCPIPServer_OnNewACKTimeout", multiTCPIPServer_Instances[selectedInstance].parameters.transmitAckTimeout)
    Script.notifyEvent("MultiTCPIPServer_OnNewTransmitBuffer", multiTCPIPServer_Instances[selectedInstance].parameters.transmitBufferSize)
    Script.notifyEvent("MultiTCPIPServer_OnNewRxFramingBufferSize", multiTCPIPServer_Instances[selectedInstance].parameters.framingBufferSize[1])
    Script.notifyEvent("MultiTCPIPServer_OnNewTxFramingBufferSize", multiTCPIPServer_Instances[selectedInstance].parameters.framingBufferSize[2])

    Script.notifyEvent("MultiTCPIPServer_OnNewGenericReceivedDataEventName", multiTCPIPServer_Instances[selectedInstance].parameters.onRecevedDataEventName)
    Script.notifyEvent("MultiTCPIPServer_OnNewGenericSendDataFunctionName", multiTCPIPServer_Instances[selectedInstance].parameters.sendDataFunctionName)
  elseif selectedTab == 1 then
    Script.notifyEvent('MultiTCPIPServer_OnNewListReadMessages', getTableKeyList(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages))
    Script.notifyEvent('MultiTCPIPServer_OnNewSelectedReadMessage', selectedReadMessage)
    Script.notifyEvent('MultiTCPIPServer_OnNewReadMessageSelectedStatus', selectedReadMessage ~= '')
    if selectedReadMessage ~= '' then
      Script.notifyEvent('MultiTCPIPServer_OnNewReadMessageEventName', multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage].eventName)
      Script.notifyEvent('MultiTCPIPServer_OnNewUseReadMessageIPFilterState', multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage].ipFilterInfo.used)
      if multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage].ipFilterInfo.used then
        Script.notifyEvent('MultiTCPIPServer_OnNewReadMessageFilterTableContent', makeDynamicTableOutOfList('DTC_ReadMessageFilterIP', multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage].ipFilterInfo.filteredIPs))
      end
    end
  elseif selectedTab == 2 then
    Script.notifyEvent('MultiTCPIPServer_OnNewListWriteMessages', getTableKeyList(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages))
    Script.notifyEvent('MultiTCPIPServer_OnNewSelectedWriteMessage', selectedWriteMessage)
    Script.notifyEvent('MultiTCPIPServer_OnNewWriteMessageSelectedStatus', selectedWriteMessage ~= '')
    if selectedWriteMessage ~= '' then
      Script.notifyEvent('MultiTCPIPServer_OnNewWriteMessageFunctionName', multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].functionName)
      Script.notifyEvent('MultiTCPIPServer_OnNewUseWriteMessageIPFilterState', multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].ipFilterInfo.used)
      if multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].ipFilterInfo.used then
        Script.notifyEvent('MultiTCPIPServer_OnNewWriteMessageFilterTableContent', makeDynamicTableOutOfList('DTC_WriteMessageFilterIP', multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].ipFilterInfo.filteredIPs))
      end
    end
  end

  Script.callFunction("CSK_MultiTCPIPServer.getConnectedClientsIPs" .. tostring(selectedInstance))
end
Timer.register(tmrMultiTCPIPServer, "OnExpired", handleOnExpiredTmrMultiTCPIPServer)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  tmrMultiTCPIPServer:start()
  return ''
end
Script.serveFunction("CSK_MultiTCPIPServer.pageCalled", pageCalled)

local function setSelectedTab(newSelectedTab)
  selectedTab = newSelectedTab
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setSelectedTab', setSelectedTab)

--**************************************************************************
--********************* Set server settings functions **********************
--**************************************************************************

local function setACKTimeout(newACKTimeout)
  if newACKTimeout < 0 then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.transmitAckTimeout = newACKTimeout
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'transmitAckTimeout', newACKTimeout)
end
Script.serveFunction("CSK_MultiTCPIPServer.setACKTimeout", setACKTimeout)


local function setInterface(newInterface)
  multiTCPIPServer_Instances[selectedInstance].parameters.interface = newInterface
  Script.notifyEvent("MultiTCPIPServer_OnNewServerIP", getInterfaceIP())
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'interface', newInterface)
end
Script.serveFunction("CSK_MultiTCPIPServer.setInterface", setInterface)

local function setListenState(newState)
  if newState == multiTCPIPServer_Instances[selectedInstance].parameters.listenState then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.listenState = newState
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'listenState', newState)
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction("CSK_MultiTCPIPServer.setListenState", setListenState)

local function setMaxConnections(newMaxConnections)
  if newMaxConnections < 0 then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.maxConnections = newMaxConnections
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'maxConnections', newMaxConnections)
end
Script.serveFunction("CSK_MultiTCPIPServer.setMaxConnections", setMaxConnections)

local function setPort(newPort)
  if newPort > 65535 or newPort < 0 then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.port = newPort
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'port', newPort)
end
Script.serveFunction("CSK_MultiTCPIPServer.setPort", setPort)

local function setRxBuffer(newRxBuffer)
  if newRxBuffer < 0 then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.framingBufferSize[1] = newRxBuffer
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'framingBufferSize', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framingBufferSize))
end
Script.serveFunction("CSK_MultiTCPIPServer.setRxBuffer", setRxBuffer)

local function setTransmitionBuffer(newTransmitionBuffer)
  if newTransmitionBuffer < 0 then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.transmitBufferSize = newTransmitionBuffer
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'transmitBufferSize', newTransmitionBuffer)
end
Script.serveFunction("CSK_MultiTCPIPServer.setTransmitionBuffer", setTransmitionBuffer)

local function setTransmitionTimeout(newTransmitionTimeout)
  if newTransmitionTimeout < 0 then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.transmitTimeout = newTransmitionTimeout
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'transmitTimeout', newTransmitionTimeout)
end
Script.serveFunction("CSK_MultiTCPIPServer.setTransmitionTimeout", setTransmitionTimeout)

local function setRxFraming(newRxFraming)
  multiTCPIPServer_Instances[selectedInstance].parameters.RxFrameMode = newRxFraming
  if newRxFraming == 'STX-ETX' then
    multiTCPIPServer_Instances[selectedInstance].parameters.framing[1] = '\02'
    multiTCPIPServer_Instances[selectedInstance].parameters.framing[2] = '\03'
  elseif newRxFraming == 'Empty' then
    multiTCPIPServer_Instances[selectedInstance].parameters.framing[1] = ''
    multiTCPIPServer_Instances[selectedInstance].parameters.framing[2] = ''
  end
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'framing', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framing))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction("CSK_MultiTCPIPServer.setRxFraming", setRxFraming)

local function setRxStart(newRxStart)
  multiTCPIPServer_Instances[selectedInstance].parameters.framing[1] = helperFuncs.convertString2Hex(newRxStart)
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'framing', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framing))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction("CSK_MultiTCPIPServer.setRxStart", setRxStart)

local function setRxStop(newRxStop)
  multiTCPIPServer_Instances[selectedInstance].parameters.framing[2] = helperFuncs.convertString2Hex(newRxStop)
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'framing', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framing))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction("CSK_MultiTCPIPServer.setRxStop", setRxStop)

local function setTxBuffer(newTxBuffer)
  if newTxBuffer < 0 then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.framingBufferSize[2] = newTxBuffer
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'framingBufferSize', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framingBufferSize))
end
Script.serveFunction("CSK_MultiTCPIPServer.setTxBuffer", setTxBuffer)

local function setTxFraming(newTxFraming)
  multiTCPIPServer_Instances[selectedInstance].parameters.TxFrameMode = newTxFraming
  if newTxFraming == 'STX-ETX' then
    multiTCPIPServer_Instances[selectedInstance].parameters.framing[3] = '\02'
    multiTCPIPServer_Instances[selectedInstance].parameters.framing[4] = '\03'
  elseif newTxFraming == 'Empty' then
    multiTCPIPServer_Instances[selectedInstance].parameters.framing[3] = ''
    multiTCPIPServer_Instances[selectedInstance].parameters.framing[4] = ''
  end
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'framing', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framing))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction("CSK_MultiTCPIPServer.setTxFraming", setTxFraming)

local function setTxStart(newTxStart)
  multiTCPIPServer_Instances[selectedInstance].parameters.framing[3] = helperFuncs.convertString2Hex(newTxStart)
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'framing', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framing))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction("CSK_MultiTCPIPServer.setTxStart", setTxStart)

local function setTxStop(newTxStop)
  multiTCPIPServer_Instances[selectedInstance].parameters.framing[4] = helperFuncs.convertString2Hex(newTxStop)
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'framing', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framing))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction("CSK_MultiTCPIPServer.setTxStop", setTxStop)

--**************************************************************************
--********************* Show received or write data ************************
--**************************************************************************

local function refreshLatestGenericReceivedData()
  local _, ipAddress, data = Script.callFunction("CSK_MultiTCPIPServer.getLatestGenericReceivedData" .. tostring(selectedInstance))
  Script.notifyEvent("MultiTCPIPServer_OnNewGenericLatestReceivedIPAddress", ipAddress)
  Script.notifyEvent("MultiTCPIPServer_OnNewGenericLatestReceivedData", data)
end
Script.serveFunction('CSK_MultiTCPIPServer.refreshLatestGenericReceivedData', refreshLatestGenericReceivedData)

local function refreshLatestGenericSentData()
  local _, success, data = Script.callFunction("CSK_MultiTCPIPServer.getLatestGenericSentData" .. tostring(selectedInstance))
  Script.notifyEvent("MultiTCPIPServer_OnNewGenericLatestSentDataSuccess", success)
  Script.notifyEvent("MultiTCPIPServer_OnNewGenericLatestSentData", data)
end
Script.serveFunction('CSK_MultiTCPIPServer.refreshLatestGenericSentData', refreshLatestGenericSentData)

local function setTestDataToSend(newTestDataToSend)
  testSendData = newTestDataToSend
end
Script.serveFunction('CSK_MultiTCPIPServer.setTestDataToSend', setTestDataToSend)

local function sendTestData()
  local _, success = Script.callFunction(multiTCPIPServer_Instances[selectedInstance].parameters.sendDataFunctionName, testSendData)
  Script.notifyEvent("MultiTCPIPServer_OnNewTestDataSendingSuccess", success)
end
Script.serveFunction('CSK_MultiTCPIPServer.sendTestData', sendTestData)

--**************************************************************************
--************************* Read messages scope ****************************
--**************************************************************************

local function setSelectedReadMessage(readMessageName)
  if not multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[readMessageName] then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  selectedReadMessage = readMessageName
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setSelectedReadMessage', setSelectedReadMessage)

local function createReadMessage()
  local index = 0
  local messageName = "read_Message"
  while multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[messageName] do
    index = index + 1
    messageName = "read_Message" .. tostring(index)
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[messageName] = {
    eventName = 'CSK_MultiTCPIPServer.OnReceivedData' .. tostring(selectedInstance) .. messageName,
    ipFilterInfo = {
      used = false,
      filteredIPs = {}
    }
  }
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'readMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages))
  selectedReadMessage = messageName
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.createReadMessage', createReadMessage)

local function deleteReadMessage()
  multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage] = nil
  selectedReadMessage = ''
  if not multiTCPIPServer_Instances[selectedInstance].parameters.readMessages then
    multiTCPIPServer_Instances[selectedInstance].parameters.readMessages = {}
  end
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'readMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.deleteReadMessage', deleteReadMessage)

local function setReadMessageName(newName)
  if multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[newName] then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[newName] = helperFuncs.copy(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage])
  multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[newName].eventName = 'CSK_MultiTCPIPServer.OnReceivedData' .. tostring(selectedInstance) .. newName
  multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage] = nil
  selectedReadMessage = newName
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'readMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setReadMessageName', setReadMessageName)

local function setUseReadMessageIPFilter(newState)
  multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage].ipFilterInfo.filteredIPs = {}
  multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage].ipFilterInfo.used = newState
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'readMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setUseReadMessageIPFilter', setUseReadMessageIPFilter)

local function setIPAddressToAddToReadMessage(ipAddress)
  if not helperFuncs.checkIP(ipAddress) then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  for _, addedIP in ipairs(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage].ipFilterInfo.filteredIPs) do
    if addedIP == ipAddress then
      handleOnExpiredTmrMultiTCPIPServer()
      return
    end
  end
  table.insert(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage].ipFilterInfo.filteredIPs, ipAddress)
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'readMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setIPAddressToAddToReadMessage', setIPAddressToAddToReadMessage)

local function deleteReadMessageFilterIPAddress(jsonRowToDelete)
  local rowContent = json.decode(jsonRowToDelete)
  for index, ipAddress in ipairs(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage].ipFilterInfo.filteredIPs) do
    if ipAddress == rowContent['DTC_ReadMessageFilterIP'] then
      table.remove(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage].ipFilterInfo.filteredIPs, index)
      break
    end
  end
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'readMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.deleteReadMessageFilterIPAddress', deleteReadMessageFilterIPAddress)

local function refreshLatestReadMessageReceivedData()
  local _, ipAddress, data = Script.callFunction("CSK_MultiTCPIPServer.getLatestReadMessageData" .. tostring(selectedInstance), selectedReadMessage)
  Script.notifyEvent("MultiTCPIPServer_OnNewReadMessageLatestReceivedIPAddress", ipAddress)
  Script.notifyEvent("MultiTCPIPServer_OnNewReadMessageLatestReceivedData", data)
end
Script.serveFunction('CSK_MultiTCPIPServer.refreshLatestReadMessageReceivedData', refreshLatestReadMessageReceivedData)

--**************************************************************************
--************************* Write messages scope ***************************
--**************************************************************************

---@param writeMessageName string Name of the write message.
local function setSelectedWriteMessage(writeMessageName)
  if not multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[writeMessageName] then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  selectedWriteMessage = writeMessageName
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setSelectedWriteMessage', setSelectedWriteMessage)

local function createWriteMessage()
  local index = 0
  local messageName = "write_Message"
  while multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[messageName] do
    index = index + 1
    messageName = "write_Message" .. tostring(index)
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[messageName] = {
    functionName = 'CSK_MultiTCPIPServer.sendData' .. tostring(selectedInstance) .. messageName,
    ipFilterInfo = {
      used = false,
      filteredIPs = {}
    }
  }
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'writeMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages))
  selectedWriteMessage = messageName
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.createWriteMessage', createWriteMessage)

local function deleteWriteMessage()
  multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage] = nil
  selectedWriteMessage = ''
  if not multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages then
    multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages = {}
  end
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'writeMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.deleteWriteMessage', deleteWriteMessage)

local function setWriteMessageName(newName)
  if multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[newName] then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[newName] = helperFuncs.copy(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage])
  multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[newName].functionName = 'CSK_MultiTCPIPServer.sendData' .. tostring(selectedInstance) .. newName
  multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage] = nil
  selectedWriteMessage = newName
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'writeMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setWriteMessageName', setWriteMessageName)

local function setUseWriteMessageIPFilter(newState)
  multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].ipFilterInfo.filteredIPs = {}
  multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].ipFilterInfo.used = newState
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'writeMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setUseWriteMessageIPFilter', setUseWriteMessageIPFilter)

local function setIPAddressToAddToWriteMessage(ipAddress)
  if not helperFuncs.checkIP(ipAddress) then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  for _, addedIP in ipairs(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].ipFilterInfo.filteredIPs) do
    if addedIP == ipAddress then
      handleOnExpiredTmrMultiTCPIPServer()
      return
    end
  end
  table.insert(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].ipFilterInfo.filteredIPs, ipAddress)
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'writeMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setIPAddressToAddToWriteMessage', setIPAddressToAddToWriteMessage)

local function deleteWriteMessageFilterIPAddress(jsonRowToDelete)
  local rowContent = json.decode(jsonRowToDelete)
  for index, ipAddress in ipairs(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].ipFilterInfo.filteredIPs) do
    if ipAddress == rowContent['DTC_WriteMessageFilterIP'] then
      table.remove(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].ipFilterInfo.filteredIPs, index)
      break
    end
  end
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'writeMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.deleteWriteMessageFilterIPAddress', deleteWriteMessageFilterIPAddress)

local function setTestWriteMessageDataToSend(newTestDataToSend)
  testWriteMessageSendData = newTestDataToSend
end
Script.serveFunction('CSK_MultiTCPIPServer.setTestWriteMessageDataToSend', setTestWriteMessageDataToSend)

local function sendTestWriteMessageData()
  local _, success = Script.callFunction(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].functionName, testWriteMessageSendData)
  Script.notifyEvent("MultiTCPIPServer_OnNewTestWriteMessageDataSendingSuccess", success)
end
Script.serveFunction('CSK_MultiTCPIPServer.sendTestWriteMessageData', sendTestWriteMessageData)

local function refreshLatestWriteMessageSentData()
  local _, success, data = Script.callFunction("CSK_MultiTCPIPServer.getLatestWriteMessageData" .. tostring(selectedInstance), selectedWriteMessage)
  Script.notifyEvent("MultiTCPIPServer_OnNewWriteMessageLatestSentDataSuccess", success)
  Script.notifyEvent("MultiTCPIPServer_OnNewWriteMessageLatestSentData", data)
end
Script.serveFunction('CSK_MultiTCPIPServer.refreshLatestWriteMessageSentData', refreshLatestWriteMessageSentData)

--**************************************************************************
--******************** Connected clients table scope ***********************
--**************************************************************************

---@param selectedRow string Selected row from the connected clients table in JSON format
local function selectConnectedClient(selectedRow)
  if selectedTab == 1 and selectedReadMessage ~= '' and multiTCPIPServer_Instances[selectedInstance].parameters.readMessages[selectedReadMessage].ipFilterInfo.used == true then
    local rowContent = json.decode(selectedRow)
    setIPAddressToAddToReadMessage(rowContent.DTC_ConnectedClientIPAddress)
  elseif selectedTab == 2 and selectedWriteMessage ~= '' and multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages[selectedWriteMessage].ipFilterInfo.used == true then
    local rowContent = json.decode(selectedRow)
    setIPAddressToAddToWriteMessage(rowContent.DTC_ConnectedClientIPAddress)
  end
end
Script.serveFunction('CSK_MultiTCPIPServer.selectConnectedClient', selectConnectedClient)

--**************************************************************************
--******************** Generic CSK functions scope *************************
--**************************************************************************

local function setSelectedInstance(instance)
  selectedInstance = instance
  _G.logger:info(nameOfModule .. ": New selected instance = " .. tostring(selectedInstance))
  multiTCPIPServer_Instances[selectedInstance].activeInUI = true
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'activeInUI', true)
  tmrMultiTCPIPServer:start()
end
Script.serveFunction("CSK_MultiTCPIPServer.setSelectedInstance", setSelectedInstance)

local function getInstancesAmount ()
  return #multiTCPIPServer_Instances
end
Script.serveFunction("CSK_MultiTCPIPServer.getInstancesAmount", getInstancesAmount)

local function addInstance()
  _G.logger:info(nameOfModule .. ": Add instance")
  table.insert(multiTCPIPServer_Instances, multiTCPIPServer_Model.create(#multiTCPIPServer_Instances+1))
  Script.deregister("CSK_MultiTCPIPServer.OnNewValueToForward" .. tostring(#multiTCPIPServer_Instances) , handleOnNewValueToForward)
  Script.register("CSK_MultiTCPIPServer.OnNewValueToForward" .. tostring(#multiTCPIPServer_Instances) , handleOnNewValueToForward)
  setSelectedInstance(#multiTCPIPServer_Instances)
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.addInstance', addInstance)

local function resetInstances()
  _G.logger:info(nameOfModule .. ": Reset instances.")
  setSelectedInstance(1)
  local totalAmount = #multiTCPIPServer_Instances
  while totalAmount > 1 do
    Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', totalAmount, 'listenState', false)
    Script.releaseObject(multiTCPIPServer_Instances[totalAmount])
    multiTCPIPServer_Instances[totalAmount] =  nil
    totalAmount = totalAmount - 1
  end
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.resetInstances', resetInstances)

local function setRegisterEvent(event)
  multiTCPIPServer_Instances[selectedInstance].parameters.registeredEvent = event
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'registeredEvent', event)
end
Script.serveFunction("CSK_MultiTCPIPServer.setRegisterEvent", setRegisterEvent)

--- Function to share process relevant configuration with processing threads
local function updateProcessingParameters()
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'activeInUI', true)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'registeredEvent', multiTCPIPServer_Instances[selectedInstance].parameters.registeredEvent)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'interface', multiTCPIPServer_Instances[selectedInstance].parameters.interface)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'port', multiTCPIPServer_Instances[selectedInstance].parameters.port)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'framing', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framing))
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'framingBufferSize', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framingBufferSize))
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'maxConnections', multiTCPIPServer_Instances[selectedInstance].parameters.maxConnections)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'transmitAckTimeout', multiTCPIPServer_Instances[selectedInstance].parameters.transmitAckTimeout)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'transmitBufferSize', multiTCPIPServer_Instances[selectedInstance].parameters.transmitBufferSize)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'transmitTimeout', multiTCPIPServer_Instances[selectedInstance].parameters.transmitTimeout)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'readMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.readMessages))
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'writeMessages', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.writeMessages))
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'onRecevedDataEventName', multiTCPIPServer_Instances[selectedInstance].parameters.onRecevedDataEventName)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'sendDataFunctionName', multiTCPIPServer_Instances[selectedInstance].parameters.sendDataFunctionName)

  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'listenState', multiTCPIPServer_Instances[selectedInstance].parameters.listenState)
end

-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  _G.logger:info(nameOfModule .. ": Set parameter name = " .. tostring(name))
  multiTCPIPServer_Instances[selectedInstance].parametersName = name
end
Script.serveFunction("CSK_MultiTCPIPServer.setParameterName", setParameterName)

local function sendParameters()
  if multiTCPIPServer_Instances[selectedInstance].persistentModuleAvailable then
    CSK_PersistentData.addParameter(helperFuncs.convertTable2Container(multiTCPIPServer_Instances[selectedInstance].parameters), multiTCPIPServer_Instances[selectedInstance].parametersName)

    -- Check if CSK_PersistentData version is >= 3.0.0
    if tonumber(string.sub(CSK_PersistentData.getVersion(), 1, 1)) >= 3 then
      CSK_PersistentData.setModuleParameterName(nameOfModule, multiTCPIPServer_Instances[selectedInstance].parametersName, multiTCPIPServer_Instances[selectedInstance].parameterLoadOnReboot, tostring(selectedInstance), #multiTCPIPServer_Instances)
    else
      CSK_PersistentData.setModuleParameterName(nameOfModule, multiTCPIPServer_Instances[selectedInstance].parametersName, multiTCPIPServer_Instances[selectedInstance].parameterLoadOnReboot, tostring(selectedInstance))
    end
    _G.logger:info(nameOfModule .. ": Send MultiTCPIPServer parameters with name '" .. multiTCPIPServer_Instances[selectedInstance].parametersName .. "' to CSK_PersistentData module.")
    CSK_PersistentData.saveData()
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.sendParameters", sendParameters)

local function loadParameters()
  if multiTCPIPServer_Instances[selectedInstance].persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(multiTCPIPServer_Instances[selectedInstance].parametersName)
    if data then
      _G.logger:info(nameOfModule .. ": Loaded parameters for multiTCPIPServerObject " .. tostring(selectedInstance) .. " from CSK_PersistentData module.")
      multiTCPIPServer_Instances[selectedInstance].parameters = helperFuncs.convertContainer2Table(data)

      -- If something needs to be configured/activated with new loaded data
      updateProcessingParameters()
      CSK_MultiTCPIPServer.pageCalled()
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
  tmrMultiTCPIPServer:start()
end
Script.serveFunction("CSK_MultiTCPIPServer.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  multiTCPIPServer_Instances[selectedInstance].parameterLoadOnReboot = status
  _G.logger:info(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
end
Script.serveFunction("CSK_MultiTCPIPServer.setLoadOnReboot", setLoadOnReboot)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()

  _G.logger:info(nameOfModule .. ': Try to initially load parameter from CSK_PersistentData module.')
  if string.sub(CSK_PersistentData.getVersion(), 1, 1) == '1' then

    _G.logger:warning(nameOfModule .. ': CSK_PersistentData module is too old and will not work. Please update CSK_PersistentData module.')

    for j = 1, #multiTCPIPServer_Instances do
      multiTCPIPServer_Instances[j].persistentModuleAvailable = false
    end
  else
    -- Check if CSK_PersistentData version is >= 3.0.0
    if tonumber(string.sub(CSK_PersistentData.getVersion(), 1, 1)) >= 3 then
      local parameterName, loadOnReboot, totalInstances = CSK_PersistentData.getModuleParameterName(nameOfModule, '1')
      -- Check for amount if instances to create
      if totalInstances then
        local c = 2
        while c <= totalInstances do
          addInstance()
          c = c+1
        end
      end
    end

    for i = 1, #multiTCPIPServer_Instances do
      local parameterName, loadOnReboot = CSK_PersistentData.getModuleParameterName(nameOfModule, tostring(i))

      if parameterName then
        multiTCPIPServer_Instances[i].parametersName = parameterName
        multiTCPIPServer_Instances[i].parameterLoadOnReboot = loadOnReboot
      end

      if multiTCPIPServer_Instances[i].parameterLoadOnReboot then
        setSelectedInstance(i)
        loadParameters()
      end
    end
    Script.notifyEvent('MultiTCPIPServer_OnDataLoadedOnReboot')
  end
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

