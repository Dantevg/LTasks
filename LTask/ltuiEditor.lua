--[[--
	This module uses the UI elements from ltuiElements.lua and converts them
	to tasks.
]]

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
	end, "viewInformation ("..(prompt and tostring(prompt).." " or "")..tostring(value)..")", value)
end

local function genericEditor(value, showUI, name)
	return task.new(function(self, options)
		self.parent = options.parent
		self.value = value
		while true do
			self.__name = name.." ("..app.pretty(self.value)..")"
			if options.showUI or options.action then showUI(self, options) end
			self, options = coroutine.yield()
		end
	end, name.." ("..app.pretty(value)..")", value)
end

---An editor for strings.
---@param value string? the initial value
---@param prompt string?
---@return table task the resulting editor task
function editor.editString(value, prompt)
	return genericEditor(value, function(self)
		local dialog = ltuiElements.stringEditor(self.value, prompt,
			function(val)
				self.value = val
				self.__name = "editString".." ("..tostring(self.value)..")"
				if self.parent then self.parent:show() end
			end)
		app.main:insert(dialog, {centerx = true, centery = true})
		return dialog
	end, "editString")
end

---An editor for numbers.
---@param value number? the initial value
---@param prompt string?
---@return table task the resulting editor task
function editor.editNumber(value, prompt)
	return genericEditor(value, function(self)
		local dialog = ltuiElements.numberEditor(self.value, prompt,
			function(val)
				self.value = val
				self.__name = "editNumber".." ("..tostring(self.value)..")"
				if self.parent then self.parent:show() end
			end)
		app.main:insert(dialog, {centerx = true, centery = true})
		return dialog
	end, "editNumber")
end

---An editor for a pre-determined set of inputs.
---@param value any the initial value
---@param choices table the list of possible choices
---@param converter function|table? the function to use for converting the values
---@param prompt string?
---@return table task the resulting editor task
function editor.editOptions(value, choices, converter, prompt, name)
	return genericEditor(value, function(self)
		local dialog = ltuiElements.choiceEditor(self.value ~= nil and tostring(self.value) or "",
			choices, converter, prompt,
			function(val)
				self.value = val
				self.__name = (name or "editOptions").." ("..tostring(self.value)..")"
				if self.parent then self.parent:show() end
			end)
		app.main:insert(dialog, {centerx = true, centery = true})
		return dialog
	end, name or "editOptions")
end

---An editor for a pre-determined set of inputs.
---@param value boolean? the initial value
---@param prompt string?
---@return table task the resulting editor task
function editor.editBoolean(value, prompt)
	return editor.editOptions(value, {"true", "false"}, {true, false}, prompt, "editBoolean")
end

---An editor for tables.
---@param editors table? the sub-editors
---@param prompt string?
---@return table task the resulting editor task
function editor.editTable(editors, prompt)
	local value = {}
	for key, ed in pairs(editors) do
		value[key] = ed.value
	end
	return genericEditor(value, function(self, options)
		if options.action == "add array" then
			local dialog = ltuiElements.numberEditor(#editors+1, "enter an index",
				function(key) self:resume {action = "add", key = key} end)
			app.main:insert(dialog, {centerx = true, centery = true})
		elseif options.action == "add named" then
			local dialog = ltuiElements.stringEditor("", "enter a name",
				function(key) self:resume {action = "add", key = key} end)
			app.main:insert(dialog, {centerx = true, centery = true})
		elseif options.action == "add" then
			local dialog = ltuiElements.choiceEditor("string",
				{"string", "number", "boolean", "table"}, nil, "choose a type",
				function(editorType)
					editors[options.key] = editor.editInformation(nil, nil, editorType)
					self:show()
				end)
			app.main:insert(dialog, {centerx = true, centery = true})
		else
			ltuiElements.tableEditor(self, editors or {}, prompt,
				function(val) self.value = val end,
				function(name)
					editors[name] = nil
					self:show()
				end)
		end
	end, "editTable")
end

---An editor for strings, numbers, booleans or tables.
---@param value any? the initial value
---@param prompt string?
---@param editorType "string" | "number" | "boolean" | "table" the type of the editor
---@return table task the resulting editor task
function editor.editInformation(value, prompt, editorType)
	editorType = editorType or type(value)
	if editorType == "string" then
		return editor.editString(value, prompt)
	elseif editorType == "number" then
		return editor.editNumber(value, prompt)
	elseif editorType == "boolean" then
		return editor.editBoolean(value, prompt)
	elseif editorType == "table" then
		return editor.editTable(value, prompt)
	end
end

return editor
