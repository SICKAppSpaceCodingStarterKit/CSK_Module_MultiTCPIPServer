-- Block namespace
local BLOCK_NAMESPACE = "MultiTCPIPServer_FC.OnReceive"
local nameOfModule = 'CSK_MultiTCPIPServer'

--*************************************************************
--*************************************************************

-- Required to keep track of already allocated resource
local instanceTable = {}

local function register(handle, _ , callback)

  Container.remove(handle, "CB_Function")
  Container.add(handle, "CB_Function", callback)

  local instance = Container.get(handle, 'Instance')
  local whitelist = Container.get(handle, 'Whitelist')

  -- Check if amount of instances is valid
  -- if not: add multiple additional instances
  while true do
    local amount = CSK_MultiTCPIPServer.getInstancesAmount()
    if amount < instance then
      CSK_MultiTCPIPServer.addInstance()
    else
      break
    end
  end

  if whitelist ~= '' then
    local suc = CSK_MultiTCPIPServer.setSelectedClientWhitelist(whitelist)
    if not suc then
      CSK_MultiTCPIPServer.setClientWhitelistName(whitelist)
      CSK_MultiTCPIPServer.createClientWhitelist()
    end
  end

  local function localCallback()
    local whitelist = Container.get(handle, 'Whitelist')
    local cbFunction = Container.get(handle,"CB_Function")

    if cbFunction ~= nil then
      if whitelist ~= '' then
        Script.callFunction(cbFunction, 'CSK_MultiTCPIPServer.OnReceivedData' .. tostring(instance) .. '_' .. tostring(whitelist))
      else
        Script.callFunction(cbFunction, 'CSK_MultiTCPIPServer.OnReceivedData' .. tostring(instance))
      end
    else
      _G.logger:warning(nameOfModule .. ": " .. BLOCK_NAMESPACE .. ".CB_Function missing!")
    end
  end
  Script.register('CSK_FlowConfig.OnNewFlowConfig', localCallback)

  return true
end
Script.serveFunction(BLOCK_NAMESPACE ..".register", register)

--*************************************************************
--*************************************************************

local function create(instance, whitelist)

  local fullInstanceName = tostring(instance)
  if whitelist then
    fullInstanceName = fullInstanceName .. tostring(whitelist)
  end

  -- Check if same instance is already configured
  if instance < 1 or instanceTable[fullInstanceName] ~= nil then
    _G.logger:warning(nameOfModule .. "Instance invalid or already in use, please choose another one")
    return nil
  else
    -- Otherwise create handle and store the restriced resource
    local handle = Container.create()
    instanceTable[fullInstanceName] = fullInstanceName
    Container.add(handle, 'Instance', instance)
    if whitelist then
      Container.add(handle, 'Whitelist', whitelist)
    else
      Container.add(handle, 'Whitelist', '')
    end
    Container.add(handle, "CB_Function", "")
    return handle
  end
end
Script.serveFunction(BLOCK_NAMESPACE .. ".create", create)

--- Function to reset instances if FlowConfig was cleared
local function handleOnClearOldFlow()
  Script.releaseObject(instanceTable)
  instanceTable = {}
end
Script.register('CSK_FlowConfig.OnClearOldFlow', handleOnClearOldFlow)