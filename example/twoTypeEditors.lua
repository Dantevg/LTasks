local task = require "LTask.task"
local editor = require "LTask.terminalEditor"

t1 = editor.editBoolean(true)
t2 = editor.editNumber(32)

local contNumber = {
	type = "number",
	fn = function(value)
		if value >= 42 then return editor.viewInformation(value, "number output:") end
	end
}

local contBoolean = {
	type = "boolean",
	fn = function(value)
		if value == false then return editor.viewInformation(value, "boolean output:") end
	end
}

t3 = (t1 | t2) .. {contNumber, contBoolean}
