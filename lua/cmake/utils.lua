local config = require("cmake.config")
local capabilities = require("cmake.capabilities")
local scan = require("plenary.scandir")
local Path = require("plenary.path")
local uv = vim.uv or vim.loop

local utils = {}

utils.substitude = function(str, subs)
	local ret = str
	for k, v in pairs(subs) do
		ret = ret:gsub(k, v)
	end
	return ret
end

function utils.touch_file(path, txt, flag, callback)
	uv.fs_open(path, flag, 438, function(err, fd)
		assert(not err, err)
		assert(fd)
		uv.fs_close(fd, function(c_err)
			assert(not c_err, c_err)
			if type(callback) == "function" then
				callback()
			end
		end)
	end)
end

function utils.file_exists(path, callback)
	uv.fs_stat(path, function(err, _)
		local exists
		if err then
			exists = false
		else
			exists = true
		end
		if type(callback) == "function" then
			callback(exists)
		end
	end)
end

function utils.read_file(path, callback)
	uv.fs_open(path, "r", 438, function(err, fd)
		assert(not err, err)
		assert(fd, fd)
		uv.fs_fstat(fd, function(s_err, stat)
			assert(not s_err, s_err)
			assert(stat, stat)
			uv.fs_read(fd, stat.size, 0, function(r_err, data)
				assert(not r_err, r_err)
				uv.fs_close(fd, function(c_err)
					assert(not c_err, c_err)
					callback(data)
				end)
			end)
		end)
	end)
end

function utils.write_file(path, txt, callback)
	uv.fs_open(path, "w", 438, function(err, fd)
		assert(not err, err)
		assert(fd)
		uv.fs_write(fd, txt, nil, function(w_err, _)
			assert(not w_err, w_err)
			uv.fs_close(fd, function(c_err)
				assert(not c_err, c_err)
				if type(callback) == "function" then
					callback()
				end
			end)
		end)
	end)
end

--TODO: async mkdir -p

function utils.symlink(src_path, dst_path, callback)
	--TODO: replace to vim.fs.joinpath after nvim 0.10 release
	local src = Path:new(src_path, "compile_commands.json")
	if src:exists() then
		vim.cmd(
			'silent exec "!'
				.. config.cmake_path
				.. " -E create_symlink "
				.. src:normalize()
				.. " "
				.. Path:new(dst_path, "compile_commands.json"):normalize()
				.. '"'
		)
	end
end

return utils
