local ltui = require "ltui"
local tasklist = require "LTask.ltui.tasklist"

-- Inspired by mconfdialog.lua

local tasklistdialog = ltui.boxdialog()

function tasklistdialog:init(name, bounds, title)
	ltui.boxdialog.init(self, name, bounds, title)
	
	self:box():panel():insert(self:tasklist())
end

function tasklistdialog:tasklist()
	if not self._TASKLIST then
		local bounds = self:box():panel():bounds()
		self._TASKLIST = tasklist:new("tasklistdialog.tasklist",
			ltui.rect:new(0, 0, bounds:width() - 1, bounds:height()))
	end
	return self._TASKLIST
end

function tasklistdialog:on_event(e)
	if e.type == ltui.event.ev_keyboard then
		if e.key_name == "Down" or e.key_name == "Up" or e.key_name == " " or e.key_name == "Esc" then
			return self:tasklist():on_event(e)
		end
	end
	return ltui.boxdialog.on_event(self, e)
end

return tasklistdialog
