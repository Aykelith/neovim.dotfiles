#!/usr/bin/env bash
# Build the test image and run one or all scenarios.
# Usage: ./docker-test.sh [scenario]
#   scenario defaults to "all"
#   e.g.: ./docker-test.sh nvim_missing
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIO="${1:-all}"
IMAGE="nvim-ansible-test"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found. Install Docker and retry."
  exit 1
fi

echo "Building test image..."
docker build -t "$IMAGE" "$SCRIPT_DIR" --quiet

echo "Running scenario: $SCENARIO"
docker run --rm \
  -e SCENARIO="$SCENARIO" \
  "$IMAGE"
