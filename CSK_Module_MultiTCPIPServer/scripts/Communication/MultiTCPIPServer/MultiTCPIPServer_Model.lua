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

local json = require('Communication/MultiTCPIPServer/helper/Json')

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

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

  --self.object = Image.create() -- Use any AppEngine CROWN
  --self.counter = 1 -- Short docu of variable
  --self.varA = 'value' -- Short docu of variable

  -- Parameters to be saved permanently if wanted
  self.parameters = {}
  self.parameters.listenState = false
  self.parameters.registeredEvent = '' -- If thread internal function should react on external event, define it here, e.g. 'CSK_OtherModule.OnNewInput'
  self.parameters.processingFile = 'CSK_MultiTCPIPServer_Processing' -- which file to use for processing (will be started in own thread)
  self.currentDevice = Engine.getTypeName()
  if self.currentDevice == 'Webdisplay' then
    self.parameters.interface = 'ETH1'
  elseif self.currentDevice == 'SICK AppEngine' then
    self.parameters.interface = ""
  else
    local interfaceList = Ethernet.Interface.getInterfaces()
    self.parameters.interface = interfaceList[1]
  end
  self.parameters.port = 20
  self.parameters.RxFrameMode = 'Empty'
  self.parameters.TxFrameMode = 'Empty'
  self.RxFramingList = {'STX-ETX', 'Empty', 'Custom'}
  self.TxFramingList = {'STX-ETX', 'Empty', 'Custom'}
  self.parameters.framing = {'','','',''}
  self.parameters.framingBufferSize = {10240, 10240}
  self.parameters.maxConnections = 10
  self.parameters.transmitAckTimeout = 15000
  self.parameters.transmitBufferSize = 0
  self.parameters.transmitTimeout = 15000
  self.parameters.readMessages = {}
  self.parameters.writeMessages = {}
  self.parameters.onRecevedDataEventName = 'CSK_MultiTCPIPServer.OnReceivedData' .. self.multiTCPIPServerInstanceNoString
  self.parameters.sendDataFunctionName = 'CSK_MultiTCPIPServer.sendData' .. self.multiTCPIPServerInstanceNoString

  -- Parameters to give to the processing script
  self.multiTCPIPServerProcessingParams = Container.create()
  self.multiTCPIPServerProcessingParams:add('multiTCPIPServerInstanceNumber', multiTCPIPServerInstanceNo, "INT")
  self.multiTCPIPServerProcessingParams:add('activeInUI', self.activeInUI, "BOOL")
  self.multiTCPIPServerProcessingParams:add('registeredEvent', self.parameters.registeredEvent, "STRING")
  self.multiTCPIPServerProcessingParams:add('listenState', self.parameters.listenState, "BOOL")
  self.multiTCPIPServerProcessingParams:add('interface', self.parameters.interface, "STRING")
  self.multiTCPIPServerProcessingParams:add('port', self.parameters.port, "INT")
  self.multiTCPIPServerProcessingParams:add('framing', json.encode(self.parameters.framing), "STRING")
  self.multiTCPIPServerProcessingParams:add('framingBufferSize', json.encode(self.parameters.framingBufferSize), "STRING")
  self.multiTCPIPServerProcessingParams:add('maxConnections', self.parameters.maxConnections, "INT")
  self.multiTCPIPServerProcessingParams:add('transmitAckTimeout', self.parameters.transmitAckTimeout, "INT")
  self.multiTCPIPServerProcessingParams:add('transmitBufferSize', self.parameters.transmitBufferSize, "INT")
  self.multiTCPIPServerProcessingParams:add('transmitTimeout', self.parameters.transmitTimeout, "INT")
  self.multiTCPIPServerProcessingParams:add('readMessages', json.encode(self.parameters.readMessages), "STRING")
  self.multiTCPIPServerProcessingParams:add('writeMessages', json.encode(self.parameters.writeMessages), "STRING")
  self.multiTCPIPServerProcessingParams:add('onRecevedDataEventName', self.parameters.onRecevedDataEventName, "STRING")
  self.multiTCPIPServerProcessingParams:add('sendDataFunctionName', self.parameters.sendDataFunctionName, "STRING")

  --self.multiTCPIPServerProcessingParams:add('showImage', self.parameters.showImage, "BOOL")
  --self.multiTCPIPServerProcessingParams:add('viewerId', 'multiTCPIPServerViewer' .. self.multiTCPIPServerInstanceNoString, "STRING")

  --self.multiTCPIPServerProcessingParams:add('internalObjects', internalObjectContainer, "OBJECT") -- optionally
  --self.multiTCPIPServerProcessingParams:add('selectedObject', self.parameters.selectedObject, "INT")

  -- Handle processing
  Script.startScript(self.parameters.processingFile, self.multiTCPIPServerProcessingParams)

  return self
end

--[[
--- Some internal code docu for local used function to do something
function multiTCPIPServer:doSomething()
  self.object:doSomething()
end

--- Some internal code docu for local used function to do something else
function multiTCPIPServer:doSomethingElse()
  self:doSomething() --> access internal function
end
]]

return multiTCPIPServer

--*************************************************************************
--********************** End Function Scope *******************************
--*************************************************************************