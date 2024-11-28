--MIT License
--
--Copyright (c) 2023 SICK AG
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.

---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

-- If app property "LuaLoadAllEngineAPI" is FALSE, use this to load and check for required APIs
-- This can improve performance of garbage collection
_G.availableAPIs = require('Communication/MultiTCPIPServer/helper/checkAPIs') -- can be used to adjust function scope of the module related on available APIs of the device

-----------------------------------------------------------
-- Logger
_G.logger = Log.SharedLogger.create('ModuleLogger')
_G.logHandle = Log.Handler.create()
_G.logHandle:attachToSharedLogger('ModuleLogger')
_G.logHandle:setConsoleSinkEnabled(false) --> Set to TRUE if CSK_Logger is not used
_G.logHandle:setLevel("ALL")
_G.logHandle:applyConfig()
-----------------------------------------------------------

-- Loading script regarding MultiTCPIPServer_Model
-- Check this script regarding MultiTCPIPServer_Model parameters and functions
local multiTCPIPServer_Model = require('Communication/MultiTCPIPServer/MultiTCPIPServer_Model')

local multiTCPIPServer_Instances = {} -- Handle all instances

-- Load script to communicate with the MultiTCPIPServer_Model UI
-- Check / edit this script to see/edit functions which communicate with the UI
local multiTCPIPServerController = require('Communication/MultiTCPIPServer/MultiTCPIPServer_Controller')

if _G.availableAPIs.default and _G.availableAPIs.specific then
  local setInstanceHandle = require('Communication/MultiTCPIPServer/FlowConfig/MultiTCPIPServer_FlowConfig')
  table.insert(multiTCPIPServer_Instances, multiTCPIPServer_Model.create(1)) -- Create at least 1 instance
  multiTCPIPServerController.setMultiTCPIPServer_Instances_Handle(multiTCPIPServer_Instances) -- share handle of instances
  setInstanceHandle(multiTCPIPServer_Instances)
else
  _G.logger:warning("CSK_MultiTCPIPServer: Relevant CROWN(s) not available on device. Module is not supported...")
end

--**************************************************************************
--**********************End Global Scope ***********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to react on startup event of the app
local function main()

  multiTCPIPServerController.setMultiTCPIPServer_Model_Handle(multiTCPIPServer_Model) -- share handle of Model

  ----------------------------------------------------------------------------------------
  -- INFO: Please check if module will eventually load inital configuration triggered via
  --       event CSK_PersistentData.OnInitialDataLoaded
  --       (see internal variable _G.multiTCPIPServer_Model.parameterLoadOnReboot)
  --       If so, the app will trigger the "OnDataLoadedOnReboot" event if ready after loading parameters
  --
  -- Can be used e.g. like this
  ----------------------------------------------------------------------------------------

  if _G.availableAPIs.default and _G.availableAPIs.specific then
    CSK_MultiTCPIPServer.setSelectedInstance(1)
  end
  CSK_MultiTCPIPServer.pageCalled() -- Update UI
end
Script.register("Engine.OnStarted", main)

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************