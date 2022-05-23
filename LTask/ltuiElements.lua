local ltui = require "ltui"
local app = require "LTask.ltuiApp"

local ltuiElements = {}

local function genericDialog(dialog, text, title)
	dialog:background_set(app.main:maindialog():frame():background())
	dialog:frame():background_set("cyan")
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
	dialog:textedit():text_set(tostring(converter(value)))
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
	dialog:extra("config").callback = function(val, config)
		local converted = converter(val)
		config.value = converted
		callback(converted, dialog)
	end
	dialog:choicebox():load(choices, value)
	dialog:choicebox():action_set(ltui.action.ac_on_selected, function (_, index, choice)
		local converted = converter(choice, index)
		dialog:extra("config").value = converted
	end)
	return dialog
end

---An editor for a pre-determined set of inputs.
---@param value any the initial value
---@param choices table the list of possible choices
---@param converter function|table? the function to use for converting the values
---@param prompt table?
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
