local mermaid = require("methods.mermaid-live")

vim.keymap.set("n", "<leader>m", function()
  mermaid.open()
end, { buffer = true, desc = "Open mermaid block in Mermaid Live Editor" })

local group = vim.api.nvim_create_augroup("MermaidLiveHint", { clear = false })
vim.api.nvim_clear_autocmds({ group = group, buffer = 0 })
vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "InsertLeave" }, {
  group = group,
  buffer = 0,
  callback = function(ev) mermaid.refresh_hints(ev.buf) end,
})
mermaid.refresh_hints(0)
