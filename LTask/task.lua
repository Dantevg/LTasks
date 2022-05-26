local ltui = require "ltui"
local ltuiElements = require "LTask.ltuiElements"
local app = require "LTask.ltuiApp"
local log = require "ltui.base.log"
local pretty = require "pretty"

local task = {}
task.__index = task

function task.new(fn, name)
	local self = {}
	self.stable = false
	self.value = nil
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
	end)
end

---Transform the result of task `t` with function `fn`.
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
			self.__name = "transform ("..t.__name..")"
			self.value, self.stable = fn(t.value, t.stable)
			if self.stable == nil then self.stable = t.stable end
			self, options = coroutine.yield()
		end
	end, "transform")
end

local function matchTypes(value, stable, action, conts)
	-- Order is important
	local matching = {}
	for _, cont in ipairs(conts) do
		-- nil type signifies any type for now
		if (type(value) == cont.type or cont.type == nil)
				and (action == cont.action or cont.action == nil) then
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
---`Task a, [ {type: string, fn: (a -> Task b)} ] -> Task b`
---@param t table `Task a`
---@param conts table `[ {type: string, fn: (a -> Task b)} ]`
---@return table `Task b`
function task.step(t, conts)
	return task.new(function(self, options)
		local matching = {}
		while #matching == 0 and not t.stable do
			self.__name = "step (left, "..t.__name..")"
			if options.showUI then ltuiElements.stepDialog(self, conts, t) end
			options.showUI = false
			t:resume(options)
			matching = matchTypes(t.value, t.stable, options.action, conts)
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
		
		options.showUI = true -- Always show UI the first time after step
		next:resume({showUI = true}) -- Automatically show continuation
		
		while not self.stable do
			self.__name = "step (right, "..next.__name..")"
			if options.showUI then ltuiElements.stepDialog(self, {}, next) end
			options.showUI = false
			next:resume(options)
			self.value, self.stable = next.value, next.stable
			self, options = coroutine.yield()
		end
	end, "step")
end

---Sequential combinator with a single continuation. Continues when task `t`
---has a stable value.
---
---iTasks equivalent: [`>>-`](https://cloogle.org/#%3E%3E-)
---`Task a, (a -> Task b) -> Task b`
---@param t table `Task a`
---@param cont function `a -> Task b`
---@return table `Task b`
function task.stepStable(t, cont)
	return task.step(t, {{
		type = nil,
		fn = function(value, stable)
			if stable then return cont(value, stable) end
		end
	}})
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
		self.value = {}
		while not self.stable do
			self.__name = "parallel ("..table.concat(getTaskNames(), ", ")..")"
			if options.showUI then ltuiElements.parallelDialog(self, tasks) end
			options.showUI = false
			for i, t in ipairs(tasks) do
				if not t.stable then
					t:resume(options)
					self.value[i] = {value = t.value, stable = t.stable}
				end
			end
			self.stable = allStable(tasks)
			self, options = coroutine.yield()
		end
	end, "parallel")
end

-- Perform tasks in parallel and return the first available value.
--
-- iTasks equivalent: [`anyTask`](https://cloogle.org/#anyTask)  
-- `[Task a] -> Task a`
function task.anyTask(tasks)
	-- TODO: prioriteit aan stable values
	return task.transform(
		task.parallel(tasks),
		function(values)
			for _, v in ipairs(values) do
				if v.value ~= nil then return v.value, v.stable end
			end
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
			return {values[1].value, values[2].value}
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
-- Custom operator: `<<`
--
-- iTasks equivalent: [`-||`](https://cloogle.org/#-%7C%7C)  
-- `Task a, Task b -> Task a`
function task.parallelLeft(l, r)
	return task.transform(
		task.parallel {l, r},
		function(values) return values[1].value end
	)
end

-- Perform tasks `l` and `r` in parallel, yield only the result of task `r`
--
-- Custom operator: `>>`
--
-- iTasks equivalent: [`||-`](https://cloogle.org/#%7C%7C-)  
---`Task a, Task b -> Task b`
function task.parallelRight(l, r)
	return task.transform(
		task.parallel {l, r},
		function(values) return values[2].value end
	)
end



function task:resume(options)
	if self.stable then return self.value end
	if coroutine.status(self.co) == "dead" then return end
	
	local success, err = coroutine.resume(self.co, self, options or {})
	
	if not success then error(err) end
	return self.value, self.stable
end

function task:show()
	self:resume({showUI = true})
end

task.__band = task.parallelAnd
task.__bor = task.parallelOr
task.__shl = task.parallelLeft
task.__shr = task.parallelRight
task.__concat = task.step

return task
