return {
  {
    "williamboman/mason.nvim",
    commit = "44d1e90",
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    tag = "v2.5.0"
  },
  {
    "saghen/blink.cmp",
    version = '1.*',
    opts = {
      keymap = { preset = 'default' },
      appearance = {
        nerd_font_variant = 'mono'
      },
      completion = {
        documentation = { auto_show = false },
        ghost_text = { enabled = false }
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" }
    },
    opts_extend = { "sources.default" }
  },
  {
    "williamboman/mason-lspconfig.nvim",
    commit = "f2fa604",
    lazy = false,
    opts = {
      ensure_installed = {"rust_analyzer"},
    },
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
      "saghen/blink.cmp",
    },
  }
}
