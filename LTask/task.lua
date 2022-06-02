--[[--
	This module contains functions for creating tasks and for composing them.
]]

local typed = require "typed"
local ltuiElements = require "LTask.ltuiElements"
local app = require "LTask.ltuiApp"

local task = {}
task.__index = task

function task.new(fn, name, value)
	local self = {}
	self.stable = false
	self.value = value
	self.__name = name or ""
	self.co = coroutine.create(fn)
	return setmetatable(self, task)
end

-- Create a task that simply holds the value given.
-- Is stable immediately.
--
-- iTasks equivalent: [`return`](https://cloogle.org/#return%20%3A%3A%20a%20-%3E%20Task%20a)  
-- `a -> Task a`
function task.constant(value)
	return task.new(function(self)
		self.value = value
		self.stable = true
	end, "constant")
end

---Transform the resulting value and stability of task `t` with function `fn`.
---
---iTasks equivalent: [`transform`](https://cloogle.org/#transform)  
---`Task a, ((a, boolean) -> (b, boolean)) -> Task b`
---@param t table `Task a`
---@param fn function `(a, boolean) -> (b, boolean)`
---@return table `Task b`
function task.transform(t, fn)
	return task.new(function(self, options)
		while not self.stable do
			t:resume(options)
			self.__name = t.__name -- Transform is transparent
			self.value, self.stable = fn(t.value, t.stable)
			self, options = coroutine.yield()
		end
	end, "transform")
end

---Transform the result of task `t` with function `fn` without changing the
---stability.
---
---iTasks equivalent: [`@`](https://cloogle.org/#@)  
---`Task a, (a -> b) -> Task b`
---@param t table `Task a`
---@param fn function `a -> b`
---@return table `Task b`
function task.transformValue(t, fn)
	return task.transform(t, function(value, stable) return fn(value), stable end)
end

local function matchTypes(value, stable, action, conts)
	-- Order is important
	local matching = {}
	for _, cont in ipairs(conts) do
		-- Transform types for use with typed
		if cont.type == nil then cont.type = "any" end
		if cont.type == "table" then cont.type = "table<any, any>" end
		
		local typeMatches
		if type(cont.type) == "string" then
			typeMatches = typed.is(cont.type, value)
		else
			typeMatches = cont.type:validate(value)
		end
		
		local actionMatches = (cont.action == nil or action == cont.action)
		
		if typeMatches and actionMatches then
			local next = cont.fn(value, stable)
			if next ~= nil then table.insert(matching, next) end
		end
	end
	return matching
end

---Sequential combinator. Performs task `t` followed by the task returned by
---the matchng combinator from `conts`. When a match is found, the step happens.
---
---Custom operator: `..`
---
---iTasks equivalent: [`step`](https://cloogle.org/#step)
---or [`>>*`](https://cloogle.org/#%3E%3E*)  
---`Task a, [ {type: any, action: string?, fn: (a -> Task b)} ] -> Task b`
---@param t table `Task a`
---@param conts table `[ {type: any, action: string?, fn: (a -> Task b)} ]`
---@return table `Task b`
function task.step(t, conts)
	return task.new(function(self, options)
		local matching = {}
		self.parent = options.parent
		while #matching == 0 do
			self.__name = "step (left, "..t.__name..")"
			if options.showUI then ltuiElements.stepDialog(self, conts, t) end
			t:resume(options, false, self)
			if t.value ~= nil then
				matching = matchTypes(t.value, t.stable, options.action, conts)
			end
			if t.stable then break end
			if #matching == 0 then self, options = coroutine.yield() end
		end
		
		if #matching == 0 then error("no matching continuation for stable task") end
		
		-- Step happens here
		local next, nextNames = nil, {}
		if #matching > 1 then
			-- Allow user to choose continuation
			for _, nextTask in ipairs(matching) do table.insert(nextNames, nextTask.__name) end
			app.main:insert(
				ltuiElements.choiceEditor(nextNames[1], nextNames,
					function(_, idx) return matching[idx] end, nil,
					function(val) next = val end),
				{centerx = true, centery = true}
			)
			while not next do self, options = coroutine.yield() end
		else
			next = matching[1]
		end
		
		options.showUI = true -- Show self to reflect stepped task
		next:show(self) -- Automatically show continuation
		
		while not self.stable do
			self.__name = "step (right, "..next.__name..")"
			if options.showUI then ltuiElements.stepDialog(self, {}, next) end
			next:resume(options, false, self)
			self.value, self.stable = next.value, next.stable
			self, options = coroutine.yield()
		end
	end, "step")
end

---Helper function for `step` combinator. Returns a continuation configuration
---that matches when the given type and action match and there is any value.
---@param type any the type that the continuation accepts
---@param action string? the action that is needed for the continuation
---@param cont function `a -> Task b`
---@return table
function task.onAction(type, action, cont)
	return {
		type = type,
		action = action,
		fn = function(value)
			if value ~= nil then return cont(value) end
		end
	}
end

---Helper function for `step` combinator. Returns a continuation configuration
---that matches when the given type matches and there is a stable value.
---
---iTasks equivalent: [`ifStable`](https://cloogle.org/#ifStable)
---@param type any the type that the continuation accepts
---@param cont function `a -> Task b`
---@return table
function task.ifStable(type, cont)
	return {
		type = type,
		fn = function(value, stable)
			if value ~= nil and stable then return cont(value) end
		end
	}
end

---Sequential combinator with a single continuation. Continues when task `t`
---has a stable value.
---
---iTasks equivalent: [`>>-`](https://cloogle.org/#%3E%3E-)
---`Task a, (a -> Task b) -> Task b`
---@param t table `Task a`
---@param type any the type that the continuation accepts
---@param cont function `a -> Task b`
---@return table `Task b`
function task.stepStable(t, type, cont)
	return task.step(t, { task.ifStable(type, cont) })
end

---Sequential combinator with a single continuation. Continues when the user
---presses "continue" (only when task `t` has a value) or when task `t` has a
---stable value.
---
---iTasks equivalent: [`>>?`](https://cloogle.org/#%3E%3E%3F)
---`Task a, (a -> Task b) -> Task b`
---@param t table `Task a`
---@param cont function `a -> Task b`
---@return table `Task b`
function task.stepButtonStable(t, type, cont)
	return task.step(t, { task.onAction("continue", type, cont), task.ifStable(type, cont) })
end

-- Returns whether all tasks in `tasks` have stable values.
local function allStable(tasks)
	for _, t in ipairs(tasks) do
		if not t.stable then return false end
	end
	return true
end

---Parallel combinator. Performs all tasks in `tasks`. The result is the list
---of results of `tasks`.
---
---iTasks equivalent: [`parallel`](https://cloogle.org/#parallel)  
---`[Task a] -> Task [{value: a, stable: boolean}]`
---@param tasks table `[Task a]`
---@return table `Task [{value: a, stable: boolean}]`
function task.parallel(tasks)
	local function getTaskNames()
		local taskNames = {}
		for _, t in ipairs(tasks) do table.insert(taskNames, t.__name) end
		return taskNames
	end
	
	return task.new(function(self, options)
		self.parent = options.parent
		self.value = {}
		while not self.stable do
			self.__name = "parallel ("..table.concat(getTaskNames(), ", ")..")"
			if options.showUI then ltuiElements.parallelDialog(self, tasks) end
			for i, t in ipairs(tasks) do
				if not t.stable then
					t:resume(options, false, self)
					self.value[i] = {value = t.value, stable = t.stable}
				end
			end
			self.stable = allStable(tasks)
			self, options = coroutine.yield()
		end
	end, "parallel")
end

-- Perform tasks in parallel and return the first stable value, or the first
-- unstable value if there are no unstable values.
--
-- iTasks equivalent: [`anyTask`](https://cloogle.org/#anyTask)  
-- `[Task a] -> Task a`
function task.anyTask(tasks)
	return task.transform(
		task.parallel(tasks),
		function(values)
			local unstableValue
			for _, v in ipairs(values) do
				if v.value ~= nil and v.stable then
					-- Stable value found, return immediately
					return v.value, true
				elseif v.value ~= nil then
					-- Set first unstable value we find
					unstableValue = v.value
				end
			end
			-- No stable value found, return first unstable value found
			return unstableValue, false
		end
	)
end

-- Perform tasks `l` and `r` in parallel, yield both values
--
-- Custom operator: `&`
--
-- iTasks equivalent: [`-&&-`](https://cloogle.org/#-%26%26-)  
-- `Task a, Task b -> Task (a, b)`
function task.parallelAnd(l, r)
	return task.transform(
		task.parallel {l, r},
		function(values)
			return {values[1].value, values[2].value},
				values[1].stable and values[2].stable
		end
	)
end

-- Perform tasks `l` and `r` in parallel, yield the first available value.
--
-- Custom operator: `|`
--
-- iTasks equivalent: [`-||-`](https://cloogle.org/#-%7C%7C-)  
-- `Task a, Task b -> Task (a | b)`
function task.parallelOr(l, r)
	return task.anyTask {l, r}
end

-- Perform tasks `l` and `r` in parallel, yield only the result of task `l`
--
-- iTasks equivalent: [`-||`](https://cloogle.org/#-%7C%7C)  
-- `Task a, Task b -> Task a`
function task.parallelLeft(l, r)
	return task.transform(
		task.parallel {l, r},
		function(values) return values[1].value, values[1].stable end
	)
end

-- Perform tasks `l` and `r` in parallel, yield only the result of task `r`
--
-- iTasks equivalent: [`||-`](https://cloogle.org/#%7C%7C-)  
---`Task a, Task b -> Task b`
function task.parallelRight(l, r)
	return task.transform(
		task.parallel {l, r},
		function(values) return values[2].value, values[2].stable end
	)
end



---Resumes the coroutine of the task with the given options
---@param options table
---@param showUI boolean? if set, sets `options.showUI` to this value
---@param parent table? if set, sets `options.parent` to this value
---@return any value
---@return boolean stability
function task:resume(options, showUI, parent)
	if self.stable then return self.value end
	if coroutine.status(self.co) == "dead" then return end
	
	options = options or {}
	if showUI ~= nil then options.showUI = showUI end
	if parent ~= nil then options.parent = parent end
	local success, err = coroutine.resume(self.co, self, options)
	
	if not success then error(err) end
	return self.value, self.stable
end

---Resumes the task with `options.showUI` enabled
---@param parent table
---@return any value
---@return boolean stability
function task:show(parent)
	return self:resume({showUI = true, parent = parent})
end

task.__band = task.parallelAnd
task.__bor = task.parallelOr
task.__bxor = task.step
task.__concat = task.step -- For backwards compatibility, `..` is right-associative

return task
