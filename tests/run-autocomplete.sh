#!/usr/bin/env bash
# Autocomplete E2E: start the Ollama server (if not already up), drive a child
# nvim through a real minuet -> Ollama FIM completion, then stop the server
# again ONLY if this script started it.
#
#   ./tests/run-autocomplete.sh
#
# The server lives in the local-autocomplete repo. Override its path if needed:
#   AUTOCOMPLETE_DIR=/path/to/local-autocomplete ./tests/run-autocomplete.sh
set -euo pipefail
cd "$(dirname "$0")/.."

NAME=local-autocomplete
PORT=11434
TAGS="http://localhost:$PORT/api/tags"
AUTOCOMPLETE_DIR="${AUTOCOMPLETE_DIR:-/home/alexxanderx/work/local-autocomplete}"
STARTED_IT=0

is_up() { docker ps --filter "name=^${NAME}$" --format '{{.Names}}' | grep -qx "$NAME"; }

cleanup() {
  if [[ "$STARTED_IT" == "1" ]]; then
    echo "==> Stopping $NAME (started by this script)…"
    docker stop "$NAME" >/dev/null 2>&1 || true
  else
    echo "==> Leaving $NAME running (was already up)."
  fi
}
trap cleanup EXIT

if is_up; then
  echo "==> $NAME already running."
else
  echo "==> $NAME not running — starting it via $AUTOCOMPLETE_DIR/start.sh…"
  [[ -x "$AUTOCOMPLETE_DIR/start.sh" ]] || { echo "start.sh not found/executable in $AUTOCOMPLETE_DIR" >&2; exit 1; }
  ( cd "$AUTOCOMPLETE_DIR" && ./start.sh )
  STARTED_IT=1
fi

# Wait until the API answers AND lists a model (first boot pulls it — slow).
echo "==> Waiting for the model to be ready on :$PORT (up to 10 min)…"
MODEL=""
for _ in $(seq 1 600); do
  MODEL=$(curl -s -m 2 "$TAGS" 2>/dev/null \
    | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4 || true)
  [[ -n "$MODEL" ]] && break
  sleep 1
done
[[ -n "$MODEL" ]] || { echo "Server never reported a ready model." >&2; exit 1; }
echo "==> Server ready, serving model: $MODEL"

# Warm the model with one FIM request. minuet's request_timeout is 3s, so a cold
# first token (model not yet resident) would make the test flake. This forces
# the load now.
echo "==> Warming the model…"
curl -s -m 120 "http://localhost:$PORT/v1/completions" \
  -H 'Content-Type: application/json' \
  -d "{\"model\":\"$MODEL\",\"prompt\":\"def f():\\n    return \",\"suffix\":\"\",\"max_tokens\":8}" \
  >/dev/null || true

# Point the plugin at whatever the container actually serves, then run just the
# autocomplete test through the existing headless runner.
echo "==> Running autocomplete E2E…"
MINUET_E2E=1 MINUET_MODEL="$MODEL" \
  nvim --headless -u NONE -c "luafile tests/run.lua"
