---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the module definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_MultiTCPIPServer'

-- Create kind of "class"
local multiTCPIPServer = {}
multiTCPIPServer.__index = multiTCPIPServer

multiTCPIPServer.styleForUI = 'None' -- Optional parameter to set UI style
multiTCPIPServer.version = Engine.getCurrentAppVersion() -- Version of module

local json = require('Communication/MultiTCPIPServer/helper/Json')

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to react on UI style change
local function handleOnStyleChanged(theme)
  multiTCPIPServer.styleForUI = theme
  Script.notifyEvent("MultiTCPIPServer_OnNewStatusCSKStyle", multiTCPIPServer.styleForUI)
end
Script.register('CSK_PersistentData.OnNewStatusCSKStyle', handleOnStyleChanged)

--- Function to create new instance
---@param multiTCPIPServerInstanceNo int Number of instance
---@return table[] self Instance of multiTCPIPServer
function multiTCPIPServer.create(multiTCPIPServerInstanceNo)

  local self = {}
  setmetatable(self, multiTCPIPServer)

  self.multiTCPIPServerInstanceNo = multiTCPIPServerInstanceNo -- Number of this instance
  self.multiTCPIPServerInstanceNoString = tostring(self.multiTCPIPServerInstanceNo) -- Number of this instance as string
  self.helperFuncs = require('Communication/MultiTCPIPServer/helper/funcs') -- Load helper functions

  -- Create parameters etc. for this module instance
  self.activeInUI = (multiTCPIPServerInstanceNo == 1) -- Check if this instance is currently active in UI

  -- Check if CSK_PersistentData module can be used if wanted
  self.persistentModuleAvailable = CSK_PersistentData ~= nil or false

  -- Check if CSK_UserManagement module can be used if wanted
  self.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

  -- Default values for persistent data
  -- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
  self.parametersName = 'CSK_MultiTCPIPServer_Parameter' .. self.multiTCPIPServerInstanceNoString -- name of parameter dataset to be used for this module
  self.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

  self.RxFramingList = {'STX-ETX', 'Empty', 'Custom'} -- available framing types for received data
  self.TxFramingList = {'STX-ETX', 'Empty', 'Custom'} -- available framing types for transmitted data

  -- Parameters to be saved permanently if wanted
  self.parameters = {}
  self.parameters.flowConfigPriority = CSK_FlowConfig ~= nil or false -- Status if FlowConfig should have priority for FlowConfig relevant configurations
  self.parameters.listenState = false -- Status if server should be active to listen for clients
  self.parameters.processingFile = 'CSK_MultiTCPIPServer_Processing' -- which file to use for processing (will be started in own thread)
  self.currentDevice = Engine.getTypeName() -- device type running the app
  if self.currentDevice == 'Webdisplay' then
    self.parameters.interface = 'ETH1' -- ethernet interface to listen to
  elseif self.currentDevice == 'SICK AppEngine' then
    self.parameters.interface = ""
  else
    local interfaceList = Ethernet.Interface.getInterfaces()
    self.parameters.interface = interfaceList[1]
  end
  self.parameters.port = 1234 -- port number to listen to
  self.parameters.RxFrameMode = 'Empty' -- type of framing for received data
  self.parameters.TxFrameMode = 'Empty' -- type of framing for transmitted data
  self.parameters.framing = {'','','',''} -- array with start/end framing of received and transmitted data
  self.parameters.framingBufferSize = {10240, 10240} -- array with size of the internal framing parser buffer for received and transmitted data in bytes
  self.parameters.maxConnections = 10 -- limit of connections
  self.parameters.transmitAckTimeout = 15000 -- data transmittion acknowledgement timeout in millliseconds
  self.parameters.transmitBufferSize = 0 --  size of the socket’s send buffer
  self.parameters.transmitTimeout = 15000 -- timeout for transmits, in milliseconds
  self.parameters.forwardEvents = {} -- List of events to register to and forward content to TCP/IP server
  self.parameters.clientWhitelists = {} -- info about configured client whitelists
  self.parameters.clientBroadcasts = {} -- info about configured client broadcasts
  self.parameters.clientBroadcasts.names = {} -- Names of configured client broadcasts
  self.parameters.clientBroadcasts.forwardEvents = {} -- List of events to register to and forward content to TCP/IP server limited to client broadcast
  self.parameters.onReceivedDataEventName = 'CSK_MultiTCPIPServer.OnReceivedData' .. self.multiTCPIPServerInstanceNoString -- event name to register to get any received data
  self.parameters.sendDataFunctionName = 'CSK_MultiTCPIPServer.sendData' .. self.multiTCPIPServerInstanceNoString -- function name to call to send data to all clients

  -- Parameters to give to the processing script
  self.multiTCPIPServerProcessingParams = Container.create()
  self.multiTCPIPServerProcessingParams:add('multiTCPIPServerInstanceNumber', multiTCPIPServerInstanceNo, "INT")
  self.multiTCPIPServerProcessingParams:add('activeInUI', self.activeInUI, "BOOL")
  self.multiTCPIPServerProcessingParams:add('listenState', self.parameters.listenState, "BOOL")
  self.multiTCPIPServerProcessingParams:add('interface', self.parameters.interface, "STRING")
  self.multiTCPIPServerProcessingParams:add('port', self.parameters.port, "INT")
  self.multiTCPIPServerProcessingParams:add('framing', json.encode(self.parameters.framing), "STRING")
  self.multiTCPIPServerProcessingParams:add('framingBufferSize', json.encode(self.parameters.framingBufferSize), "STRING")
  self.multiTCPIPServerProcessingParams:add('maxConnections', self.parameters.maxConnections, "INT")
  self.multiTCPIPServerProcessingParams:add('transmitAckTimeout', self.parameters.transmitAckTimeout, "INT")
  self.multiTCPIPServerProcessingParams:add('transmitBufferSize', self.parameters.transmitBufferSize, "INT")
  self.multiTCPIPServerProcessingParams:add('transmitTimeout', self.parameters.transmitTimeout, "INT")
  self.multiTCPIPServerProcessingParams:add('clientWhitelists', json.encode(self.parameters.clientWhitelists), "STRING")
  self.multiTCPIPServerProcessingParams:add('clientBroadcasts', json.encode(self.parameters.clientBroadcasts), "STRING")
  self.multiTCPIPServerProcessingParams:add('onReceivedDataEventName', self.parameters.onReceivedDataEventName, "STRING")
  self.multiTCPIPServerProcessingParams:add('sendDataFunctionName', self.parameters.sendDataFunctionName, "STRING")

  -- Handle processing
  Script.startScript(self.parameters.processingFile, self.multiTCPIPServerProcessingParams)

  return self
end

return multiTCPIPServer

--*************************************************************************
--********************** End Function Scope *******************************
--*************************************************************************