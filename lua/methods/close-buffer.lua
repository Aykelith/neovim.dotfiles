-- :bdelete on a buffer shown in >1 window makes nvim collapse the extra
-- window(s) instead of just swapping their buffer out. Switch every other
-- window off the target buffer first so nothing is left to collapse.
local M = {}

function M.close()
  local buf = vim.api.nvim_get_current_buf()
  local alt = vim.fn.bufnr("#")

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      if alt ~= -1 and alt ~= buf and vim.fn.buflisted(alt) == 1 then
        vim.api.nvim_win_set_buf(win, alt)
      else
        vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
      end
    end
  end

  vim.api.nvim_buf_delete(buf, {})
end

return M
