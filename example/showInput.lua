local task = require "LTask.task"
local editor = require "LTask.terminalEditor"

local input = editor.editString("initial", "enter a string:")
local output = function(value)
	if #value > 10 then return editor.viewInformation(value, "your input:") end
end

local t = input .. {{type = "string", fn = output}}

return t
