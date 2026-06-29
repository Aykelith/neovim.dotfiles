-- Warn once when prettier is absent for markdown/mdx formatting.
-- check_fn(bufnr)->bool and notify_fn(msg,level) are injectable for tests.
local warned = false
local M = {}

function M.check(bufnr, check_fn, notify_fn)
  if warned then return end
  check_fn = check_fn or function(b)
    return require("conform").get_formatter_info("prettier", b).available
  end
  notify_fn = notify_fn or vim.notify
  if not check_fn(bufnr) then
    warned = true
    notify_fn(
      "conform: prettier not found — install it in the project (npm i -D prettier) to format markdown/mdx",
      vim.log.levels.WARN
    )
  end
end

return M
