#!/bin/sh
# Godot external-editor wrapper.
# Godot Exec Path -> this script.  Exec Flags: {project} {file} {line} {col}
#
# If the project's nvim server is reachable, send it the file+cursor and focus
# the window. Otherwise open a fresh Alacritty running nvim in the project (its
# config autostarts the server).
# Godot may launch us with a minimal PATH (no login shell), so pin the bins.
export PATH="/home/alexxanderx/local-apps/nvim/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Debug log — tail /tmp/godot-open.log if something misbehaves.
exec 2>>/tmp/godot-open.log
echo "$(date '+%F %T') args: $*" >>/tmp/godot-open.log

project="$1"
file="$2"
line="$3"
col="${4:-0}"

pipe="$project/server.pipe"
# Godot's {line}/{col} are 0-based; nvim is 1-based.
lnum=$((line + 1))
cnum=$((col + 1))
send="<C-\\><C-N>:e $file<CR>:call cursor($lnum,$cnum)<CR>"

if nvim --server "$pipe" --remote-send "$send" 2>/dev/null; then
  # Delivered to a running server — bring it into focus.
  if [ -f "$pipe.tmux" ]; then
    pane=$(cat "$pipe.tmux")
    # ponytail: tmux default socket; add -L <name> if you run a named one.
    tmux switch-client -t "$pane" 2>/dev/null
    tmux select-window -t "$pane" 2>/dev/null
    tmux select-pane -t "$pane" 2>/dev/null
  fi
  # Match the window we launch below by its unique WM_CLASS (stable; nvim's
  # dynamic title can't change it). Fall back to title, then any Alacritty.
  wmctrl -x -a godot-nvim || wmctrl -a godot-nvim || wmctrl -x -a Alacritty
else
  # No server reachable. Drop any stale pipe and open a fresh terminal.
  rm -f "$pipe"
  alacritty --class godot-nvim,godot-nvim --working-directory "$project" -e nvim "+$lnum" "$file" &
fi
