#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOKS_DIR="$SCRIPT_DIR/init"

# ── Ansible check ────────────────────────────────────────────────────────────
if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "ERROR: ansible-playbook not found."
  echo ""
  echo "Install Ansible with:"
  echo "  pip install --user ansible"
  echo "  # or"
  echo "  sudo apt install ansible          # Debian/Ubuntu"
  echo "  sudo dnf install ansible          # Fedora/RHEL"
  echo "  brew install ansible              # macOS"
  exit 1
fi

# ── Sudo password (collected once, passed to all playbooks) ──────────────────
if [[ $EUID -ne 0 ]]; then
  read -rsp "sudo password (for package installs): " _sudo_pass
  echo ""
  export ANSIBLE_BECOME_PASS="$_sudo_pass"
  unset _sudo_pass
fi

# ── Extra vars pass-through (e.g. -e reinstall=true) ─────────────────────────
EXTRA_ARGS=("$@")

run_playbook() {
  local book="$1"
  echo ""
  echo "══════════════════════════════════════════"
  echo "  Running: $(basename "$book")"
  echo "══════════════════════════════════════════"
  ansible-playbook "$book" "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"
}

run_playbook "$PLAYBOOKS_DIR/packages.yml"
run_playbook "$PLAYBOOKS_DIR/nvm.yml"
run_playbook "$PLAYBOOKS_DIR/nvim.yml"
run_playbook "$PLAYBOOKS_DIR/firacode.yml"

echo ""
echo "All playbooks completed."
