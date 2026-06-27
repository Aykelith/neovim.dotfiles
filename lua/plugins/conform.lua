-- Formatter dispatch + format-on-save. Lazy: save event, cmd, and keymap.
return {
  "stevearc/conform.nvim",
  commit = "619363c30309d29ffa631e67c8183f2a72caa373",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    { "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, desc = "Format Buffer" },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      go = { "gofmt" },
      rust = { "rustfmt" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
    },
    -- ponytail: format on save with LSP fallback; flip to a keymap-only flow
    -- if save latency ever bites.
    format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
  },
}
