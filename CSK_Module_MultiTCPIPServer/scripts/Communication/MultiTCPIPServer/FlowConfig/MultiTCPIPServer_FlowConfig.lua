--*****************************************************************
-- Here you will find all the required content to provide specific
-- features of this module via the 'CSK FlowConfig'.
--*****************************************************************

require('Communication.MultiTCPIPServer.FlowConfig.MultiTCPIPServer_OnReceive')
require('Communication.MultiTCPIPServer.FlowConfig.MultiTCPIPServer_Transmit')

-- Reference to the multiTCPIPServer_Instances handle
local multiTCPIPServer_Instances

--- Function to react if FlowConfig was updated
local function handleOnClearOldFlow()
  if _G.availableAPIs.default and _G.availableAPIs.specific then
    for i = 1, #multiTCPIPServer_Instances do
      if multiTCPIPServer_Instances[i].parameters.flowConfigPriority then
        CSK_MultiTCPIPServer.clearFlowConfigRelevantConfiguration()
        break
      end
    end
  end
end
Script.register('CSK_FlowConfig.OnClearOldFlow', handleOnClearOldFlow)

--- Function to get access to the multiTCPIPServer_Instances
---@param handle handle Handle of multiTCPIPServer_Instances object
local function setMultiTCPIPServer_Instances_Handle(handle)
  multiTCPIPServer_Instances = handle
end

return setMultiTCPIPServer_Instances_Handle