#!/usr/bin/env bash
# Entrypoint for Docker test scenarios.
# Each scenario sets up a specific state then runs the relevant playbook,
# checking that Ansible exits with the expected code.
set -euo pipefail

NVIM_BIN="/root/local-apps/nvim/bin/nvim"
NVIM_DIR="/root/local-apps/nvim"
NVM_DIR="${HOME}/.nvm"
PASS=0
FAIL=0

pass() { echo "  PASS: $*"; ((PASS++)) || true; }
fail() { echo "  FAIL: $*"; ((FAIL++)) || true; }

expect_success() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label (expected success)"; fi
}

expect_failure() {
  local label="$1"; shift
  if ! "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label (expected failure)"; fi
}

nvm_exec() {
  bash -c "source ${NVM_DIR}/nvm.sh && $*"
}

run_nvim_book() {
  ansible-playbook /playbooks/nvim.yml "$@" 2>&1
}

run_nvm_book() {
  ansible-playbook /playbooks/nvm.yml "$@" 2>&1
}

run_firacode_book() {
  ansible-playbook /playbooks/firacode.yml "$@" 2>&1
}

install_fake_nvim() {
  local version="${1:-v0.9.0}"
  mkdir -p "$NVIM_DIR/bin"
  cat > "$NVIM_BIN" <<EOF
#!/usr/bin/env bash
echo "NVIM ${version}"
echo "Build type: Release"
EOF
  chmod +x "$NVIM_BIN"
}

install_real_nvim() {
  local tag
  tag=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
        | grep '"tag_name"' | head -1 | cut -d'"' -f4)
  curl -sL "https://github.com/neovim/neovim/releases/download/${tag}/nvim-linux-x86_64.tar.gz" \
       -o /tmp/nvim.tar.gz
  rm -rf "$NVIM_DIR"
  mkdir -p "$NVIM_DIR"
  tar -xzf /tmp/nvim.tar.gz -C "$NVIM_DIR" --strip-components=1
}

# ── Scenarios ────────────────────────────────────────────────────────────────

scenario_packages() {
  echo "=== scenario: packages ==="
  expect_success "packages playbook runs clean" \
    ansible-playbook /playbooks/packages.yml
  for pkg in git curl wget tar unzip; do
    expect_success "$pkg is installed" command -v "$pkg"
  done
  expect_success "build-essential (gcc) is installed" command -v gcc
}

# ── NVM scenarios ─────────────────────────────────────────────────────────────

scenario_nvm_missing() {
  echo "=== scenario: nvm_missing ==="
  rm -rf "$NVM_DIR"
  if run_nvm_book; then
    if [[ -f "$NVM_DIR/nvm.sh" ]]; then
      pass "NVM installed from scratch"
    else
      fail "nvm.sh not found after install"
    fi
    if nvm_exec "node --version" | grep -qE "^v24\."; then
      pass "Node 24 installed and active"
    else
      fail "Node 24 not active after install"
    fi
    local default_alias
    default_alias=$(nvm_exec "nvm alias default 2>/dev/null" || echo "")
    if echo "$default_alias" | grep -qE "v24\."; then
      pass "Node 24 set as default"
    else
      fail "Node 24 not set as default: $default_alias"
    fi
  else
    fail "nvm playbook failed on fresh install"
  fi
}

scenario_nvm_already_installed() {
  echo "=== scenario: nvm_already_installed ==="
  # Pre-install NVM so the install step is skipped
  run_nvm_book >/dev/null 2>&1 || true
  local output
  output=$(run_nvm_book)
  # Playbook must succeed and NVM must still work
  if nvm_exec "node --version" | grep -qE "^v24\."; then
    pass "Node 24 still active when NVM already present"
  else
    fail "Node 24 not active after idempotent run"
  fi
  local default_alias
  default_alias=$(nvm_exec "nvm alias default 2>/dev/null" || echo "")
  if echo "$default_alias" | grep -qE "v24\."; then
    pass "default alias still Node 24"
  else
    fail "default alias changed: $default_alias"
  fi
}

scenario_nvm_node_missing() {
  echo "=== scenario: nvm_node_missing ==="
  # NVM present but Node 24 not installed
  run_nvm_book >/dev/null 2>&1 || true
  nvm_exec "nvm uninstall 24 2>/dev/null" || true
  if run_nvm_book; then
    if nvm_exec "node --version" | grep -qE "^v24\."; then
      pass "Node 24 installed when it was missing"
    else
      fail "Node 24 still not active"
    fi
  else
    fail "nvm playbook failed when Node 24 was missing"
  fi
}

scenario_nvm_wrong_default() {
  echo "=== scenario: nvm_wrong_default ==="
  # NVM + Node 24 present, but default alias points to something else
  run_nvm_book >/dev/null 2>&1 || true
  nvm_exec "nvm install 20 && nvm alias default 20" >/dev/null 2>&1 || true
  if run_nvm_book; then
    local default_alias
    default_alias=$(nvm_exec "nvm alias default 2>/dev/null" || echo "")
    if echo "$default_alias" | grep -qE "v24\."; then
      pass "default alias corrected to Node 24"
    else
      fail "default alias still wrong: $default_alias"
    fi
  else
    fail "nvm playbook failed when fixing default alias"
  fi
}

# ── Nvim scenarios ────────────────────────────────────────────────────────────

scenario_nvim_missing() {
  echo "=== scenario: nvim_missing ==="
  rm -f "$NVIM_BIN"
  expect_failure "playbook fails when nvim missing" run_nvim_book
}

scenario_nvim_wrong_path() {
  echo "=== scenario: nvim_wrong_path ==="
  mkdir -p /usr/local/bin
  cp /bin/true /usr/local/bin/nvim
  expect_failure "playbook fails when nvim at wrong path" run_nvim_book
  rm -f /usr/local/bin/nvim
}

scenario_nvim_no_path_entry() {
  echo "=== scenario: nvim_no_path_entry ==="
  export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "local-apps/nvim/bin" | tr '\n' ':' | sed 's/:$//')
  expect_failure "playbook fails when PATH entry missing" run_nvim_book
}

scenario_nvim_outdated() {
  echo "=== scenario: nvim_outdated ==="
  install_fake_nvim "v0.1.0"
  if run_nvim_book; then
    local installed
    installed=$("$NVIM_BIN" --version | grep '^NVIM' | awk '{print $2}')
    local latest
    latest=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
             | grep '"tag_name"' | head -1 | cut -d'"' -f4)
    if [[ "$installed" == "$latest" ]]; then
      pass "nvim upgraded to $latest"
    else
      fail "nvim version mismatch after upgrade: got $installed want $latest"
    fi
  else
    fail "playbook failed during upgrade"
  fi
}

scenario_nvim_current() {
  echo "=== scenario: nvim_current ==="
  install_real_nvim
  local output
  output=$(run_nvim_book)
  if echo "$output" | grep -q "already the latest"; then
    pass "playbook reports up to date"
  else
    fail "expected 'already the latest' message"
  fi
}

# ── FiraCode scenarios ────────────────────────────────────────────────────────

scenario_firacode_missing() {
  echo "=== scenario: firacode_missing ==="
  if run_firacode_book; then
    if fc-list | grep -q "FiraCodeNerdFont"; then
      pass "FiraCode installed from scratch"
    else
      fail "FiraCode not found after playbook"
    fi
  else
    fail "firacode playbook failed"
  fi
}

scenario_firacode_exists() {
  echo "=== scenario: firacode_exists ==="
  run_firacode_book >/dev/null 2>&1 || true
  local output
  output=$(run_firacode_book)
  if echo "$output" | grep -q "already installed"; then
    pass "playbook skips when FiraCode present"
  else
    fail "expected skip message"
  fi
}

scenario_firacode_reinstall() {
  echo "=== scenario: firacode_reinstall ==="
  run_firacode_book >/dev/null 2>&1 || true
  if run_firacode_book -e reinstall=true; then
    if fc-list | grep -q "FiraCodeNerdFont"; then
      pass "FiraCode reinstalled"
    else
      fail "FiraCode not found after reinstall"
    fi
  else
    fail "firacode reinstall playbook failed"
  fi
}

# ── Dispatch ─────────────────────────────────────────────────────────────────

echo ""
echo "Running scenario: $SCENARIO"
echo "────────────────────────────────────────"

case "$SCENARIO" in
  packages)               scenario_packages ;;
  nvm_missing)            scenario_nvm_missing ;;
  nvm_already_installed)  scenario_nvm_already_installed ;;
  nvm_node_missing)       scenario_nvm_node_missing ;;
  nvm_wrong_default)      scenario_nvm_wrong_default ;;
  nvim_missing)           scenario_nvim_missing ;;
  nvim_wrong_path)        scenario_nvim_wrong_path ;;
  nvim_no_path_entry)     scenario_nvim_no_path_entry ;;
  nvim_outdated)          scenario_nvim_outdated ;;
  nvim_current)           scenario_nvim_current ;;
  firacode_missing)       scenario_firacode_missing ;;
  firacode_exists)        scenario_firacode_exists ;;
  firacode_reinstall)     scenario_firacode_reinstall ;;
  all)
    scenario_packages
    scenario_nvm_missing
    scenario_nvm_already_installed
    scenario_nvm_node_missing
    scenario_nvm_wrong_default
    scenario_nvim_missing
    scenario_nvim_wrong_path
    scenario_nvim_no_path_entry
    scenario_nvim_outdated
    scenario_nvim_current
    scenario_firacode_missing
    scenario_firacode_exists
    scenario_firacode_reinstall
    ;;
  *)
    echo "Unknown scenario: $SCENARIO"
    echo "Valid: packages nvm_missing nvm_already_installed nvm_node_missing nvm_wrong_default"
    echo "       nvim_missing nvim_wrong_path nvim_no_path_entry nvim_outdated nvim_current"
    echo "       firacode_missing firacode_exists firacode_reinstall all"
    exit 1
    ;;
esac

echo ""
echo "────────────────────────────────────────"
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ $FAIL -eq 0 ]]
