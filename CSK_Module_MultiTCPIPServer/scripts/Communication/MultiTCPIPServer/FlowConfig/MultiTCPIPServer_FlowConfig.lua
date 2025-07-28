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
    CSK_MultiTCPIPServer.clearFlowConfigRelevantConfiguration()
  end
end
Script.register('CSK_FlowConfig.OnClearOldFlow', handleOnClearOldFlow)
