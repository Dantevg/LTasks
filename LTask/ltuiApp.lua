local ltui = require "ltui"

local app = ltui.application()

function app:maindialog()
	if not self._MAINDIALOG then
		local dialog_main = ltui.boxdialog:new("dialog.main",
			ltui.rect {1, 1, self:width() - 1, self:height() - 1})
		-- function dialog_main:on_event(e)
		-- 	local back = false
		-- 	if e.type == ltui.event.ev_keyboard then
		-- 		if e.key_name == "Down" then
		-- 			if self:current() == self:last() then
		-- 				self:scroll(self:height())
		-- 			else
		-- 				self:select_next()
		-- 			end
		-- 			self:_notify_scrolled()
		-- 			return true
		-- 		elseif e.key_name == "Up" then
		-- 			if self:current() == self:first() then
		-- 				self:scroll(-self:height())
		-- 			else
		-- 				self:select_prev()
		-- 			end
		-- 			self:_notify_scrolled()
		-- 			return true
		-- 		elseif e.key_name == "PageDown" or e.key_name == "PageUp" then
		-- 			local direction = e.key_name == "PageDown" and 1 or -1
		-- 			self:scroll(self:height() * direction)
		-- 			self:_notify_scrolled()
		-- 			return true
		-- 		elseif e.key_name == "Enter" or e.key_name == " " then
		-- 			self:_do_select()
		-- 			return true
		-- 		elseif e.key_name:lower() == "y" then
		-- 			self:_do_include(true)
		-- 			return true
		-- 		elseif e.key_name:lower() == "n" then
		-- 			self:_do_include(false)
		-- 			return true
		-- 		elseif e.key_name == "Esc" then
		-- 			back = true
		-- 		end
		-- 	elseif e.type == ltui.event.ev_command then
		-- 		if e.command == "cm_enter" then
		-- 			self:_do_select()
		-- 			return true
		-- 		elseif e.command == "cm_back" then
		-- 			back = true
		-- 		end
		-- 	end
		
		-- 	-- back?
		-- 	if back then
		-- 		-- load the previous menu configs
		-- 		local configs_prev = self._CONFIGS._PREV
		-- 		if configs_prev then
		-- 			self._CONFIGS._PREV = configs_prev._PREV
		-- 			self:load(configs_prev)
		-- 			return true
		-- 		end
		-- 	end
		-- end
		self._MAINDIALOG = dialog_main
	end
	return self._MAINDIALOG
end

function app:nextbounds()
	local last = self:maindialog():box():panel():last()
	return last and last:bounds()():move(0, 1) or ltui.rect:new(0, 0, self:maindialog():width(), 1)
end

-- resultdialog, inputdialog, choicedialog from:
-- https://github.com/tboox/ltui/blob/master/src/ltui/mconfdialog.lua

function app:resultdialog()
	if not self._RESULTDIALOG then
		local dialog_result = ltui.textdialog:new(
			"dialog.result",
			ltui.rect {0, 0, math.min(80, self:width() - 8), math.min(8, self:height())},
			"output dialog"
		)
		dialog_result:button_add("exit", "< Exit >", function () dialog_result:quit() end)
		dialog_result:background_set(self:maindialog():frame():background())
		dialog_result:frame():background_set("cyan")
		dialog_result:option_set("scrollable", true)
		dialog_result:title():textattr_set("black")
		self._RESULTDIALOG = dialog_result
	end
	return self._RESULTDIALOG
end

function app:inputdialog()
	if not self._INPUTDIALOG then
		local dialog_input = ltui.inputdialog:new(
			"dialog.input",
			ltui.rect {0, 0, math.min(80, self:width() - 8), math.min(8, self:height())},
			"input dialog"
		)
		dialog_input:background_set(self:maindialog():frame():background())
		dialog_input:frame():background_set("cyan")
		dialog_input:textedit():option_set("multiline", false)
		dialog_input:title():textattr_set("black")
		dialog_input:button_add("ok", "< Ok >", function()
			local config = dialog_input:extra("config")
			if config.callback then
				config.callback(dialog_input:textedit():text(), config)
			end
			dialog_input:quit()
		end)
		dialog_input:button_add("cancel", "< Cancel >", function()
			dialog_input:quit()
		end)
		dialog_input:button_select("ok")
		self._INPUTDIALOG = dialog_input
	end
	return self._INPUTDIALOG
end

function app:choicedialog()
	if not self._CHOICEDIALOG then
		local dialog_choice = ltui.choicedialog:new(
			"dialog.choice",
			ltui.rect {0, 0, math.min(80, self:width() - 8), math.min(20, self:height())},
			"input dialog"
		)
		dialog_choice:background_set(self:maindialog():frame():background())
		dialog_choice:frame():background_set("cyan")
		dialog_choice:box():frame():background_set("cyan")
		dialog_choice:title():textattr_set("black")
		dialog_choice:button("select"):action_set(ltui.action.ac_on_enter, function()
			dialog_choice:choicebox():on_event(ltui.event.command {"cm_enter"})
			local config = dialog_choice:extra("config")
			if config.callback then
				config.callback(config.value, config)
			end
			dialog_choice:quit()
		end)
		self._CHOICEDIALOG = dialog_choice
	end
	return self._CHOICEDIALOG
end

return app
