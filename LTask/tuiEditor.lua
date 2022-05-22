local task = require "LTask.task"
local ltuiElements = require "LTask.ltuiElements"
local ltui = require "ltui"
local app = require "LTask.ltuiApp"

local editor = {}

---Show `value` to the user with a prompt before.
---
---iTasks equivalent: [`viewInformation`](https://cloogle.org/#parallel)  
---`a, String? -> Task String`
---@param value string the value to display
---@param prompt string?
---@return table task the resulting editor task
function editor.viewInformation(value, prompt)
	return task.new(function(self, parent)
		self.value = tostring(value)
		local dialog = ltuiElements.stringView(value, prompt, app.main:maindialog())
		-- local button = ltui.button:new("button.2",
		-- 	ltui.rect:new(0, 2, app.main:maindialog():width(), 1),
		-- 	"show output",
		-- 	function() dialog:show(true, {focused = true}) end)
		-- local selected = app.main:current()
		app.main:insert(dialog, {centerx = true, centery = true})
		-- app.main:maindialog():box():panel():insert(button)
		-- TODO: maybe add new stringView every yield
		-- to automatically update the button
		-- app.main:maindialog():box():panel():remove(app.main:maindialog():box():panel():prev(button))
		-- app.main:select(selected)
		while true do coroutine.yield() end
	end)
end

---An editor for strings.
---@param value string the initial value
---@param prompt string?
---@return table task the resulting editor task
function editor.editString(value, prompt)
	return task.new(function(self, parent)
		local dialog = ltuiElements.stringEditor(value, prompt, app.main:maindialog(),
			function(val) self.value = val end)
		-- local button = ltui.button:new("button.3",
		-- 	ltui.rect:new(0, 1, app.main:maindialog():width(), 1),
		-- 	"show input",
		-- 	function() dialog:show(true, {focused = true}) end)
		-- local selected = parent:current()
		app.main:insert(dialog, {centerx = true, centery = true})
		-- app.main:maindialog():box():panel():insert(button)
		-- parent:select(selected)
		
		-- self.value = tostring(value)
		-- self.ui = ltuiElements.stringEditor(value, prompt, self.ui,
		-- 	function(val) self.value = val end)
		self.value = dialog:extra("config").value
		while true do coroutine.yield() end
	end)
end

---An editor for numbers.
---@param value number the initial value
---@param prompt string?
---@return table task the resulting editor task
function editor.editNumber(value, prompt)
	return task.new(function(self)
		-- self.value = tonumber(value)
		local dialog = ltuiElements.numberEditor(value, prompt, app.main:maindialog(),
			function(val) self.value = val end)
		app.main:insert(dialog, {centerx = true, centery = true})
		self.value = dialog:extra("config").value
		while true do coroutine.yield() end
	end)
end

---An editor for a pre-determined set of inputs.
---@param value any the initial value
---@param choices table the list of possible choices
---@param converter function|table? the function to use for converting the values
---@param prompt table?
---@return table element the resulting editor UI element
function editor.editOptions(value, choices, converter, prompt)
	return task.new(function(self)
		self.value = value
		local dialog = ltuiElements.choiceEditor(value, choices, converter,
			prompt, app.main:maindialog(),
			function(val) self.value = val end)
		app.main:insert(dialog, {centerx = true, centery = true})
		self.value = dialog:extra("config").value
		while true do coroutine.yield() end
	end)
end

return editor
