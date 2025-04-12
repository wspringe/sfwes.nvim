local M = {}

M.options = {
	sf = "",
	ns = vim.api.nvim_create_namespace("sfwes"),
	ns_name = "Sfwes",
}

function M.setup(config)
	vim.tbl_deep_extend("force", M.options, config or {})
end

function M.get(key)
	return M.options[key]
end

return M
