-- Block namespace
local BLOCK_NAMESPACE = 'MultiTCPIPServer_FC.Transmit'
local nameOfModule = 'CSK_MultiTCPIPServer'

--*************************************************************
--*************************************************************

-- Required to keep track of already allocated resource
local instanceTable = {}

local function transmit(handle, source1, source2, source3, source4)

  local sourceEvents = { s1=source1 or 'none', s2=source2 or 'none', s3=source3 or 'none', s4=source4 or 'none'}
  local instance = Container.get(handle, 'Instance')
  local broadcast = Container.get(handle, 'Broadcast')

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

  CSK_MultiTCPIPServer.setSelectedInstance(instance)

  for key, value in pairs(sourceEvents) do
    if value ~= 'none' then
      if broadcast ~= '' then
        CSK_MultiTCPIPServer.setForwardBroadcastEvent(true)
        local suc = CSK_MultiTCPIPServer.setSelectedClientBroadcast(broadcast)
        if not suc then
          CSK_MultiTCPIPServer.setClientBroadcastName(broadcast)
          CSK_MultiTCPIPServer.createClientBroadcast()
          CSK_MultiTCPIPServer.setSelectedClientBroadcast(broadcast)
        end
      else
        CSK_MultiTCPIPServer.setForwardBroadcastEvent(false)
      end
      CSK_MultiTCPIPServer.addEventToForward(value)
    end
  end
end
Script.serveFunction(BLOCK_NAMESPACE .. '.transmit', transmit)

--*************************************************************
--*************************************************************

local function create(instance, broadcast)

  local fullInstanceName = tostring(instance)
  if broadcast then
    fullInstanceName = fullInstanceName .. tostring(broadcast)
  end

  -- Check if same instance is already configured
  if instance < 1 or nil ~= instanceTable[fullInstanceName] then
    _G.logger:warning(nameOfModule .. ': Instance invalid or already in use, please choose another one')
    return nil
  else
    -- Otherwise create handle and store the restriced resource
    local handle = Container.create()
    instanceTable[fullInstanceName] = fullInstanceName
    Container.add(handle, 'Instance', instance)
    Container.add(handle, 'Broadcast', broadcast)
    return handle
  end
end
Script.serveFunction(BLOCK_NAMESPACE .. '.create', create)

--- Function to reset instances if FlowConfig was cleared
local function handleOnClearOldFlow()
  Script.releaseObject(instanceTable)
  instanceTable = {}
end
Script.register('CSK_FlowConfig.OnClearOldFlow', handleOnClearOldFlow)