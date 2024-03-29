local cmd = vim.api.nvim_create_user_command

cmd("CMakeSelectBehaviour", function()
	require("cmake-explorer").change_current_behaviour()
end, { desc = "Configure one of existings directories" })

cmd("CMakeSelectConfig", function()
	require("cmake-explorer").change_current_config()
end, { desc = "Configure with parameters" })

cmd("CMakeConfigure", function()
	require("cmake-explorer").configure()
end, { desc = "Configure with parameters" })

cmd("CMakeConfigureLast", function()
	require("cmake-explorer").configure_last()
end, { desc = "Configure last if exists. Otherwise default" })

cmd("CMakeBuild", function()
	require("cmake-explorer").build()
end, { desc = "Configure one of existings directories" })

cmd("CMakeBuildLast", function()
	require("cmake-explorer").build_last()
end, { desc = "Configure one of existings directories" })

cmd("CMakeConfigureProject", function()
	require("cmake-explorer").configure_project()
end, { desc = "Configure one of existings directories" })

cmd("CMakeInitProject", function()
	require("cmake-explorer").init_project()
end, { desc = "Configure one of existings directories" })
