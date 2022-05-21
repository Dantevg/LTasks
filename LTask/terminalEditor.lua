local task = require "LTask.task"

local editor = {}

local function editGeneric(value, converter, prompt)
	return task.new(function(self)
		self.value = converter(value)
		while true do
			coroutine.yield()
			if prompt then io.write(prompt.." ("..tostring(self.value)..") ") end
			self.value = converter(io.read())
		end
	end)
end

---An editor for strings.
---@param value string the initial value
---@param prompt string?
---@return table task the resulting editor task
function editor.editString(value, prompt)
	return editGeneric(value, tostring, prompt or "enter string:")
end

---An editor for numbers.
---@param value number the initial value
---@param prompt string?
---@return table task the resulting editor task
function editor.editNumber(value, prompt)
	return editGeneric(value, tonumber, prompt or "enter number:")
end

---An editor for a pre-determined set of inputs.
---@param value any the initial value
---@param options table the list of possible options
---@param converter function|table? the function to use for converting the values
---@param prompt table?
---@return table task the resulting editor task
function editor.editOptions(value, options, converter, prompt)
	if not converter then
		converter = function(v) return v end
	elseif type(converter) == "table" then
		local converterTable = converter
		converter = function(v) return converterTable[v] end
	end
	
	local optionsSet = {}
	for _, option in ipairs(options) do optionsSet[option] = true end
	
	return editGeneric(value,
		function(v) if optionsSet[v] then return converter(v) end end,
		prompt or ("choose from "..table.concat(options, ", ")..":"))
end

---An editor for booleans.
---@param value boolean the initial value
---@param prompt string?
---@return table task the resulting editor task
function editor.editBoolean(value, prompt)
	return editor.editOptions(value, { "true", "false" },
		{ ["true"] = true, ["false"] = false }, prompt or "enter boolean:")
end

return editor
