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

function app:dialog_root()
	self:maindialog():tasklist():clear()
	self:maindialog():buttons():clear()
	self:maindialog():text():text_set("Root dialog")
	
	self:maindialog():tasklist():task_add(self.task, nil, "Root task: ")
	
	self:maindialog():button_add("quit", "< Quit >", "cm_quit")
	-- self:maindialog():button_add("showtask", "< Show Task >", function()
	-- 	self.task:show()
	-- end)
end

function app:init()
	app.main = self
	ltui.application.init(self, "demo")
	self:background_set("blue")
	self:insert(self:maindialog())
	
	-- self.task = editor.editBoolean(true, "Enter Information:") .. {{
	-- 	type = "number",
	-- 	action = "continue",
	-- 	fn = function(value)
	-- 		if value then return editor.viewInformation(value, "The information:") end
	-- 	end
	-- }}
	-- self.task = editor.viewInformation("Hello!", "The Information:")
	
	local colourEditor = editor.editOptions("green", {"red", "green", "blue"})
	local numberEditor = editor.editNumber(41, "edit number:")
	-- local booleanEditor = editor.editBoolean(true, "edit boolean:")

	self.task = (colourEditor | numberEditor) .. {
		{
			type = "string",
			action = "continue",
			fn = function(value) return editor.viewInformation(value, "colour output:") end
		},
		{
			type = "number",
			action = "continue",
			fn = function(value) return editor.viewInformation(value, "number output:") end
		},
		{
			type = "boolean",
			action = "continue",
			fn = function(value) return editor.viewInformation(value, "boolean output:") end
		},
	}
	
	self:dialog_root()
	-- self.task:show()
end

-- on resize
function app:on_resize()
	self:maindialog():bounds_set(ltui.rect {1, 1, self:width() - 1, self:height() - 1})
	ltui.application.on_resize(self)
end

-- Called every loop iteration
function app:on_refresh()
	if self.task then
		self.task:resume()
		-- Do not do :text_set() because it will mess up the focus or something
		-- self:maindialog():tasklist():view("button.task.root")._TEXT = "Root task: "..self.task.__name
	end
	
	ltui.application.on_refresh(self)
end

-- run app
app:run()
