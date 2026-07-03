-- Fuzzy finder. Lazy: command + keys only. fzf-native compiled for speed.
return {
  "nvim-telescope/telescope.nvim",
  commit = "427b576c16792edad01a92b89721d923c19ad60f",
  cmd = "Telescope",
  dependencies = {
    { "nvim-lua/plenary.nvim", commit = "74b06c6c75e4eeb3108ec01852001636d85a932b" },
    { "nvim-telescope/telescope-fzf-native.nvim", commit = "b25b749b9db64d375d782094e2b9dce53ad53a40", build = "make" },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
  },
  opts = {
    pickers = {
      live_grep = {
        additional_args = { "--ignore-case", "--hidden" },
      },
      find_files = {
        hidden = true,
      },
    },
    extensions = { fzf = {} },
  },
  config = function(_, opts)
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
      mappings = {
        i = {
          ["<C-j>"] = actions.cycle_history_next,
          ["<C-k>"] = actions.cycle_history_prev,
        },
      },
    })
    telescope.setup(opts)
    pcall(telescope.load_extension, "fzf")
  end,
}
