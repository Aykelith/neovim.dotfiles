# local-autocomplete

A self-hosted, **local** code-completion backend for Neovim. No cloud, no API
keys, no code leaving your machine. It runs [Ollama](https://ollama.com) serving
[Qwen2.5-Coder](https://ollama.com/library/qwen2.5-coder) natively on the host,
and Neovim talks to it via the [`minuet-ai.nvim`](https://github.com/milanglacier/minuet-ai.nvim)
plugin for inline ghost-text suggestions.

```
┌─────────────┐   FIM request    ┌──────────────────────────┐
│  Neovim     │ ───────────────▶ │ Ollama (systemd service) │
│ minuet-ai   │                  │   Qwen2.5-Coder (GPU/CPU) │
│ (ghost text)│ ◀─────────────── │   127.0.0.1:11434        │
└─────────────┘   completion     └──────────────────────────┘
```

## Why this stack

- **Ollama** — easiest way to run a code model locally; official installer,
  exposes an OpenAI-compatible FIM endpoint so editors just work.
- **Qwen2.5-Coder** — strong open code model with proper fill-in-the-middle (FIM)
  support, which is what makes mid-line completion good rather than just
  end-of-line guessing.
- **minuet-ai.nvim** — pure-Lua, speaks to Ollama directly (no extra daemon like
  `llm-ls`), and renders suggestions as inline ghost text.

Runs **directly on the host** (no container). Docker's user-namespace remapping
blocked the GPU's `/dev/kfd`, so ROCm never initialized inside the container.
Native Ollama runs as the `ollama` user in the `render`/`video` groups and gets
real GPU access.

## Requirements

- A systemd Linux host
- [Ansible](https://docs.ansible.com) on the machine you run the playbook from
  (`pipx install ansible` or your package manager)
- For GPU: an AMD card with ROCm support (`/dev/kfd` + `/dev/dri` present). The
  installer pulls Ollama's bundled ROCm; CPU-only works too, just slower.

## Install

```sh
ansible-playbook -i deploy/inventory.ini deploy/playbook.yml --ask-become-pass
```

This installs Ollama, applies the tuned service config, pulls the model, and
installs the systemd service **disabled** — it does **not** start on boot.

Override the model:

```sh
ansible-playbook -i deploy/inventory.ini deploy/playbook.yml --ask-become-pass \
  -e ollama_model=qwen2.5-coder:1.5b
```

7B on CPU is too slow for live type-ahead, hence the smaller default
(`qwen2.5-coder:3b`).

## Run the service

The service never auto-starts. Bring it up when you want autocomplete, stop it
when you're done:

```sh
sudo systemctl start local-autocomplete    # start
sudo systemctl stop local-autocomplete     # stop
systemctl status local-autocomplete        # check
journalctl -u local-autocomplete -f        # watch logs
curl http://127.0.0.1:11434/api/tags       # check it's alive
```

## Uninstall

```sh
ansible-playbook -i deploy/inventory.ini deploy/uninstall.yml --ask-become-pass \
  -e confirm=yes
```

This removes both systemd units, the Ollama binary, and the `ollama` system
user — which deletes its home dir (`~/.ollama`) and every pulled model, not
just `qwen2.5-coder`. It refuses to run without `-e confirm=yes`.

### AMD GPU notes

The playbook adds the `ollama` user to the `render` and `video` groups so it can
open `/dev/kfd` + `/dev/dri`. Confirm the GPU is actually used:

```sh
journalctl -u local-autocomplete 2>&1 | grep -iE "library=rocm|VRAM|inference compute"
```

Success = `library=rocm` in the `inference compute` line with non-zero VRAM. If
you see CPU fallback, check that `/dev/kfd` exists and the `ollama` user is in
`render`/`video` (re-run the playbook, then restart the service).

## Neovim side

The plugin is configured in your nvim config at `lua/plugins/minuet.lua`
(lazy.nvim spec, loads on `InsertEnter`). It points at `http://localhost:11434`
and uses Qwen FIM. Suggestions appear as ghost text; accept with:

| Key     | Action                          |
|---------|---------------------------------|
| `<A-A>` | accept whole suggestion         |
| `<A-a>` | accept one line                 |
| `<A-z>` | accept N lines (prompts)        |
| `<A-]>` | next suggestion                 |
| `<A-[>` | previous suggestion             |
| `<A-e>` | dismiss                         |

If you serve a different model than the plugin default (`qwen2.5-coder:7b`),
point the plugin at it without editing the file:

```sh
MINUET_MODEL=qwen2.5-coder:3b nvim
```

## Files

| File                                  | Purpose                                           |
|---------------------------------------|---------------------------------------------------|
| `deploy/playbook.yml`                 | Ansible: install Ollama + systemd service (disabled) |
| `deploy/uninstall.yml`                | Ansible: full teardown — units, binary, user, and all pulled models |
| `deploy/inventory.ini`                | Target hosts (defaults to localhost)              |
| `deploy/templates/local-autocomplete.service.j2` | systemd unit with the tuned env config |
