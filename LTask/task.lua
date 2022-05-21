---@diagnostic disable: trailing-space
--luacheck: ignore 611

local task = {}
task.__index = task

function task.new(fn)
	local self = {}
	self.stable = false
	self.value = nil
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

-- Show `value` to the user with a prompt before.
-- Is never stable.
--
-- iTasks equivalent: [`viewInformation`](https://cloogle.org/#parallel)  
-- `a, String? -> Task String`
function task.viewInformation(value, prompt)
	return task.new(function(self)
		while true do
			self.value = value
			if prompt then io.write(prompt.." ") end
			print(value)
			coroutine.yield()
		end
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
	return task.new(function(self)
		while not self.stable do
			t:resume()
			self.value, self.stable = fn(t.value, t.stable)
			if self.stable == nil then self.stable = t.stable end
			coroutine.yield()
		end
	end)
end

local function matchTypes(value, stable, conts)
	-- volgorde is belangrijk, niet veranderen!
	for _, cont in ipairs(conts) do
		-- nil type signifies any type
		if type(value) == cont.type or cont.type == nil then
			local next = cont.fn(value, stable)
			if next ~= nil then return next end
		end
	end
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
	return task.new(function(self)
		local next
		while not next and not t.stable do
			t:resume()
			next = matchTypes(t.value, t.stable, conts)
			if not next then coroutine.yield() end
		end
		
		if not next then error("no matching continuation for stable task") end
		
		-- Step happens here
		
		while not self.stable do
			next:resume()
			self.value, self.stable = next.value, next.stable
			coroutine.yield()
		end
	end)
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
	return task.new(function(self)
		self.value = {}
		while not self.stable do
			for i, t in ipairs(tasks) do
				if not t.stable then
					t:resume()
					self.value[i] = {value = t.value, stable = t.stable}
				end
			end
			self.stable = allStable(tasks)
			coroutine.yield()
		end
	end)
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



function task:resume()
	if self.stable then return self.value end
	if coroutine.status(self.co) == "dead" then return end
	
	local success, err = coroutine.resume(self.co, self)
	
	if not success then error(err) end
	return self.value, self.stable
end

task.__band = task.parallelAnd
task.__bor = task.parallelOr
task.__shl = task.parallelLeft
task.__shr = task.parallelRight
task.__concat = task.step

return task
