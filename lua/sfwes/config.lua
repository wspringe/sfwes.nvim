local M = {}

M.options = {
	sf = "",
	ns = vim.api.nvim_create_namespace("sfwes"),
	ns_name = "Sfwes",
	use_test_watcher = true,
}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

function M.get(key)
	return M.options[key]
end

function M.get_namespace()
	return M.options.ns
end

return M
