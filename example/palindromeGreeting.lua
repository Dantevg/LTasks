local editor = require "LTask.ltuiEditor"

local function isPalindrome(txt)
	txt = txt:gsub("([%s',])", ""):lower()
	return txt:reverse() == txt
end

local function isGreeting(txt)
	return txt == "hello" or txt == "Madam, I'm Adam"
end

return editor.editString("") ~ {
	{
		action = "continue",
		fn = function(value)
			return isPalindrome(value)
				and editor.viewInformation(value, "palindrome: ")
		end
	}, {
		action = "continue",
		fn = function(value)
			return isGreeting(value)
				and editor.viewInformation(value, "greeting: ")
		end
	}
}
