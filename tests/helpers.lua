-- E2E helpers: drive a child nvim that loads THIS config over msgpack-rpc.
-- Uses neovim's builtin jobstart(rpc) + nvim_* api — no test framework needed.
local M = {}

-- Start a headless child nvim loading the real config (-u init.lua).
function M.start_child()
  local chan = vim.fn.jobstart(
    { "nvim", "--embed", "--headless", "-n", "-u", "init.lua" },
    { rpc = true, cwd = vim.fn.getcwd() }
  )
  assert(chan > 0, "failed to start child nvim (chan=" .. tostring(chan) .. ")")
  return chan
end

function M.stop(chan)
  pcall(vim.fn.jobstop, chan)
end

-- Run lua in the child; extra args are passed as `...` inside `code`.
function M.lua(chan, code, ...)
  return vim.rpcrequest(chan, "nvim_exec_lua", code, { ... })
end

-- Feed real keystrokes (keycodes like <Esc>, <C-h> are translated).
function M.input(chan, keys)
  vim.rpcrequest(chan, "nvim_input", keys)
end

-- Poll fn() until it returns truthy or timeout (ms). Returns the value or nil.
function M.wait(fn, timeout, interval)
  timeout = timeout or 2000
  interval = interval or 50
  local waited = 0
  while waited <= timeout do
    local ok, res = pcall(fn)
    if ok and res then return res end
    vim.wait(interval)
    waited = waited + interval
  end
  return nil
end

-- Write a small cargo project to a temp dir so rust_analyzer attaches.
function M.make_rust_project()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. "/src", "p")
  local function put(path, body)
    local f = assert(io.open(dir .. "/" .. path, "w"))
    f:write(body)
    f:close()
  end
  put("Cargo.toml", '[package]\nname = "e2e"\nversion = "0.1.0"\nedition = "2021"\n')
  put("src/main.rs", 'fn main() {\n    println!("hello");\n}\n')
  return dir
end

return M
