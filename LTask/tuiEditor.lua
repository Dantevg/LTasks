local task = require "LTask.task"
local ltuiElements = require "LTask.ltuiElements"
local ltui = require "ltui"

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
		local dialog = ltuiElements.stringView(value, prompt, parent:dialog_main())
		local button = ltui.button:new("button.2",
			ltui.rect:new(0, 2, parent:dialog_main():width(), 1),
			"show output",
			function() dialog:show(true, {focused = true}) end)
		local selected = parent:current()
		parent:insert(dialog, {centerx = true, centery = true})
		parent:dialog_main():box():panel():insert(button)
		-- TODO: maybe add new stringView every yield
		-- to automatically update the button
		parent:dialog_main():box():panel():remove(parent:dialog_main():box():panel():prev(button))
		parent:select(selected)
		while true do coroutine.yield() end
	end)
end

---An editor for strings.
---@param value string the initial value
---@param prompt string?
---@return table task the resulting editor task
function editor.editString(value, prompt)
	return task.new(function(self, parent)
		local dialog = ltuiElements.stringEditor(value, prompt, parent:dialog_main(),
			function(val) self.value = val end)
		local button = ltui.button:new("button.3",
			ltui.rect:new(0, 1, parent:dialog_main():width(), 1),
			"show input",
			function() dialog:show(true, {focused = true}) end)
		local selected = parent:current()
		parent:insert(dialog, {centerx = true, centery = true})
		parent:dialog_main():box():panel():insert(button)
		parent:select(selected)
		
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
		self.ui = ltuiElements.numberEditor(value, prompt, self.ui,
			function(val) self.value = val end)
		self.value = self.ui:extra("config").value
		while true do coroutine.yield() end
	end)
end

return editor
