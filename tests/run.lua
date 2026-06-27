-- Headless E2E runner. Parent is bare (-u NONE); child loads the real config.
local cwd = vim.fn.getcwd()
package.path = cwd .. "/tests/?.lua;" .. package.path

local suite = require("e2e_spec")
local passed, failed, fails = 0, 0, {}

-- pairs() order is unspecified; tests are independent so that's fine.
for name, fn in pairs(suite) do
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print("ok   - " .. name)
  else
    failed = failed + 1
    fails[#fails + 1] = name .. ": " .. tostring(err)
    print("FAIL - " .. name)
  end
end

print(string.format("\n%d passed, %d failed", passed, failed))
for _, f in ipairs(fails) do print("  " .. f) end

vim.cmd(failed == 0 and "qa!" or "cq")
