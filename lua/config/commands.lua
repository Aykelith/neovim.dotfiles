-- User commands are defined with an uppercase first letter (Neovim
-- requirement); cnoreabbrev below lets them be typed lowercase.
local function copy_to_clipboard(path)
	vim.fn.setreg("+", path)
	vim.notify("Copied to clipboard: " .. path)
end

vim.api.nvim_create_user_command("Xalcrp", function()
	copy_to_clipboard(vim.fn.expand("%"))
end, { desc = "Copy current file's relative path to clipboard" })

vim.api.nvim_create_user_command("Xalcap", function()
	copy_to_clipboard(vim.fn.expand("%:p"))
end, { desc = "Copy current file's absolute path to clipboard" })

local function cmd_abbrev(lhs, rhs)
	vim.cmd(
		string.format(
			"cnoreabbrev <expr> %s (getcmdtype() ==# ':' && getcmdline() ==# '%s') ? '%s' : '%s'",
			lhs,
			lhs,
			rhs,
			lhs
		)
	)
end

cmd_abbrev("xalcrp", "Xalcrp")
cmd_abbrev("xalcap", "Xalcap")
