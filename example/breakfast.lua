local task = require "LTask.task"
local editor = require "LTask.ltuiEditor"

local makeTea = editor.editBoolean(false, "make tea?")
	:transformValue(function(x) return x and "Tea" or nil end)
local makeCoffee = editor.editBoolean(false, "make coffee?")
	:transformValue(function(x) return x and "Coffee" or nil end)
local makeSandwich = editor.editBoolean(false, "make sandwich?")
	:transformValue(function(x) return x and "A Sandwich" or nil end)
local eatBreakfast = function(drink, food)
	return editor.viewInformation("I'm eating "..food.." and drinking "..drink)
end

-- return task.parallelOr(makeTea, makeCoffee)
-- 	:parallelAnd(makeSandwich)
-- 	:step {{fn = function(value)
-- 		if value[1] ~= nil and value[2] ~= nil then
-- 			return eatBreakfast(value[1], value[2])
-- 		end
-- 	end}}

return ((makeTea | makeCoffee) & makeSandwich) .. {{fn = function(value)
	if value[1] ~= nil and value[2] ~= nil then
		return eatBreakfast(value[1], value[2])
	end
end}}
