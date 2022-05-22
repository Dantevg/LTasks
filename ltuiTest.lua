local ltui = require "ltui"
local pretty = require "pretty"
local ltuiElements = require "LTask.ltuiElements"
local editor = require "LTask.tuiEditor"

local app = ltui.application()

function app:init()
	ltui.application.init(self, "demo")
	self:background_set("blue")
	
	self:insert(self:dialog_main())
	-- self:insert(self:dialog_input(), {centerx = true, centery = true})
	
	-- local button = ltui.button:new("button.1",
	-- 	ltui.rect {0, 0, self:dialog_main():width(), 1},
	-- 	"show dialog",
	-- 	function() self:dialog_input():show(true, {focused = true}) end)
	-- self:dialog_main():box():panel():insert(button)
	
	self:select(self:dialog_main())
	
	self.input = editor.editString("initial", "enter a string:")
	-- local output = function(value)
	-- 	if #value > 10 then return editor.viewInformation(value, "your input:") end
	-- end

	-- local t = input .. {{type = "string", fn = output}}
	
	self.output = self.input .. {{
		type = "string",
		fn = function(value)
			if #value > 10 then return editor.viewInformation(value, "The information:") end
		end
	}}
end

-- main dialog
function app:dialog_main()
	local dialog_main = self._DIALOG_MAIN
	if not dialog_main then
		dialog_main = ltui.boxdialog:new("dialog.main", ltui.rect {1, 1, self:width() - 1, self:height() - 1}, "main dialog")
		dialog_main:text():text_set("Main description")
		dialog_main:button_add("quit", "< Quit >", "cm_quit")
		
		self._DIALOG_MAIN = dialog_main
	end
	return dialog_main
end

-- input dialog
function app:dialog_input()
	local function callback(value, elem)
		local file = io.open("output.txt", "w")
		file:write(pretty(value, true, true), "\n")
		file:close()
	end
	
	self._DIALOG_INPUT = self._DIALOG_INPUT
		-- or ltuiElements.numberEditor(1, nil, self:dialog_main(), callback)
		or ltuiElements.choiceEditor("false", {"true", "false"},
			{true, false}, nil, self:dialog_main(), callback)
		-- or ltuiElements.stringView("Hello, World!", nil, self:dialog_main())
	return self._DIALOG_INPUT
end

-- on resize
function app:on_resize()
	self:dialog_main():bounds_set(ltui.rect {1, 1, self:width() - 1, self:height() - 1})
	self:center(self:dialog_input(), {centerx = true, centery = true})
	ltui.application.on_resize(self)
end

-- Called every loop iteration
function app:on_refresh()
	self.output:resume(self)
	-- local file = io.open("output.txt", "w")
	-- file:write(pretty(self.input.value, true, true), "\n")
	-- file:close()
	
	ltui.application.on_refresh(self)
end

-- run app
app:run()
