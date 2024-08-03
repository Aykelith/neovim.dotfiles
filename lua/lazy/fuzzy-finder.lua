return {
  "nvim-telescope/telescope.nvim",
  tag = '0.1.8',
  dependencies = {
    "nvim-lua/plenary.nvim",
    "debugloop/telescope-undo.nvim" -- provides undo tree
  },
  -- lazy = true,
  keys = {
    { '<Leader>ff', function() require('telescope.builtin').find_files() end },
    { '<Leader>fg', function() require('telescope.builtin').live_grep() end },
    { '<Leader>fb', function() require('telescope.builtin').buffers() end },
    { '<Leader>fh', function() require('telescope.builtin').help_tags() end },
    { '<Leader>fu', "<cmd>Telescope undo<cr>" },
  },
  config = function()
    require("telescope").load_extension("undo")
  end,
}
