---@diagnostic disable: redundant-parameter, undefined-global

--***************************************************************
-- Inside of this script, you will find the relevant parameters
-- for this module and its default values
--***************************************************************

local functions = {}

local function getParameters()

  local multiTCPIPServerParameters = {}
  multiTCPIPServerParameters.flowConfigPriority = CSK_FlowConfig ~= nil or false -- Status if FlowConfig should have priority for FlowConfig relevant configurations
  multiTCPIPServerParameters.listenState = false -- Status if server should be active to listen for clients
  multiTCPIPServerParameters.processingFile = 'CSK_MultiTCPIPServer_Processing' -- which file to use for processing (will be started in own thread)

  multiTCPIPServerParameters.interface = '' -- Interface to use (must be set individually)

  multiTCPIPServerParameters.port = 1234 -- port number to listen to
  multiTCPIPServerParameters.RxFrameMode = 'Empty' -- type of framing for received data
  multiTCPIPServerParameters.TxFrameMode = 'Empty' -- type of framing for transmitted data
  multiTCPIPServerParameters.framing = {'','','',''} -- array with start/end framing of received and transmitted data
  multiTCPIPServerParameters.framingBufferSize = {10240, 10240} -- array with size of the internal framing parser buffer for received and transmitted data in bytes
  multiTCPIPServerParameters.maxConnections = 10 -- limit of connections
  multiTCPIPServerParameters.transmitAckTimeout = 15000 -- data transmittion acknowledgement timeout in millliseconds
  multiTCPIPServerParameters.transmitBufferSize = 0 --  size of the socket’s send buffer
  multiTCPIPServerParameters.transmitTimeout = 15000 -- timeout for transmits, in milliseconds
  multiTCPIPServerParameters.forwardEvents = {} -- List of events to register to and forward content to TCP/IP server
  multiTCPIPServerParameters.clientWhitelists = {} -- info about configured client whitelists
  multiTCPIPServerParameters.clientBroadcasts = {} -- info about configured client broadcasts
  multiTCPIPServerParameters.clientBroadcasts.names = {} -- Names of configured client broadcasts
  multiTCPIPServerParameters.clientBroadcasts.forwardEvents = {} -- List of events to register to and forward content to TCP/IP server limited to client broadcast
  multiTCPIPServerParameters.onReceivedDataEventName = 'CSK_MultiTCPIPServer.OnReceivedDataNUM' -- event name to register to get any received data (must be set individually)
  multiTCPIPServerParameters.sendDataFunctionName = 'CSK_MultiTCPIPServer.sendDataNUM' -- function name to call to send data to all clients (must be set individually)

  return multiTCPIPServerParameters
end
functions.getParameters = getParameters

return functions