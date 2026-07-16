local mermaid = require("methods.mermaid-live")

vim.keymap.set("n", "<leader>m", function()
  mermaid.open()
end, { buffer = true, desc = "Open mermaid block in Mermaid Live Editor" })

vim.keymap.set("n", "<leader>oi", function()
  local target = vim.fn.expand("<cfile>")
  -- ponytail: relative paths resolve against the .md file's dir; absolute paths & URLs pass through
  if not target:match("^%w+://") and not vim.startswith(target, "/") then
    target = vim.fs.normalize(vim.fn.expand("%:p:h") .. "/" .. target)
  end
  vim.ui.open(target)
end, { buffer = true, desc = "Open image/link under cursor in default app" })

local group = vim.api.nvim_create_augroup("MermaidLiveHint", { clear = false })
vim.api.nvim_clear_autocmds({ group = group, buffer = 0 })
vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "InsertLeave" }, {
  group = group,
  buffer = 0,
  callback = function(ev) mermaid.refresh_hints(ev.buf) end,
})
mermaid.refresh_hints(0)
