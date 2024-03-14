local utils = {
	plugin_prefix = "CM",
}

function utils.with_prefix(command)
	return utils.plugin_prefix .. command
end

function utils.has_value(tab, val)
	for index, value in ipairs(tab) do
		if type(val) == "function" then
			if val(value) then
				return true
			end
		else
			if value == val then
				return true
			end
		end
	end

	return false
end

return utils
