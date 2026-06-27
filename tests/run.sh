#!/usr/bin/env bash
# E2E tests. Installs plugins, then drives a child nvim with simulated keys.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Installing plugins (Lazy sync)…"
nvim --headless "+Lazy! sync" +qa 2>&1 | tail -n 5 || true

echo "==> Running E2E tests…"
nvim --headless -u NONE -c "luafile tests/run.lua"
