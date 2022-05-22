local task = require "LTask.task"
local editor = require "LTask.terminalEditor"

local colourEditor = editor.editOptions(nil, {"red", "green", "blue"})
local numberEditor = editor.editNumber(nil, "edit number:")
local booleanEditor = editor.editBoolean(nil, "edit boolean:")

local output = (colourEditor | numberEditor | booleanEditor) .. {
	{
		type = "string",
		fn = function(value) return editor.viewInformation(value, "colour output:") end
	},
	{
		type = "number",
		fn = function(value) return editor.viewInformation(value, "number output:") end
	},
	{
		type = "boolean",
		fn = function(value) return editor.viewInformation(value, "boolean output:") end
	},
}

return output
