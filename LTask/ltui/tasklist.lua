local ltui = require "ltui"

local log = require "ltui.base.log"
local pretty = require "pretty"

-- Inspired by menuconf.lua

local tasklist = ltui.panel()

function tasklist:init(name, bounds)
	ltui.panel.init(self, name, bounds)
end

function tasklist:on_event(e)
	if e.type == ltui.event.ev_keyboard then
		if e.key_name == "Down" then
			self:select_next()
			return true
		elseif e.key_name == "Up" then
			self:select_prev()
			return true
		elseif e.key_name == "Enter" then
			return true
		end
	elseif e.type == ltui.event.ev_command then
		if e.command == "cm_enter" then
			return true
		end
	end
end

function tasklist:nextbounds()
	if self:last() then
		return self:last():bounds()():move(0, 1)
	else
		return ltui.rect:new(0, 0, self:width(), 1)
	end
end

function tasklist:task_add(t, prefix, parent)
	local button = ltui.button:new(
		"button.task."..self._VIEWS:size() + 1,
		self:nextbounds(),
		(prefix and prefix.." " or "")..t.__name,
		function() t:show(parent) end
	)
	button:extra_set("task", t)
	self:insert(button)
end

return tasklist
