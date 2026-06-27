-- Colorscheme. Essential at startup: must load eagerly so the theme is set
-- before the first frame (priority 1000, lazy = false).
return {
	"catppuccin/nvim",
	name = "catppuccin",
	commit = "e068ab5f8261f23f6f71ffd8791ae40315b77b9c",
	priority = 1000,
	lazy = false,
	opts = {
		flavour = "mocha",
		auto_integrations = true,
		custom_highlights = function(colors)
			return {
				SnacksPickerGitStatusUntracked = { fg = colors.green },
			}
		end,
		integrations = {
			blink_cmp = true,
			flash = true,
			gitsigns = true,
			lualine = false,
			mason = true,
			native_lsp = { enabled = true },
			snacks = true,
			telescope = true,
			treesitter = true,
			trouble = true,
			which_key = true,
		},
	},
	config = function(_, opts)
		require("catppuccin").setup(opts)
		vim.cmd.colorscheme("catppuccin")
	end,
}
