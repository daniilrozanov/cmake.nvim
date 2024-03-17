local Build = require("cmake-explorer.build")

local BuildFilter = {}

BuildFilter.__call = function(self, build)
	for k, v in pairs(self) do
		if type(k) == "string" then
			if v ~= build[k] then
				return false
			end
		end
	end
	return true
end

local BuildList = {
	__newindex = function(t, k, v)
		for _, value in ipairs(t) do
			if value == v then
				return
			end
		end
		rawset(t, k, v)
	end,
}

function BuildList:new()
	local obj = {
		current = nil,
	}
	setmetatable(obj, BuildList)
	return obj
end

function BuildList:insert(o)
	local build = Build:new(o)
	table.insert(self, build)
	self.current = build
end

function BuildList:filter(pred)
	pred = pred or {}
	local i, n = 0, #self
	if type(pred) == "table" then
		setmetatable(pred, BuildFilter)
	end
	return function()
		repeat
			i = i + 1
			if pred(self[i]) then
				return self[i]
			end
		until i ~= n
	end
end

return BuildList
