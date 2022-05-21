local task = require "LTask.task"
local editor = require "LTask.terminalEditor"
local pretty = require "pretty"

local months = {"jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"}

local validMonths = {}
for _, m in ipairs(months) do validMonths[m] = true end

local function stringToDate(str)
	local year, month, day = str:match("(%d+)-(%d+)-(%d+)")
	if not tonumber(year) or not tonumber(month) or not tonumber(day) then return nil end
	return {
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
	}
end

local function toMonth(month)
	month = tostring(month)
	return validMonths[month:lower()] and month or nil
end

local function convertAll(values, converters)
	if type(values) ~= "table" then return {} end
	local converted, valid = {}, true
	for k, v in pairs(values) do
		converted[k] = converters[k](v)
		if converted[k] == nil then valid = false end
	end
	return converted, valid
end

local function editTable(value, converters, prompt)
	return task.new(function(self)
		local value, valid = convertAll(value, converters)
		if valid then self.value = value end
		while true do
			coroutine.yield()
			for k, converter in pairs(converters) do
				if prompt then io.write(prompt.." "..tostring(k).." ("..tostring(value[k])..") ") end
				value[k] = converter(io.read())
				if value[k] == nil then valid = false end
			end
			self.value = valid and value or nil
		end
	end)
end

local function editDateNumeric(value, prompt)
	return editTable(value, {year = tonumber, month = tonumber, day = tonumber}, prompt)
end
local function editDateNamedMonth(value, prompt)
	return editTable(value, {year = tonumber, month = toMonth, day = tonumber}, prompt)
end

local dateString = editor.editString(nil, "date as string:")
local dateTableNumeric = editDateNumeric(nil, "date as numeric table:")
local dateTableNamedMonth = editDateNamedMonth(nil, "date as named-month table:")

-- Probleem: dateTable* werkt niet met dateString
local datepicker = (dateString | dateTableNumeric | dateTableNamedMonth) .. {
	{
		type = "string",
		fn = function(dateStr)
			local date = stringToDate(dateStr)
			if date then return task.constant(date) end
		end
	},
	{
		type = "table",
		fn = function(date)
			print(pretty(date, true))
			if type(date.year) ~= "number" or type(date.day) ~= "number" then return end
			if type(date.month) == "string" then
				return task.constant(date)
			else
				return task.constant(date)
			end
		end
	}
}

return datepicker
