-- If need to remember history for multiple projects:
-- https://github.com/nvim-telescope/telescope-smart-history.nvim

return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "debugloop/telescope-undo.nvim", -- provides undo tree
    "nvim-telescope/telescope-live-grep-args.nvim" -- provides grep args to filter files in searches
  },
  -- lazy = true,
  keys = {
    { '<Leader>ff', function() require('telescope.builtin').find_files() end },
    { '<Leader>fg', ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>" },
    { '<Leader>fb', function() require('telescope.builtin').buffers() end },
    { '<Leader>fh', function() require('telescope.builtin').help_tags() end },
    { '<Leader>fu', "<cmd>Telescope undo<cr>" },
  },
  config = function()
    local actions = require('telescope.actions')
    local lga_actions = require("telescope-live-grep-args.actions")

    require("telescope").setup({
      defaults = {
        mappings = {
          i = {
            ["<C-Down>"] = actions.cycle_history_next,
            ["<C-Up>"] = actions.cycle_history_prev,
            ["<C-k>"] = lga_actions.quote_prompt()
          }
        }
      }
    })
    require("telescope").load_extension("undo")
  end,
}
