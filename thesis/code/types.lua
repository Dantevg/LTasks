--[[--
	This module contains functions for comparing types and specificity.
]]

local typed = require "typed"

local types = {}

-- taken from https://github.com/SovietKitsune/typed/blob/master/typed.lua
local function trim(str)
	return string.match(str, '^%s*(.-)%s*$')
end

---Get the number of fields in a Typed schema
---@param schema table
---@return number
local function schemaLength(schema)
	local n = 0
	for _ in pairs(schema._fields) do n = n + 1 end
	return n
end

---Transform types for use with typed
function types.toType(type_)
	if type_ == nil then
		return "any"
	elseif type_ == "table" then
		return "table<any, any>"
	else
		return type_
	end
end

---Match `value` with the continuation types in `conts`
---@param value any the value to match
---@param conts table the list of continuations, of form `{type = ""}`
---@return table matching the list of matching continuations
function types.matchAll(value, conts)
	-- Order is important
	local matching = {}
	for _, cont in ipairs(conts) do
		local type_ = types.toType(cont.type)
		if type(type_) == "string" then
			if typed.is(type_, value) then table.insert(matching, cont) end
		else
			if type_:validate(value) then table.insert(matching, cont) end
		end
	end
	return matching
end

---Compare two types on their specificity, returns whether `a` < `b`.
---
---This relation must define a strict partial order according to the Lua docs
---(https://www.lua.org/manual/5.3/manual.html#pdf-table.sort).
---This means that it must be:
--- - Irreflexive: not `a` < `a`
--- - Asymmetric: if `a` < `b` then not `b` < `a`
--- - Transitive: if `a` < `b` and `b` < `c` then `a` < `c`
---@param a any
---@param b any
---@return boolean lt whether `a` is less specific than `b`
function types.lt(a, b)
	local aIsString, bIsString = type(a) == "string", type(b) == "string"
	local aIsSchema = type(a) == "table" and a.__name == "Schema"
	local bIsSchema = type(b) == "table" and b.__name == "Schema"
	
	-- empty struct (schema) is equal to "table"
	if bIsSchema and schemaLength(b) == 0 then
		b = "table"
		bIsString, bIsSchema = true, false
	end
	
	if a == b then
		return false -- Irreflexivity
	elseif a == "any" and b ~= "any" then
		return true -- any < T  if T != any
	elseif aIsString and a:match("|")
			and not (bIsString and b:match("|")) then
		return true -- T_1 | T_2 < t_3
	elseif aIsString and a:match("|")
			and bIsString and b:match("|") then
		-- T_1 | T_2 < T_1 | T_3  if T_2 < T_3
		local firstA, restA = string.match(a, "(.-)%s*|%s*(.+)")
		local firstB, restB = string.match(b, "(.-)%s*|%s*(.+)")
		if firstA == firstB then
			return types.lt(restA, restB) -- T_2 < T_3
		else
			-- First types (T_1) are not equal, cannot compare
			-- (assume types are ordered the same)
			return false
		end
	elseif a == "table" and bIsString and b:match("(%[%])") then
		return true -- table < table(T)
	elseif aIsString and a:match("%[%]")
			and bIsString and b:match("%[%]") then
		local listTypeA = trim(a):match("(.+)%[%]$")
		local listTypeB = trim(b):match("(.+)%[%]$")
		return types.lt(listTypeA, listTypeB)
		-- table(T_1) < table(T_2)  if T_1 < T_2
	elseif a == "table" and bIsString and b:match("table<.-,%s*.->") then
		return true -- table < table(T_1, T_2)
	elseif aIsString and a:match("table<.-,%s*.->") and bIsSchema then
		return a:match("table<(.-),%s*.->") == "string"
		-- table(string, T) < {F_1, ..., F_n}
	elseif aIsSchema and bIsSchema then
		local fields = {}
		for k, v in pairs(a._fields) do
			fields[k] = fields[k] or {}
			fields[k].a = v[1]
		end
		for k, v in pairs(b._fields) do
			fields[k] = fields[k] or {}
			fields[k].b = v[1]
		end
		
		-- {F_1, ..., F_n, k : T} < {G_1, ..., G_m, k : T}  if {F_1, ..., F_n} < {G_1, ..., G_m}
		local nonequalFields = {}
		for k, v in pairs(fields) do
			if v.a ~= v.b then nonequalFields[k] = v end
		end
		
		for k, v in pairs(nonequalFields) do
			if v.a ~= nil and v.b ~= nil then
				if not types.lt(v.a, v.b) then return false end
			elseif v.a ~= nil and v.b == nil then
				return false
			end
		end
		return true
		-- {F_1, ..., F_n, k : T_1} < {G_1, ..., G_m, k : T_2}
		-- if T_1 < T_2 and {F_1, ..., F_n} < {G_1, ..., G_m}
	else
		return false -- If none of the above rules match, a is not less specific than b
	end
end

return types
