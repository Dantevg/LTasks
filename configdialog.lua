--!A cross-platform terminal ui library based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        mconfdialog.lua
--

local ltui        = require("ltui")
local label       = ltui.label
local button      = ltui.button
local application = ltui.application
local event       = ltui.event
local rect        = ltui.rect
local action      = ltui.action
local menuconf    = ltui.menuconf
local mconfdialog = ltui.mconfdialog

local pretty = require "pretty"

-- the demo application
local app = application()

-- init demo
function app:init()
	-- init name
	application.init(self, "demo")

	-- init background
	self:background_set("blue")

	-- init configs
	local configs_sub = {}
	table.insert(configs_sub, menuconf.boolean {description = "boolean config itm"})
	table.insert(configs_sub, menuconf.boolean {description = "boolean config"})
	
	local configs = {}
	table.insert(configs, menuconf.boolean {description = "boolean config item"})
	table.insert(configs, menuconf.boolean {default = true, new = false, description = {
		"boolean config item2",
		"  - more description info",
		"  - more description info",
		"  - more description info"}})
	table.insert(configs, menuconf.number {value = 6, default = 10, description = "number config item"})
	table.insert(configs, menuconf.string {value = "x86_64", description = "string config item"})
	table.insert(configs, menuconf.menu {description = "task 1", configs = configs_sub})
	table.insert(configs, menuconf.choice {value = 3, values = {1, 2, 3, 4, 5, 6, 7, 8, 10, 12}, default = 2, description = "choice config item"})

	-- init menu config dialog
	self:dialog_mconf():load(configs)
	self:insert(self:dialog_mconf())
end

local function getConfigValues(configs)
	local values = {}
	for _, elem in ipairs(configs) do
		values[elem:prompt()] = elem.configs and getConfigValues(elem.configs) or elem.value
	end
	return values
end

-- get mconfdialog
function app:dialog_mconf()
	local dialog_mconf = self._DIALOG_MCONF
	if not dialog_mconf then
		dialog_mconf = mconfdialog:new("mconfdialog.main", rect{1, 1, self:width() - 1, self:height() - 1}, "menu config")
		dialog_mconf:action_set(action.ac_on_exit, function (v) self:quit() end)
		dialog_mconf:action_set(action.ac_on_save, function (v)
			-- TODO save configs
			local file = io.open("output.txt", "w")
			file:write(pretty.table(getConfigValues(dialog_mconf:menuconf()._CONFIGS), true, true), "\n")
			file:close()
			dialog_mconf:quit()
		end)
		self._DIALOG_MCONF = dialog_mconf
	end
	return dialog_mconf
end

-- on resize
function app:on_resize()
	self:dialog_mconf():bounds_set(rect{1, 1, self:width() - 1, self:height() - 1})
	application.on_resize(self)
end

-- run demo
app:run()
