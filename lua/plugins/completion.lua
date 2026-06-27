-- Completion engine. Lazy: loads on insert/cmdline, or when lsp.lua requires
-- it for capabilities (whichever comes first). version "*" pulls the prebuilt
-- fuzzy-matcher binary so no Rust toolchain is needed.
return {
  "saghen/blink.cmp",
  version = "v1.10.2",
  event = { "InsertEnter", "CmdlineEnter" },
  opts = {
    keymap = { preset = "default" },
    appearance = { nerd_font_variant = "mono" },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
}
