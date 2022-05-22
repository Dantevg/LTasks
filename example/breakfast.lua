local task = require "LTask.task"
local editor = require "LTask.terminalEditor"

local makeTea = editor.editBoolean(false, "make tea?")
	:transform(function(x) return x and "Tea" or nil end)
local makeCoffee = editor.editBoolean(false, "make coffee?")
	:transform(function(x) return x and "Coffee" or nil end)
local makeSandwich = editor.editBoolean(false, "make sandwich?")
	:transform(function(x) return x and "A Sandwich" or nil end)
local eatBreakfast = function(drink, food)
	return editor.viewInformation("I'm eating "..food.." and drinking "..drink)
end

-- local breakfast = makeTea:parallelOr(makeCoffee)
-- 	:parallelAnd(makeSandwich)
-- 	:step {{fn = function(value)
-- 		if value[1] ~= nil and value[2] ~= nil then
-- 			return eatBreakfast(value[1], value[2])
-- 		end
-- 	end}}

local breakfast = ((makeTea | makeCoffee) & makeSandwich) .. {{fn = function(value)
	if value[1] ~= nil and value[2] ~= nil then
		return eatBreakfast(value[1], value[2])
	end
end}}

return breakfast
