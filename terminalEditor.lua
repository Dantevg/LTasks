local task = require "task"

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
---@param prompt string
---@return table
function editor.editString(value, prompt)
	return editGeneric(value, tostring, prompt or "enter string:")
end

---An editor for numbers.
---@param value number the initial value
---@param prompt string
---@return table
function editor.editNumber(value, prompt)
	return editGeneric(value, tonumber, prompt or "enter number:")
end

---An editor for booleans.
---@param value boolean the initial value
---@param prompt string
---@return table
function editor.editBoolean(value, prompt)
	return editGeneric(value, function(b)
		if b == true or b == "true" then
			return true
		elseif b == false or b == "false" then
			return false
		else
			return nil
		end
	end, prompt or "enter boolean:")
end

return editor
