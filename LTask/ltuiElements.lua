local ltui = require "ltui"

local ltuiElements = {}

local function genericDialog(dialog, prompt, parent)
	dialog:background_set(parent:frame():background())
	dialog:frame():background_set("cyan")
	if prompt then dialog:text():text_set(prompt) end
	dialog:extra_set("config", {})
	dialog:show(false)
	return dialog
end

local function inputEditor(value, converter, prompt, parent, callback)
	local dialog = genericDialog(
		ltui.inputdialog:new("dialog.input",
			ltui.rect {0, 0, math.min(80, parent:width() - 8), math.min(8, parent:height())}),
		prompt, parent
	)
	dialog:textedit():text_set(tostring(converter(value)))
	dialog:button_add("no", "< No >", function() dialog:show(false) end)
	dialog:button_add("yes", "< Yes >", function()
		local converted = converter(dialog:textedit():text())
		dialog:extra("config").value = converted
		dialog:textedit():text_set(converted ~= nil and tostring(converted) or "")
		callback(converted, dialog)
		dialog:show(false)
	end)
	return dialog
end

---An editor for strings.
---@param value string the initial value
---@param prompt string?
---@param parent table the parent UI element
---@param callback function the callback function
---@return table element the resulting editor UI element
function ltuiElements.stringEditor(value, prompt, parent, callback)
	local dialog = inputEditor(value, tostring, prompt or "please input text:",
		parent, callback)
	dialog:extra("config").value = value
	dialog:extra("config").type = "string"
	return dialog
end

---An editor for numbers.
---@param value number the initial value
---@param prompt string?
---@param parent table the parent UI element
---@param callback function the callback function
---@return table element the resulting editor UI element
function ltuiElements.numberEditor(value, prompt, parent, callback)
	local dialog = inputEditor(value, tonumber, prompt or "please input number:",
		parent, callback)
	dialog:extra("config").value = value
	dialog:extra("config").type = "number"
	return dialog
end

local function choiceEditor(value, choices, converter, prompt, parent, callback)
	local dialog = genericDialog(
		ltui.choicedialog:new("dialog.input",
			ltui.rect {0, 0, math.min(80, parent:width() - 8), math.min(20, parent:height())}),
		prompt, parent
	)
	dialog:choicebox():load(choices, value)
	dialog:choicebox():action_set(ltui.action.ac_on_selected, function (_, index, choice)
		local converted = converter(choice, index)
		dialog:extra("config").value = converted
	end)
	dialog:button("select"):action_set(ltui.action.ac_on_enter, function()
		dialog:choicebox():on_event(ltui.event.command {"cm_enter"})
		callback(dialog:extra("config").value, dialog)
		dialog:show(false)
	end)
	dialog:button("cancel"):action_set(ltui.action.ac_on_enter, function()
		dialog:show(false)
	end)
	return dialog
end

---An editor for a pre-determined set of inputs.
---@param value any the initial value
---@param choices table the list of possible choices
---@param converter function|table? the function to use for converting the values
---@param prompt table?
---@param parent table the parent UI element
---@param callback function the callback function
---@return table element the resulting editor UI element
function ltuiElements.choiceEditor(value, choices, converter, prompt, parent, callback)
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
		prompt or ("choose from "..table.concat(choices, ", ")..":"),
		parent, callback)
	dialog:extra("config").value = value
	dialog:extra("config").type = "choice"
	dialog:extra("config").values = choices
	return dialog
end

return ltuiElements
