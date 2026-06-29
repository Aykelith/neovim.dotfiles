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
      markdown = { "prettier" },
      mdx = { "prettier" },
    },
    formatters = {
      -- ponytail: prose-wrap is markdown-only so safe to set globally
      prettier = { prepend_args = { "--prose-wrap", "always", "--print-width", "80" } },
    },
    format_on_save = function(bufnr)
      local ft = vim.bo[bufnr].filetype
      if ft == "markdown" or ft == "mdx" then
        require("methods.markdown-prettier-warn").check(bufnr)
      end
      -- ponytail: LSP fallback; flip to keymap-only if save latency bites
      return { timeout_ms = 500, lsp_format = "fallback" }
    end,
  },
}
