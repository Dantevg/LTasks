local task = require "LTask.task"
local ltuiElements = require "LTask.ltuiElements"
local ltui = require "ltui"
local app = require "LTask.ltuiApp"

local log = require "ltui.base.log"
local pretty = require "pretty"

local editor = {}

---Show `value` to the user with a prompt before.
---
---iTasks equivalent: [`viewInformation`](https://cloogle.org/#parallel)  
---`a, String? -> Task String`
---@param value string the value to display
---@param prompt string?
---@return table task the resulting editor task
function editor.viewInformation(value, prompt)
	local function showUI()
		app.main:insert(
			ltuiElements.stringView(value, prompt),
			{centerx = true, centery = true}
		)
	end
	
	return task.new(function(self, options)
		self.value = tostring(value)
		while true do
			if options.showUI then showUI() end
			self, options = coroutine.yield()
		end
	end, "viewInformation")
end

local function genericEditor(value, showUI, name)
	return task.new(function(self, options)
		self.value = value
		-- self.value = dialog:extra("config").value
		while true do
			if options.showUI then showUI(self) end
			self, options = coroutine.yield()
		end
	end, name)
end

---An editor for strings.
---@param value string the initial value
---@param prompt string?
---@return table task the resulting editor task
function editor.editString(value, prompt)
	return genericEditor(value, function(self)
		local dialog = ltuiElements.stringEditor(self.value, prompt,
			function(val) self.value = val end)
		app.main:insert(dialog, {centerx = true, centery = true})
		return dialog
	end, "editString")
end

---An editor for numbers.
---@param value number the initial value
---@param prompt string?
---@return table task the resulting editor task
function editor.editNumber(value, prompt)
	return genericEditor(value, function(self)
		local dialog = ltuiElements.numberEditor(self.value, prompt,
			function(val) self.value = val end)
		app.main:insert(dialog, {centerx = true, centery = true})
		return dialog
	end, "editNumber")
end

---An editor for a pre-determined set of inputs.
---@param value any the initial value
---@param choices table the list of possible choices
---@param converter function|table? the function to use for converting the values
---@param prompt string?
---@return table element the resulting editor UI element
function editor.editOptions(value, choices, converter, prompt)
	return genericEditor(value, function(self)
		local dialog = ltuiElements.choiceEditor(self.value ~= nil and tostring(self.value) or "",
			choices, converter, prompt, function(val) self.value = val end)
		app.main:insert(dialog, {centerx = true, centery = true})
		return dialog
	end, "editOptions")
end

---An editor for a pre-determined set of inputs.
---@param value boolean the initial value
---@param prompt string?
---@return table element the resulting editor UI element
function editor.editBoolean(value, prompt)
	local t = editor.editOptions(value and "true" or "false",
		{"true", "false"}, {true, false}, prompt)
	t.__name = "editBoolean"
	return t
end

return editor
