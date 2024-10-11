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
tmrMultiTCPIPServer:setExpirationTime(300)
tmrMultiTCPIPServer:setPeriodic(false)

local multiTCPIPServer_Model -- Reference to model handle
local multiTCPIPServer_Instances -- Reference to instances handle
local selectedInstance = 1 -- Which instance is currently selected
local selectedTab = 0 -- selected tab ID in UI
local whitelistName = 'clientWhitelist' -- name of the new client broadcast to create
local selectedClientWhitelist = '' -- name of the selected client whitelist
local broadcastName = 'clientBroadcast' -- name of the new client broadcast to create
local selectedClientBroadcast = '' -- name of the selected client broadcast
local testSendData = '' -- generic test data string to send
local testSendDataClientBroadcast = '' -- test data string to send as selected write message
local addIPViaList = false -- Status if selected IP in UI should be added to whitelist/broadcast list
local configBroadcastEvent = false -- Status if forward event config is for broadcast

local eventToForward = '' -- Preset event name to add via UI (see 'addEventToForwardViaUI')
local selectedEventToForward = '' -- Selected event to forward content to TCP/IP server within UI table

-- ************************ UI Events Start ********************************
-- Only to prevent WARNING messages, but these are only examples/placeholders for dynamically created events/functions
----------------------------------------------------------------
local function emptyFunction()
end
Script.serveFunction("CSK_MultiTCPIPServer.sendDataNUM", emptyFunction)
Script.serveFunction("CSK_MultiTCPIPServer.sendDataNUM_BROADCASTNAME", emptyFunction)

Script.serveEvent("CSK_MultiTCPIPServer.OnNewValueToForwardNUM", "MultiTCPIPServer_OnNewValueToForwardNUM")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewValueUpdateNUM", "MultiTCPIPServer_OnNewValueUpdateNUM")
Script.serveEvent('CSK_MultiTCPIPServer.OnReceivedDataNUM', 'MultiTCPIPServer_OnReceivedDataNUM')
Script.serveEvent('CSK_MultiTCPIPServer.OnReceivedDataNUM_WHITELISTNAME', 'MultiTCPIPServer_OnReceivedDataNUM_WHITELISTNAME')

----------------------------------------------------------------

-- Real events
--------------------------------------------------

Script.serveEvent('CSK_MultiTCPIPServer.OnNewStatusModuleVersion', 'MultiTCPIPServer_OnNewStatusModuleVersion')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewStatusCSKStyle', 'MultiTCPIPServer_OnNewStatusCSKStyle')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewStatusModuleIsActive', 'MultiTCPIPServer_OnNewStatusModuleIsActive')

Script.serveEvent("CSK_MultiTCPIPServer.OnNewLog", "MultiTCPIPServer_OnNewLog")
Script.serveEvent('CSK_MultiTCPIPServer.OnNewStatusFlowConfigPriority', 'MultiTCPIPServer_OnNewStatusFlowConfigPriority')
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

Script.serveEvent('CSK_MultiTCPIPServer.OnNewStatusForwardEventForBroadcasts', 'MultiTCPIPServer_OnNewStatusForwardEventForBroadcasts')
Script.serveEvent("CSK_MultiTCPIPServer.OnNewEventToForwardList", "MultiTCPIPServer_OnNewEventToForwardList")

Script.serveEvent('CSK_MultiTCPIPServer.OnNewTestDataToSend', 'MultiTCPIPServer_OnNewTestDataToSend')

Script.serveEvent('CSK_MultiTCPIPServer.OnNewClientWhitelistName', 'MultiTCPIPServer_OnNewClientWhitelistName')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewListClientWhitelist', 'MultiTCPIPServer_OnNewListClientWhitelist')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewClientWhitelistEventName', 'MultiTCPIPServer_OnNewClientWhitelistEventName')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewClientWhitelistTableContent', 'MultiTCPIPServer_OnNewClientWhitelistTableContent')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewStatusClientWhitelistSelected', 'MultiTCPIPServer_OnNewStatusClientWhitelistSelected')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewSelectedClientWhitelist', 'MultiTCPIPServer_OnNewSelectedClientWhitelist')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewStatusAddIPViaList', 'MultiTCPIPServer_OnNewStatusAddIPViaList')

Script.serveEvent('CSK_MultiTCPIPServer.OnNewClientBroadcastName', 'MultiTCPIPServer_OnNewClientBroadcastName')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewListClientBroadcast', 'MultiTCPIPServer_OnNewListClientBroadcast')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewClientBroadcastFunctionName', 'MultiTCPIPServer_OnNewClientBroadcastFunctionName')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewClientBroadcastTableContent', 'MultiTCPIPServer_OnNewClientBroadcastTableContent')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewStatusClientBroadcastSelected', 'MultiTCPIPServer_OnNewStatusClientBroadcastSelected')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewSelectedClientBroadcast', 'MultiTCPIPServer_OnNewSelectedClientBroadcast')
Script.serveEvent('CSK_MultiTCPIPServer.OnNewClientBroadcastTestDataToSend', 'MultiTCPIPServer_OnNewClientBroadcastTestDataToSend')

Script.serveEvent("CSK_MultiTCPIPServer.OnNewStatusLoadParameterOnReboot", "MultiTCPIPServer_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_MultiTCPIPServer.OnPersistentDataModuleAvailable", "MultiTCPIPServer_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_MultiTCPIPServer.OnNewParameterName", "MultiTCPIPServer_OnNewParameterName")

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

local function getInterfaceIP()
  if multiTCPIPServer_Instances[1].currentDevice == 'SICK AppEngine' or multiTCPIPServer_Instances[1].currentDevice == 'Webdisplay' then return '' end
  local _, ipAddress = Ethernet.Interface.getAddressConfig(multiTCPIPServer_Instances[selectedInstance].parameters.interface)
  return ipAddress
end
Script.serveFunction('CSK_MultiTCPIPServer.getInterfaceIP', getInterfaceIP)

---Function to get list of keys of the lua table as a JSON string.
---@param someTable auto[] Table with content
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
  if #list == 0 then
    table.insert(tableContent, {[dynamicTableColumnName] = '-'})
  else
    for _, value in ipairs(list) do
      table.insert(tableContent, {[dynamicTableColumnName] = tostring(value)})
    end
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

  Script.notifyEvent("MultiTCPIPServer_OnNewStatusModuleVersion", 'v' .. multiTCPIPServer_Model.version)
  Script.notifyEvent("MultiTCPIPServer_OnNewStatusCSKStyle", multiTCPIPServer_Model.styleForUI)
  Script.notifyEvent("MultiTCPIPServer_OnNewStatusModuleIsActive", _G.availableAPIs.default and _G.availableAPIs.specific)

  if _G.availableAPIs.default and _G.availableAPIs.specific then

    updateUserLevel()

    addIPViaList = false
    Script.notifyEvent("MultiTCPIPServer_OnNewStatusAddIPViaList", false)

    Script.notifyEvent('MultiTCPIPServer_OnNewSelectedInstance', selectedInstance)
    Script.notifyEvent("MultiTCPIPServer_OnNewInstanceList", helperFuncs.createStringListBySize(#multiTCPIPServer_Instances))

    Script.notifyEvent("MultiTCPIPServer_OnNewStatusLoadParameterOnReboot", multiTCPIPServer_Instances[selectedInstance].parameterLoadOnReboot)
    Script.notifyEvent("MultiTCPIPServer_OnPersistentDataModuleAvailable", multiTCPIPServer_Instances[selectedInstance].persistentModuleAvailable)
    Script.notifyEvent("MultiTCPIPServer_OnNewParameterName", multiTCPIPServer_Instances[selectedInstance].parametersName)
    Script.notifyEvent("MultiTCPIPServer_OnNewStatusFlowConfigPriority", multiTCPIPServer_Instances[selectedInstance].parameters.flowConfigPriority)

    local serverIsActive = multiTCPIPServer_Instances[selectedInstance].parameters.listenState

    Script.notifyEvent("MultiTCPIPServer_OnNewListenState", serverIsActive)

    Script.notifyEvent("MultiTCPIPServer_OnNewInterface", multiTCPIPServer_Instances[selectedInstance].parameters.interface)
    Script.notifyEvent("MultiTCPIPServer_OnNewInterfaceList", createInterfaceList())
    Script.notifyEvent("MultiTCPIPServer_OnNewServerIP", getInterfaceIP())
    Script.notifyEvent("MultiTCPIPServer_OnNewPort", multiTCPIPServer_Instances[selectedInstance].parameters.port)

    Script.notifyEvent("MultiTCPIPServer_OnNewSelectedTab", selectedTab)

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

    Script.notifyEvent("MultiTCPIPServer_OnNewGenericReceivedDataEventName", multiTCPIPServer_Instances[selectedInstance].parameters.onReceivedDataEventName)
    Script.notifyEvent("MultiTCPIPServer_OnNewGenericSendDataFunctionName", multiTCPIPServer_Instances[selectedInstance].parameters.sendDataFunctionName)

    Script.notifyEvent("MultiTCPIPServer_OnNewStatusForwardEventForBroadcasts", configBroadcastEvent)

    if configBroadcastEvent then
      if multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[selectedClientBroadcast] then
        Script.notifyEvent("MultiTCPIPServer_OnNewEventToForwardList", multiTCPIPServer_Instances[selectedInstance].helperFuncs.createSpecificJsonList('eventToForward', multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.forwardEvents[selectedClientBroadcast]))
      else
        Script.notifyEvent("MultiTCPIPServer_OnNewEventToForwardList", multiTCPIPServer_Instances[selectedInstance].helperFuncs.createSpecificJsonList('eventToForward', nil))
      end
    else
      Script.notifyEvent("MultiTCPIPServer_OnNewEventToForwardList", multiTCPIPServer_Instances[selectedInstance].helperFuncs.createSpecificJsonList('eventToForward', multiTCPIPServer_Instances[selectedInstance].parameters.forwardEvents))
    end

    Script.notifyEvent('MultiTCPIPServer_OnNewClientWhitelistName', whitelistName)
    Script.notifyEvent('MultiTCPIPServer_OnNewListClientWhitelist', getTableKeyList(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists))
    Script.notifyEvent('MultiTCPIPServer_OnNewSelectedClientWhitelist', selectedClientWhitelist)
    Script.notifyEvent('MultiTCPIPServer_OnNewStatusClientWhitelistSelected', selectedClientWhitelist ~= '')

    if selectedClientWhitelist ~= '' then
      Script.notifyEvent('MultiTCPIPServer_OnNewClientWhitelistEventName', multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists[selectedClientWhitelist].eventName)
      Script.notifyEvent('MultiTCPIPServer_OnNewClientWhitelistTableContent', makeDynamicTableOutOfList('DTC_ClientWhitelistIP', multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists[selectedClientWhitelist].ipFilterInfo.filteredIPs))
    end

    Script.notifyEvent('MultiTCPIPServer_OnNewClientBroadcastName', broadcastName)
    Script.notifyEvent('MultiTCPIPServer_OnNewListClientBroadcast', getTableKeyList(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names))
    Script.notifyEvent('MultiTCPIPServer_OnNewSelectedClientBroadcast', selectedClientBroadcast)
    Script.notifyEvent('MultiTCPIPServer_OnNewStatusClientBroadcastSelected', selectedClientBroadcast ~= '')

    if selectedClientBroadcast ~= '' then
      Script.notifyEvent('MultiTCPIPServer_OnNewClientBroadcastFunctionName', multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[selectedClientBroadcast].functionName)
      Script.notifyEvent('MultiTCPIPServer_OnNewClientBroadcastTableContent', makeDynamicTableOutOfList('DTC_ClientBroadcastIP', multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[selectedClientBroadcast].ipFilterInfo.filteredIPs))
    end

    Script.callFunction("CSK_MultiTCPIPServer.getConnectedClientsIPs" .. tostring(selectedInstance))
  end
end
Timer.register(tmrMultiTCPIPServer, "OnExpired", handleOnExpiredTmrMultiTCPIPServer)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  if _G.availableAPIs.default and _G.availableAPIs.specific then
    updateUserLevel() -- try to hide user specific content asap
  end
  tmrMultiTCPIPServer:start()
  return ''
end
Script.serveFunction("CSK_MultiTCPIPServer.pageCalled", pageCalled)

local function setSelectedTab(newSelectedTab)
  selectedTab = newSelectedTab
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

local function setForwardBroadcastEvent(status)
  configBroadcastEvent = status
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setForwardBroadcastEvent', setForwardBroadcastEvent)

local function selectEventToForwardViaUI(selection)

  if selection == "" then
    selectedEventToForward = ''
    _G.logger:warning(nameOfModule .. ": Did not find EventToForward. Is empty")
  else
    local _, pos = string.find(selection, '"EventToForward":"')
    if pos == nil then
      _G.logger:warning(nameOfModule .. ": Did not find EventToForward. Is nil")
      selectedEventToForward = ''
    else
      pos = tonumber(pos)
      local endPos = string.find(selection, '"', pos+1)
      selectedEventToForward = string.sub(selection, pos+1, endPos-1)
      if ( selectedEventToForward == nil or selectedEventToForward == "" ) then
        _G.logger:warning(nameOfModule .. ": Did not find EventToForward. Is empty or nil")
        selectedEventToForward = ''
      else
        _G.logger:fine(nameOfModule .. ": Selected EventToForward: " .. tostring(selectedEventToForward))
      end
    end
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.selectEventToForwardViaUI", selectEventToForwardViaUI)

local function addEventToForward(event)
  if configBroadcastEvent then
    if not multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.forwardEvents[selectedClientBroadcast] then
      multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.forwardEvents[selectedClientBroadcast] = {}
    end
    multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.forwardEvents[selectedClientBroadcast][event] = event
    Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'addEvent', event, selectedClientBroadcast)
    Script.notifyEvent("MultiTCPIPServer_OnNewEventToForwardList", multiTCPIPServer_Instances[selectedInstance].helperFuncs.createSpecificJsonList('eventToForward', multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.forwardEvents[selectedClientBroadcast]))
  else
    multiTCPIPServer_Instances[selectedInstance].parameters.forwardEvents[event] = event
    Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'addEvent', event)
    Script.notifyEvent("MultiTCPIPServer_OnNewEventToForwardList", multiTCPIPServer_Instances[selectedInstance].helperFuncs.createSpecificJsonList('eventToForward', multiTCPIPServer_Instances[selectedInstance].parameters.forwardEvents))
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.addEventToForward", addEventToForward)

local function addEventToForwardViaUI()
  addEventToForward(eventToForward)
end
Script.serveFunction("CSK_MultiTCPIPServer.addEventToForwardViaUI", addEventToForwardViaUI)

local function deleteEventToForward(event)
  if configBroadcastEvent and multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.forwardEvents[selectedClientBroadcast][event] then
    multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.forwardEvents[selectedClientBroadcast][event] = nil
    Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'removeEvent', event, selectedClientBroadcast)
    Script.notifyEvent("MultiTCPIPServer_OnNewEventToForwardList", multiTCPIPServer_Instances[selectedInstance].helperFuncs.createSpecificJsonList('eventToForward', multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.forwardEvents[selectedClientBroadcast]))
  else
    multiTCPIPServer_Instances[selectedInstance].parameters.forwardEvents[event] = nil
    Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'removeEvent', event)
    Script.notifyEvent("MultiTCPIPServer_OnNewEventToForwardList", multiTCPIPServer_Instances[selectedInstance].helperFuncs.createSpecificJsonList('eventToForward', multiTCPIPServer_Instances[selectedInstance].parameters.forwardEvents))
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.deleteEventToForward", deleteEventToForward)

local function deleteEventToForwardViaUI()
  if selectedEventToForward ~= '' then
    deleteEventToForward(selectedEventToForward)
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.deleteEventToForwardViaUI", deleteEventToForwardViaUI)

local function setEventToForward(value)
  eventToForward = value
  _G.logger:fine(nameOfModule .. ": Set eventToForward = " .. tostring(value))
end
Script.serveFunction("CSK_MultiTCPIPServer.setEventToForward", setEventToForward)

--**************************************************************************
--********************* Show received or write data ************************
--**************************************************************************

local function setTestDataToSend(newTestDataToSend)
  testSendData = newTestDataToSend
end
Script.serveFunction('CSK_MultiTCPIPServer.setTestDataToSend', setTestDataToSend)

local function sendTestData()
  local _, success = Script.callFunction(multiTCPIPServer_Instances[selectedInstance].parameters.sendDataFunctionName, testSendData)
end
Script.serveFunction('CSK_MultiTCPIPServer.sendTestData', sendTestData)

--**************************************************************************
--************************* Client whitelist scope *************************
--**************************************************************************

local function setSelectedClientWhitelist(clientWhitelistName)
  if not multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists[clientWhitelistName] then
    handleOnExpiredTmrMultiTCPIPServer()
    return false
  end
  selectedClientWhitelist = clientWhitelistName
  handleOnExpiredTmrMultiTCPIPServer()
  return true
end
Script.serveFunction('CSK_MultiTCPIPServer.setSelectedClientWhitelist', setSelectedClientWhitelist)

local function createClientWhitelist()
  if not multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists[whitelistName] then
    multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists[whitelistName] = {
      eventName = 'CSK_MultiTCPIPServer.OnReceivedData' .. tostring(selectedInstance) .. '_' .. whitelistName,
      ipFilterInfo = {
        filteredIPs = {}
      }
    }
    Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'clientWhitelists', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists))
    selectedClientWhitelist = whitelistName
  else
    _G.logger:fine(nameOfModule .. ": Whitelist already exists.")
  end
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.createClientWhitelist', createClientWhitelist)

local function deleteClientWhitelist()
  multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists[selectedClientWhitelist] = nil
  selectedClientWhitelist = ''
  if not multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists then
    multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists = {}
  end
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'clientWhitelists', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.deleteClientWhitelist', deleteClientWhitelist)

local function setClientWhitelistName(newName)
  whitelistName = newName
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setClientWhitelistName', setClientWhitelistName)

local function setIPAddressToAddToClientWhitelist(ipAddress)
  if not helperFuncs.checkIP(ipAddress) then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  for _, addedIP in ipairs(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists[selectedClientWhitelist].ipFilterInfo.filteredIPs) do
    if addedIP == ipAddress then
      handleOnExpiredTmrMultiTCPIPServer()
      return
    end
  end
  table.insert(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists[selectedClientWhitelist].ipFilterInfo.filteredIPs, ipAddress)
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'clientWhitelists', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setIPAddressToAddToClientWhitelist', setIPAddressToAddToClientWhitelist)

local function deleteClientWhitelistIPAddress(jsonRowToDelete)
  local rowContent = json.decode(jsonRowToDelete)
  for index, ipAddress in ipairs(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists[selectedClientWhitelist].ipFilterInfo.filteredIPs) do
    if ipAddress == rowContent['DTC_ClientWhitelistIP'] then
      table.remove(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists[selectedClientWhitelist].ipFilterInfo.filteredIPs, index)
      break
    end
  end
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'clientWhitelists', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.deleteClientWhitelistIPAddress', deleteClientWhitelistIPAddress)

--**************************************************************************
--************************* Client broadcast scope *************************
--**************************************************************************

local function setSelectedClientBroadcast(clientBroadcastName)
  if not multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[clientBroadcastName] then
    handleOnExpiredTmrMultiTCPIPServer()
    return false
  end
  selectedClientBroadcast = clientBroadcastName
  handleOnExpiredTmrMultiTCPIPServer()
  return true
end
Script.serveFunction('CSK_MultiTCPIPServer.setSelectedClientBroadcast', setSelectedClientBroadcast)

local function createClientBroadcast()
  if not multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[broadcastName] then
    multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[broadcastName] = {
      functionName = 'CSK_MultiTCPIPServer.sendData' .. tostring(selectedInstance) .. '_' .. broadcastName,
      ipFilterInfo = {
        filteredIPs = {}
      }
    }
    Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'clientBroadcasts', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names))
    selectedClientBroadcast = broadcastName
  else
    _G.logger:fine(nameOfModule .. ": Broadcast already exists.")
  end
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.createClientBroadcast', createClientBroadcast)

local function deleteClientBroadcast()
  multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[selectedClientBroadcast] = nil
  selectedClientBroadcast = ''
  if not multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names then
    multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names = {}
  end
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'clientBroadcasts', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.deleteClientBroadcast', deleteClientBroadcast)

local function setClientBroadcastName(newName)
  broadcastName = newName
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setClientBroadcastName', setClientBroadcastName)

local function setIPAddressToAddToClientBroadcast(ipAddress)
  if not helperFuncs.checkIP(ipAddress) then
    handleOnExpiredTmrMultiTCPIPServer()
    return
  end
  for _, addedIP in ipairs(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[selectedClientBroadcast].ipFilterInfo.filteredIPs) do
    if addedIP == ipAddress then
      handleOnExpiredTmrMultiTCPIPServer()
      return
    end
  end
  table.insert(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[selectedClientBroadcast].ipFilterInfo.filteredIPs, ipAddress)
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'clientBroadcasts', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.setIPAddressToAddToClientBroadcast', setIPAddressToAddToClientBroadcast)

local function deleteClientBroadcastFilterIPAddress(jsonRowToDelete)
  local rowContent = json.decode(jsonRowToDelete)
  for index, ipAddress in ipairs(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[selectedClientBroadcast].ipFilterInfo.filteredIPs) do
    if ipAddress == rowContent['DTC_ClientBroadcastIP'] then
      table.remove(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[selectedClientBroadcast].ipFilterInfo.filteredIPs, index)
      break
    end
  end
  Script.notifyEvent("MultiTCPIPServer_OnNewProcessingParameter", selectedInstance, 'clientBroadcasts', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names))
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.deleteClientBroadcastFilterIPAddress', deleteClientBroadcastFilterIPAddress)

local function setClientBroadcastTestDataToSend(newTestDataToSend)
  testSendDataClientBroadcast = newTestDataToSend
end
Script.serveFunction('CSK_MultiTCPIPServer.setClientBroadcastTestDataToSend', setClientBroadcastTestDataToSend)

local function sendClientBroadcastTestData()
  if multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[selectedClientBroadcast].functionName then
    local _, success = Script.callFunction(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names[selectedClientBroadcast].functionName, testSendDataClientBroadcast)
  else
    _G.logger:fine(nameOfModule .. ": No clientBroadcast selected.")
  end
end
Script.serveFunction('CSK_MultiTCPIPServer.sendClientBroadcastTestData', sendClientBroadcastTestData)

--**************************************************************************
--******************** Connected clients table scope ***********************
--**************************************************************************

local function selectConnectedClient(selectedRow)
  if addIPViaList == true then
    addIPViaList = false
    if selectedTab == 2 and selectedClientWhitelist ~= '' then
      local rowContent = json.decode(selectedRow)
      setIPAddressToAddToClientWhitelist(rowContent.DTC_ConnectedClientIPAddress)
    elseif selectedTab == 3 and selectedClientBroadcast ~= '' then
      local rowContent = json.decode(selectedRow)
      setIPAddressToAddToClientBroadcast(rowContent.DTC_ConnectedClientIPAddress)
    end
  end
end
Script.serveFunction('CSK_MultiTCPIPServer.selectConnectedClient', selectConnectedClient)

local function setAddIPViaList(status)
  addIPViaList = status
end
Script.serveFunction('CSK_MultiTCPIPServer.setAddIPViaList', setAddIPViaList)

--**************************************************************************
--******************** Generic CSK functions scope *************************
--**************************************************************************

local function setSelectedInstance(instance)
  if #multiTCPIPServer_Instances >= instance then
    selectedInstance = instance
    selectedClientBroadcast = ''
    selectedClientWhitelist = ''
    for key in pairs(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists) do
      selectedClientWhitelist = key
      break
    end

    for key in pairs(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names) do
      selectedClientBroadcast = key
      break
    end

    _G.logger:fine(nameOfModule .. ": New selected instance = " .. tostring(selectedInstance))
    multiTCPIPServer_Instances[selectedInstance].activeInUI = true
    Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'activeInUI', true)
    Script.notifyEvent("MultiTCPIPServer_OnNewLog", '')
    tmrMultiTCPIPServer:start()
  else
    _G.logger:warning(nameOfModule .. ": Selected instance does not exist.")
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.setSelectedInstance", setSelectedInstance)

local function getInstancesAmount ()
  if multiTCPIPServer_Instances then
    return #multiTCPIPServer_Instances
  else
    return 0
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.getInstancesAmount", getInstancesAmount)

local function addInstance()
  _G.logger:fine(nameOfModule .. ": Add instance")
  table.insert(multiTCPIPServer_Instances, multiTCPIPServer_Model.create(#multiTCPIPServer_Instances+1))
  Script.deregister("CSK_MultiTCPIPServer.OnNewValueToForward" .. tostring(#multiTCPIPServer_Instances) , handleOnNewValueToForward)
  Script.register("CSK_MultiTCPIPServer.OnNewValueToForward" .. tostring(#multiTCPIPServer_Instances) , handleOnNewValueToForward)
  Script.deregister("CSK_MultiTCPIPServer.OnNewValueUpdate" .. tostring(#multiTCPIPServer_Instances) , handleOnNewValueUpdate)
  Script.register("CSK_MultiTCPIPServer.OnNewValueUpdate" .. tostring(#multiTCPIPServer_Instances) , handleOnNewValueUpdate)
  setSelectedInstance(#multiTCPIPServer_Instances)
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.addInstance', addInstance)

local function resetInstances()
  _G.logger:fine(nameOfModule .. ": Reset instances.")
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

--- Function to share process relevant configuration with processing threads
local function updateProcessingParameters()

  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'listenState', false)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'clearAll')
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'activeInUI', true)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'interface', multiTCPIPServer_Instances[selectedInstance].parameters.interface)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'port', multiTCPIPServer_Instances[selectedInstance].parameters.port)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'framing', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framing))
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'framingBufferSize', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.framingBufferSize))
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'maxConnections', multiTCPIPServer_Instances[selectedInstance].parameters.maxConnections)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'transmitAckTimeout', multiTCPIPServer_Instances[selectedInstance].parameters.transmitAckTimeout)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'transmitBufferSize', multiTCPIPServer_Instances[selectedInstance].parameters.transmitBufferSize)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'transmitTimeout', multiTCPIPServer_Instances[selectedInstance].parameters.transmitTimeout)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'clientWhitelists', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists))
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'clientBroadcasts', json.encode(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names))
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'onReceivedDataEventName', multiTCPIPServer_Instances[selectedInstance].parameters.onReceivedDataEventName)
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'sendDataFunctionName', multiTCPIPServer_Instances[selectedInstance].parameters.sendDataFunctionName)

  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'listenState', multiTCPIPServer_Instances[selectedInstance].parameters.listenState)
end

local function getStatusModuleActive()
  return _G.availableAPIs.default and _G.availableAPIs.specific
end
Script.serveFunction('CSK_MultiTCPIPServer.getStatusModuleActive', getStatusModuleActive)

local function clearFlowConfigRelevantConfiguration()
  for i = 1, #multiTCPIPServer_Instances do
    Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'clearAll')
    multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.forwardEvents = {}
    multiTCPIPServer_Instances[selectedInstance].parameters.forwardEvents = {}
  end
end
Script.serveFunction('CSK_MultiTCPIPServer.clearFlowConfigRelevantConfiguration', clearFlowConfigRelevantConfiguration)

local function getParameters(instanceNo)
  if instanceNo <= #multiTCPIPServer_Instances then
    return helperFuncs.json.encode(multiTCPIPServer_Instances[instanceNo].parameters)
  else
    return ''
  end
end
Script.serveFunction('CSK_MultiTCPIPServer.getParameters', getParameters)

-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  _G.logger:fine(nameOfModule .. ": Set parameter name = " .. tostring(name))
  multiTCPIPServer_Instances[selectedInstance].parametersName = name
end
Script.serveFunction("CSK_MultiTCPIPServer.setParameterName", setParameterName)

local function sendParameters(noDataSave)
  if multiTCPIPServer_Instances[selectedInstance].persistentModuleAvailable then
    CSK_PersistentData.addParameter(helperFuncs.convertTable2Container(multiTCPIPServer_Instances[selectedInstance].parameters), multiTCPIPServer_Instances[selectedInstance].parametersName)

    -- Check if CSK_PersistentData version is >= 3.0.0
    if tonumber(string.sub(CSK_PersistentData.getVersion(), 1, 1)) >= 3 then
      CSK_PersistentData.setModuleParameterName(nameOfModule, multiTCPIPServer_Instances[selectedInstance].parametersName, multiTCPIPServer_Instances[selectedInstance].parameterLoadOnReboot, tostring(selectedInstance), #multiTCPIPServer_Instances)
    else
      CSK_PersistentData.setModuleParameterName(nameOfModule, multiTCPIPServer_Instances[selectedInstance].parametersName, multiTCPIPServer_Instances[selectedInstance].parameterLoadOnReboot, tostring(selectedInstance))
    end
    _G.logger:fine(nameOfModule .. ": Send MultiTCPIPServer parameters with name '" .. multiTCPIPServer_Instances[selectedInstance].parametersName .. "' to CSK_PersistentData module.")
    if not noDataSave then
      CSK_PersistentData.saveData()
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.sendParameters", sendParameters)

--- Function to register to events of other modules after initial load
local function registerToEvents()
  for i = 1, #multiTCPIPServer_Instances do
    for eventForAll in pairs(multiTCPIPServer_Instances[i].parameters.forwardEvents) do
      Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', i, 'addEvent', eventForAll)
    end

    for broadcasts in pairs(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.forwardEvents) do
      for specificEvent in pairs(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.forwardEvents[broadcasts]) do
        Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', i, 'addEvent', specificEvent, broadcasts)
      end
    end
  end
  configBroadcastEvent = false
  Script.notifyEvent("MultiTCPIPServer_OnNewStatusForwardEventForBroadcasts", configBroadcastEvent)
  Script.notifyEvent("MultiTCPIPServer_OnNewEventToForwardList", multiTCPIPServer_Instances[selectedInstance].helperFuncs.createSpecificJsonList('eventToForward', multiTCPIPServer_Instances[selectedInstance].parameters.forwardEvents))
end

local function loadParameters()
  if multiTCPIPServer_Instances[selectedInstance].persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(multiTCPIPServer_Instances[selectedInstance].parametersName)
    if data then
      _G.logger:info(nameOfModule .. ": Loaded parameters for multiTCPIPServerObject " .. tostring(selectedInstance) .. " from CSK_PersistentData module.")
      multiTCPIPServer_Instances[selectedInstance].parameters = helperFuncs.convertContainer2Table(data)

      -- If something needs to be configured/activated with new loaded data
      updateProcessingParameters()

      for key in pairs(multiTCPIPServer_Instances[selectedInstance].parameters.clientWhitelists) do
        selectedClientWhitelist = key
        break
      end

      for key in pairs(multiTCPIPServer_Instances[selectedInstance].parameters.clientBroadcasts.names) do
        selectedClientBroadcast = key
        break
      end

      registerToEvents()

      tmrMultiTCPIPServer:start()
      return true
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
      tmrMultiTCPIPServer:start()
      return false
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
    tmrMultiTCPIPServer:start()
    return false
  end
end
Script.serveFunction("CSK_MultiTCPIPServer.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  multiTCPIPServer_Instances[selectedInstance].parameterLoadOnReboot = status
  _G.logger:fine(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
  Script.notifyEvent("MultiTCPIPServer_OnNewStatusLoadParameterOnReboot", status)
end
Script.serveFunction("CSK_MultiTCPIPServer.setLoadOnReboot", setLoadOnReboot)

local function setFlowConfigPriority(status)
  multiTCPIPServer_Instances[selectedInstance].parameters.flowConfigPriority = status
  _G.logger:fine(nameOfModule .. ": Set new status of FlowConfig priority: " .. tostring(status))
  Script.notifyEvent("MultiTCPIPServer_OnNewStatusFlowConfigPriority", multiTCPIPServer_Instances[selectedInstance].parameters.flowConfigPriority)
end
Script.serveFunction('CSK_MultiTCPIPServer.setFlowConfigPriority', setFlowConfigPriority)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()
  if _G.availableAPIs.default and _G.availableAPIs.specific then
    _G.logger:fine(nameOfModule .. ': Try to initially load parameter from CSK_PersistentData module.')
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

      if not multiTCPIPServer_Instances then
        return
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
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

local function resetModule()
  if _G.availableAPIs.default and _G.availableAPIs.specific then
    clearFlowConfigRelevantConfiguration()
    for i = 1, #multiTCPIPServer_Instances do
      setListenState(false)
    end
    pageCalled()
  end
end
Script.serveFunction('CSK_MultiTCPIPServer.resetModule', resetModule)
Script.register("CSK_PersistentData.OnResetAllModules", resetModule)

-- *************************************************
-- END of functions for CSK_PersistentData module usage
-- *************************************************

return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

