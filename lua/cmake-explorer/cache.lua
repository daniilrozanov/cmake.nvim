local Cache = {}

local os = {
	iswin32 = vim.fn.has("win32") == 1,
	ismac = vim.fn.has("mac") == 1,
	iswsl = vim.fn.has("wsl") == 1,
	islinux = vim.fn.has("linux") == 1,
}

local dir = {
	unix = vim.fn.expand("~") .. "/.cache/cmake_explorer_nvim/",
	mac = vim.fn.expand("~") .. "/.cache/cmake_explorer_nvim/",
	win = vim.fn.expand("~") .. "/AppData/Local/cmake_explorer_nvim/",
}

local function get_cache_path()
	if os.islinux then
		return dir.unix
	elseif os.ismac then
		return dir.mac
	elseif os.iswsl then
		return dir.unix
	elseif os.iswin32 then
		return dir.win
	end
end

local function get_clean_path(path)
	local current_path = path
	local clean_path = current_path:gsub("/", "")
	clean_path = clean_path:gsub("\\", "")
	clean_path = clean_path:gsub(":", "")
	return clean_path
end

function Cache.load(path)
	return
end

function Cache.save_global(tbl)
	local to_save = vim.tbl_deep_extend("keep", tbl)
	setmetatable(to_save, nil)
	local path = get_project_path()
	local file = io.open(path, "w")
end

return Cache
