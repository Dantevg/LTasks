local task = require "LTask.task"
local editor = require "LTask.ltuiEditor"

return (task.constant "A" & task.constant "B") ~ {{
    fn = function(x) return editor.viewInformation(x) end
}}
