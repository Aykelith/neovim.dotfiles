#!/usr/bin/env bash
# E2E tests. Installs plugins, then drives a child nvim with simulated keys.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Installing plugins (Lazy sync)…"
nvim --headless "+Lazy! sync" +qa 2>&1 | tail -n 5 || true

# nvim-treesitter's `main` branch installs parsers asynchronously (git clone +
# tree-sitter generate + cc, per language); `Lazy! sync`'s build step kicks
# this off but does not block on it, so a cold cache would otherwise leave
# the E2E suite racing an in-progress compile. Wait for it here instead of
# padding every test's own timeout.
echo "==> Waiting for treesitter parsers to finish compiling…"
nvim --headless -u init.lua -c "lua
  local want = require('config.treesitter-parsers')
  local ok = vim.wait(180000, function()
    local have = {}
    for _, p in ipairs(require('nvim-treesitter.config').get_installed('parsers')) do have[p] = true end
    for _, lang in ipairs(want) do
      if not have[lang] then return false end
    end
    return true
  end, 500)
  if not ok then
    io.stderr:write('treesitter parsers did not finish compiling within 180s\n')
    os.exit(1)
  end
" -c "qa" 2>&1 | tail -n 20

echo "==> Running E2E tests…"
nvim --headless -u NONE -c "luafile tests/run.lua"
