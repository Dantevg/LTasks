local task = require "LTask.task"
local editor = require "LTask.ltuiEditor"
local typed = require "typed"
local app = require "LTask.ltuiApp"

local months = {"jan", "feb", "mar", "apr", "may", "jun",
    "jul", "aug", "sep", "oct", "nov", "dec"}

local validMonths = {}
for i, m in ipairs(months) do validMonths[m] = i end

local function stringToDate(str)
    local year, month, day = str:match("(%d+)-(%d+)-(%d+)")
    if not tonumber(year) or not tonumber(month) or not tonumber(day) then
        return nil
    end
    return {
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
    }
end

local dateString = editor.editString("", "date as string:")
local dateTableNumeric = editor.editTable({
    year = editor.editNumber(),
    month = editor.editNumber(),
    day = editor.editNumber(),
}, "date as numeric table:")
local dateTableNamedMonth = editor.editTable({
    year = editor.editNumber(),
    month = editor.editOptions(months[1], months, nil, "choose a month:"),
    day = editor.editNumber(),
}, "date as named-month table:")

return task.anyTask {dateString, dateTableNumeric, dateTableNamedMonth} ~ {
    {
        type = "string",
        action = "continue",
        fn = function(dateStr)
            local date = stringToDate(dateStr)
            if date then return task.constant(date) end
        end
    },
