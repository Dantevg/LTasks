local ltui = require "ltui"

local log = require "ltui.base.log"
local pretty = require "pretty"

-- Inspired by menuconf.lua

local tasklist = ltui.panel()

function tasklist:init(name, bounds)
	ltui.panel.init(self, name, bounds)
end

function tasklist:on_event(e)
	local back = false
	if e.type == ltui.event.ev_keyboard then
		if e.key_name == "Down" then
			self:select_next()
			return true
		elseif e.key_name == "Up" then
			self:select_prev()
			return true
		elseif e.key_name == "Enter" then
			return true
		elseif e.key_name == "Esc" then
			back = true
		end
	elseif e.type == ltui.event.ev_command then
		if e.command == "cm_enter" then
			return true
		elseif e.command == "cm_back" then
			back = true
		end
	end
	
	if back then
		-- load the previous task
		local parent = self:current():extra("parent")
		log:print(pretty(parent, true))
	end
end

function tasklist:nextbounds()
	if self:last() then
		return self:last():bounds()():move(0, 1)
	else
		return ltui.rect:new(0, 0, self:width(), 1)
	end
end

function tasklist:task_add(t, parent)
	local button = ltui.button:new(
		"button.task."..self._VIEWS:size() + 1,
		self:nextbounds(),
		t.__name,
		function() t:show(parent) end
	)
	self:insert(button)
end

return tasklist
