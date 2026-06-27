#!/usr/bin/env bash
# Check for Nerd Fonts and luarocks.
set -euo pipefail

ok=0

# Nerd Fonts: query fontconfig for any font with "Nerd" in the name.
if command -v fc-list >/dev/null 2>&1; then
    if fc-list 2>/dev/null | grep -qi 'nerd'; then
        echo "OK   Nerd Font installed"
    else
        echo "MISS Nerd Font not found (install from https://www.nerdfonts.com)"
        ok=1
    fi
else
    echo "MISS fc-list not available, cannot check Nerd Fonts"
    ok=1
fi

# luarocks: just needs to be on PATH.
if command -v luarocks >/dev/null 2>&1; then
    echo "OK   luarocks $(luarocks --version | head -1 | awk '{print $2}')"
else
    echo "MISS luarocks not found (install via your package manager)"
    ok=1
fi

exit $ok
