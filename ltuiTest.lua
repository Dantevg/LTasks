local ltui = require "ltui"
local pretty = require "pretty"
local ltuiElements = require "LTask.ltuiElements"
local editor = require "LTask.tuiEditor"

local log = require "ltui.base.log"
log._LOGFILE = "ltui_log.txt"

local app = require "LTask.ltuiApp"

--[[
	TODO:
	- step and parallel make new main dialogs
	- step has one button item
	  - first it opens the left task
	  - when stepped, it opens the right task
	- parallel has two button items (or as many as there are parallel tasks)
]]

function app:init()
	app.main = self
	ltui.application.init(self, "demo")
	self:background_set("blue")
	
	self:insert(self:maindialog())
	-- self:select(self:maindialog())
	
	self.task = editor.editString("default", "Enter Information:") .. {{
		type = "string",
		fn = function(value)
			if #value > 10 then return editor.viewInformation(value, "The information:") end
		end
	}}
	-- self.task = editor.viewInformation("Hello!", "The Information:")
end

-- on resize
function app:on_resize()
	self:maindialog():bounds_set(ltui.rect {1, 1, self:width() - 1, self:height() - 1})
	ltui.application.on_resize(self)
end

-- Called every loop iteration
function app:on_refresh()
	if self.task then self.task:resume() end
	
	ltui.application.on_refresh(self)
end

-- run app
app:run()
