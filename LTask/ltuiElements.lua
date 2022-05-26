local ltui = require "ltui"
local app = require "LTask.ltuiApp"

local log = require "ltui.base.log"
local pretty = require "pretty"

local ltuiElements = {}

local function capitalise(str)
	return str:gsub("^%l", string.upper)
end

function ltuiElements.addActionButton(dialog, action, self)
	dialog:button_add(action, "< "..capitalise(action).." >", function()
		self:resume({action = action})
	end)
end

function ltuiElements.stepDialog(self, conts, current)
	local dialog = app.main:maindialog()
	dialog:tasklist():clear()
	dialog:buttons():clear()
	dialog:text():text_set("Task: "..self.__name)
	dialog:button_add("quit", "< Quit >", "cm_quit")
	dialog:button_add("back", "< Back >", function()
		-- TODO: return to parent task instead of to root
		app.main:dialog_root()
	end)
	dialog:button_add("showtask", "< Show Task >", function()
		current:show()
	end)
	
	-- Add buttons for actions
	local addedActions = {}
	for _, cont in ipairs(conts) do
		if cont.action and not addedActions[cont.action] then
			ltuiElements.addActionButton(dialog, cont.action, self)
			addedActions[cont.action] = true
		end
	end
end

function ltuiElements.parallelDialog(self, tasks)
	local dialog = app.main:maindialog()
	dialog:tasklist():clear()
	dialog:buttons():clear()
	dialog:text():text_set("Task: "..self.__name)
	dialog:button_add("quit", "< Quit >", "cm_quit")
	dialog:button_add("back", "< Back >", function()
		-- TODO: return to parent task instead of to root
		app.main:dialog_root()
	end)
	dialog:button_add("showtask", "< Show Task >", function()
		log:print(pretty(dialog:tasklist():current()))
		self:show()
	end)
	
	for _, t in ipairs(tasks) do
		dialog:tasklist():task_add(t, t, "Parallel task: ")
	end
end

local function genericDialog(dialog, text, title)
	if text then dialog:text():text_set(text) end
	if title then dialog:title():text_set(title) end
	dialog:extra_set("config", {})
	-- dialog:show(false)
	return dialog
end

---Show a string to the user.
---@param value string the value to display
---@param prompt string?
---@return table element the resulting editor UI element
function ltuiElements.stringView(value, prompt)
	return genericDialog(app.main:resultdialog(),
		(prompt and tostring(prompt).." " or "")..tostring(value), nil)
end

local function inputEditor(value, converter, prompt, callback)
	local dialog = genericDialog(app.main:inputdialog(), prompt, nil)
	dialog:textedit():text_set(converter(value) ~= nil and tostring(converter(value)) or "")
	dialog:panel():select(dialog:textedit())
	dialog:extra("config").callback = function(val, config)
		local converted = converter(val)
		config.value = converted
		callback(converted, dialog)
	end
	return dialog
end

---An editor for strings.
---@param value string the initial value
---@param prompt string?
---@param callback function the callback function
---@return table element the resulting editor UI element
function ltuiElements.stringEditor(value, prompt, callback)
	local dialog = inputEditor(value, tostring, prompt or "please input text:", callback)
	dialog:extra("config").value = value
	dialog:extra("config").type = "string"
	return dialog
end

---An editor for numbers.
---@param value number the initial value
---@param prompt string?
---@param callback function the callback function
---@return table element the resulting editor UI element
function ltuiElements.numberEditor(value, prompt, callback)
	local dialog = inputEditor(value, tonumber, prompt or "please input number:", callback)
	dialog:extra("config").value = value
	dialog:extra("config").type = "number"
	return dialog
end

local function choiceEditor(value, choices, converter, prompt, callback)
	local dialog = genericDialog(app.main:choicedialog(), prompt, nil)
	dialog:extra("config").callback = callback
	dialog:choicebox():load(choices, value)
	dialog:choicebox():action_set(ltui.action.ac_on_selected, function(_, index, choice)
		dialog:extra("config").value = converter(choice, index)
	end)
	return dialog
end

---An editor for a pre-determined set of inputs.
---@param value any the initial value
---@param choices table the list of possible choices
---@param converter function|table? the function to use for converting the values
---@param prompt string?
---@param callback function the callback function
---@return table element the resulting editor UI element
function ltuiElements.choiceEditor(value, choices, converter, prompt, callback)
	if not converter then
		converter = function(v) return v end
	elseif type(converter) == "table" then
		local converterTable = converter
		converter = function(v, i) return converterTable[i] end
	end
	
	local optionsSet = {}
	for i, option in ipairs(choices) do optionsSet[option] = i end
	
	local dialog = choiceEditor(optionsSet[value], choices,
		function(v, i) if optionsSet[v] then return converter(v, i) end end,
		prompt or ("choose from "..table.concat(choices, ", ")..":"), callback)
	dialog:extra("config").value = value
	dialog:extra("config").type = "choice"
	dialog:extra("config").values = choices
	return dialog
end

return ltuiElements
