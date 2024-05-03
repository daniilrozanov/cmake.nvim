local config = require("cmake.config")
local uv = vim.uv

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

function utils.read_file_sync(path)
	local fd = assert(vim.uv.fs_open(path, "r", 438))
	local stat = assert(vim.uv.fs_fstat(fd))
	local data = assert(vim.uv.fs_read(fd, stat.size, 0))
	assert(vim.uv.fs_close(fd))
	return data
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

function utils.symlink(src_path, dst_path, callback)
	local src = vim.fs.joinpath(src_path, "compile_commands.json")
	utils.file_exists(src, function()
		uv.spawn(config.cmake.cmake_path, {
			args = {
				"-E",
				"create_symlink",
				src,
				vim.fs.joinpath(dst_path, "compile_commands.json"),
			},
		}, function(code, signal)
			if code ~= 0 then
				vim.notify("CMake: error while creating symlink. Code " .. tostring(code), vim.log.levels.ERROR)
				return
			end
			if type(callback) == "function" then
				callback()
			end
		end)
	end)
end

return utils
