---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the MultiTCPIPServer_Model and _Instances
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_MultiTCPIPServer'

local funcs = {}

-- Timer to update UI via events after page was loaded
local tmrMultiTCPIPServer = Timer.create()
tmrMultiTCPIPServer:setExpirationTime(300)
tmrMultiTCPIPServer:setPeriodic(false)

local multiTCPIPServer_Model -- Reference to model handle
local multiTCPIPServer_Instances -- Reference to instances handle
local selectedInstance = 1 -- Which instance is currently selected
local helperFuncs = require('Communication/MultiTCPIPServer/helper/funcs')

-- ************************ UI Events Start ********************************
-- Only to prevent WARNING messages, but these are only examples/placeholders for dynamically created events/functions
----------------------------------------------------------------
local function emptyFunction()
end
Script.serveFunction("CSK_MultiTCPIPServer.processInstanceNUM", emptyFunction)

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

-- ...

-- ************************ UI Events End **********************************

--[[
--- Some internal code docu for local used function
local function functionName()
  -- Do something

end
]]

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
  -- Script.notifyEvent("MultiTCPIPServer_OnNewEvent", false)

  updateUserLevel()

  Script.notifyEvent('MultiTCPIPServer_OnNewSelectedInstance', selectedInstance)
  Script.notifyEvent("MultiTCPIPServer_OnNewInstanceList", helperFuncs.createStringListBySize(#multiTCPIPServer_Instances))

  Script.notifyEvent("MultiTCPIPServer_OnNewStatusRegisteredEvent", multiTCPIPServer_Instances[selectedInstance].parameters.registeredEvent)

  Script.notifyEvent("MultiTCPIPServer_OnNewStatusLoadParameterOnReboot", multiTCPIPServer_Instances[selectedInstance].parameterLoadOnReboot)
  Script.notifyEvent("MultiTCPIPServer_OnPersistentDataModuleAvailable", multiTCPIPServer_Instances[selectedInstance].persistentModuleAvailable)
  Script.notifyEvent("MultiTCPIPServer_OnNewParameterName", multiTCPIPServer_Instances[selectedInstance].parametersName)

  -- ...
end
Timer.register(tmrMultiTCPIPServer, "OnExpired", handleOnExpiredTmrMultiTCPIPServer)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  tmrMultiTCPIPServer:start()
  return ''
end
Script.serveFunction("CSK_MultiTCPIPServer.pageCalled", pageCalled)

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
  handleOnExpiredTmrMultiTCPIPServer()
end
Script.serveFunction('CSK_MultiTCPIPServer.addInstance', addInstance)

local function resetInstances()
  _G.logger:info(nameOfModule .. ": Reset instances.")
  setSelectedInstance(1)
  local totalAmount = #multiTCPIPServer_Instances
  while totalAmount > 1 do
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

  --Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'value', multiTCPIPServer_Instances[selectedInstance].parameters.value)

  -- optionally for internal objects...
  --[[
  -- Send config to instances
  local params = helperFuncs.convertTable2Container(multiTCPIPServer_Instances[selectedInstance].parameters.internalObject)
  Container.add(data, 'internalObject', params, 'OBJECT')
  Script.notifyEvent('MultiTCPIPServer_OnNewProcessingParameter', selectedInstance, 'FullSetup', data)
  ]]

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

