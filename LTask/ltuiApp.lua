local ltui = require "ltui"

local app = ltui.application()

function app:maindialog()
	if not self._MAINDIALOG then
		local dialog_main = ltui.boxdialog:new("dialog.main",
			ltui.rect {1, 1, self:width() - 1, self:height() - 1})
		dialog_main:text():text_set("Main description")
		dialog_main:button_add("quit", "< Quit >", "cm_quit")
		self._MAINDIALOG = dialog_main
	end
	return self._MAINDIALOG
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
