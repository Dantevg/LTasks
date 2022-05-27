local ltui = require "ltui"
local pretty = require "pretty"
local ltuiElements = require "LTask.ltuiElements"
local task = require "LTask.task"
local editor = require "LTask.ltuiEditor"

local log = require "ltui.base.log"
log._LOGFILE = "ltui_log.txt"

local app = require "LTask.ltuiApp"

function app:dialog_root()
	self:maindialog():tasklist():clear()
	self:maindialog():buttons():clear()
	self:maindialog():text():text_set("Root dialog")
	
	self:maindialog():tasklist():task_add(self.task)
	
	self:maindialog():button_add("quit", "< Quit >", "cm_quit")
	-- self:maindialog():button_add("showtask", "< Show Task >", function()
	-- 	self.task:show()
	-- end)
end

function app:init()
	app.main = self
	ltui.application.init(self, "demo")
	self:background_set(self.accent)
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
	local booleanEditor = editor.editBoolean(true, "edit boolean:")

	self.task = task.anyTask {colourEditor, numberEditor, booleanEditor} .. {
		{
			type = "string",
			action = "continue",
			fn = function(value) return editor.viewInformation(value, "colour output:") end
		},
		-- {
		-- 	type = "string",
		-- 	action = "continue",
		-- 	fn = function(value) return editor.viewInformation(value, "test output:") end
		-- },
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
	if self.task then self.task:resume() end
	
	ltui.application.on_refresh(self)
end

-- run app
app:run()
