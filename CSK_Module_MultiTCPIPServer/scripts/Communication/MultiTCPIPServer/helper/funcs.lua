---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find helper functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

local funcs = {}
-- Providing standard JSON functions
funcs.json = require('Communication/MultiTCPIPServer/helper/Json')

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to convert hex to string
---@param hex string String with hex content
---@return string readableString Readable string
local function convertHex2String(hex)
  local readableString = ''
  if #hex > 0 then
    for i = 1, #hex do
      readableString = readableString .. [[\]]
      local charByte = string.byte(hex,i)
      if charByte < 10 then
        readableString = readableString .. '0'
      end
      readableString = readableString .. tostring(charByte)
    end
  end
  return readableString
end
funcs.convertHex2String = convertHex2String

--- Function to convert string to hex
---@param readableString string String
---@return string hex String as hex
local function convertString2Hex(readableString)
  local hex = ''
  if #readableString > 0 and string.sub(readableString,1,1) == [[\]] then
    local lastpos = 2
    while lastpos < #readableString do
      local newpos = string.find(readableString, [[\]], lastpos)
      if newpos then
        hex = hex .. string.char(tonumber(string.sub(readableString, lastpos, newpos-1)))
        lastpos = newpos + 1
      else
        hex = hex .. string.char(tonumber(string.sub(readableString, lastpos)))
        break
      end
    end
  end
  return hex
end
funcs.convertString2Hex = convertString2Hex

--- Function to check if string has valid IP
---@param ip string String with IP
---@return bool result Result
local function checkIP(ip)
  if not ip then return false end
  local a,b,c,d=ip:match("^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$")
  a=tonumber(a)
  b=tonumber(b)
  c=tonumber(c)
  d=tonumber(d)
  if not a or not b or not c or not d then return false end
  if a<0 or 255<a then return false end
  if b<0 or 255<b then return false end
  if c<0 or 255<c then return false end
  if d<0 or 255<d then return false end
  return true
end
funcs.checkIP = checkIP

--- Function to create a list with numbers
---@param size int Size of the list
---@return string list List of numbers
local function createStringListBySize(size)
  local list = "["
  if size >= 1 then
    list = list .. '"' .. tostring(1) .. '"'
  end
  if size >= 2 then
    for i=2, size do
      list = list .. ', ' .. '"' .. tostring(i) .. '"'
    end
  end
  list = list .. "]"
  return list
end
funcs.createStringListBySize = createStringListBySize


local function checkIfKeyListFormArray(keyList)
  local success, _ = pcall(
    table.sort,
    keyList,
    function(left,right)
      return tonumber(left) < tonumber(right)
    end
  )
  if not success then
    return false, keyList
  end
  local i = 0
  for _, key in ipairs(keyList) do
    if tonumber(key) and tonumber(key)-i == 1 then
      i = i + 1
    else
      return false, keyList
    end
  end
  if i ~= #keyList then
    return false, keyList
  end
  return true, keyList
end

-- Function to convert a table into a Container object
---@param data auto[] Lua Table to convert to Container
---@return Container cont Created Container
local function convertTable2Container(data)
  local cont = Container.create()
  for key, val in pairs(data) do
    local valType = nil
    local val2add = val
    if type(val) == 'table' then
      val2add = convertTable2Container(val)
      valType = 'OBJECT'
    end
    if type(val) == 'string' then valType = 'STRING' end
    cont:add(key, val2add, valType)
  end
  return cont
end
funcs.convertTable2Container = convertTable2Container

--- Function to convert a Container into a table
---@param cont Container Container to convert to Lua table
---@return auto[] data Created Lua table
local function convertContainer2Table(cont)
  local arrayInside, keyList = checkIfKeyListFormArray(cont:list())
  local tab = {}
  for _, key in ipairs(keyList) do
    local tempVal = cont:get(key, cont:getType(key))
    local keyToAdd = key
    if arrayInside then
      keyToAdd = tonumber(key)
    end
    if cont:getType(key) == 'OBJECT' then
      if Object.getType(tempVal) == 'Container' then
        tab[keyToAdd] = convertContainer2Table(tempVal)
      else
        tab[keyToAdd] = tempVal
      end
    else
      tab[keyToAdd] = tempVal
    end
  end
  return tab
end
funcs.convertContainer2Table = convertContainer2Table

--- Function to get content list out of table
---@param data string[] Table with data entries
---@return string sortedTable Sorted entries as string, internally seperated by ','
local function createContentList(data)
  local sortedTable = {}
  for key, _ in pairs(data) do
    table.insert(sortedTable, key)
  end
  table.sort(sortedTable)
  return table.concat(sortedTable, ',')
end
funcs.createContentList = createContentList

--- Function to get content list as JSON string
---@param data string[] Table with data entries
---@return string sortedTable Sorted entries as JSON string
local function createJsonList(data)
  local sortedTable = {}
  for key, _ in pairs(data) do
    table.insert(sortedTable, key)
  end
  table.sort(sortedTable)
  return funcs.json.encode(sortedTable)
end
funcs.createJsonList = createJsonList

--- Function to create a list from table
---@param content string[] Table with data entries
---@return string list String list
local function createStringListBySimpleTable(content)
  local list = "["
  if #content >= 1 then
    list = list .. '"' .. content[1] .. '"'
  end
  if #content >= 2 then
    for i=2, #content do
      list = list .. ', ' .. '"' .. content[i] .. '"'
    end
  end
  list = list .. "]"
  return list
end
funcs.createStringListBySimpleTable = createStringListBySimpleTable

--- Function to create a JSON string out of a table content
---@param list string Type of list
---@param content string[] Lua Table with entries for list
---@return string jsonstring List created of table entries
local function createSpecificJsonList(list, content)
  local commandList = {}
  if content == nil then
    if list == 'commandList' then
      commandList = {{TriggerCommand = '-', notifyEvent = '-'},}
    else
      commandList = {{EventToForward = '-'},}
    end
  else
    local size = 0
      for key, value in pairs(content) do
        if list == 'commandList' then
          table.insert(commandList, {TriggerCommand = key, notifyEvent = 'CSK_MultiTCPIPServer.' .. value})
        elseif list == 'eventToForward' then
          table.insert(commandList, {EventToForward = key})
        end
        size = size + 1
      end
      if size == 0 then
        if list == 'commandList' then
          commandList = {{TriggerCommand = '-', notifyEvent = '-'},}
        elseif list == 'eventToForward' then
          commandList = {{EventToForward = '-'},}
        end
      end
  end

  local jsonstring = funcs.json.encode(commandList)
  return jsonstring
end
funcs.createSpecificJsonList = createSpecificJsonList

return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************