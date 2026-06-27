# local-autocomplete - AGENT.md

Self-hosted **local** code-completion backend for Neovim. No cloud, no API keys,
no code leaves the machine. Ollama serves Qwen2.5-Coder natively on the host;
Neovim's `minuet-ai.nvim` talks to it over the OpenAI-compatible FIM endpoint and
renders inline ghost text. See `README.md` for full user docs.

## Architecture

- Ollama runs **natively on the host** (no Docker). Docker user-namespace
  remapping blocked the GPU's `/dev/kfd`, so ROCm never initialized in-container.
  Native Ollama runs as the `ollama` user in `render`/`video` groups for real GPU.
- Model: Qwen2.5-Coder (FIM-capable — needed for good mid-line completion).
- Bound to `127.0.0.1:11434`, local-only by default.

## Structure

- `deploy/playbook.yml` — Ansible: installs Ollama, applies tuned systemd unit,
  pulls model, installs the service **disabled** (never auto-starts on boot).
- `deploy/inventory.ini` — target hosts; defaults to localhost (`ansible_connection=local`).
- `deploy/templates/local-autocomplete.service.j2` — systemd unit, env from `ollama_env`.
- `README.md` — user-facing docs.

## Deploy

```sh
ansible-playbook -i deploy/inventory.ini deploy/playbook.yml --ask-become-pass
```

Override model: `-e ollama_model=qwen2.5-coder:1.5b`. Default is `qwen2.5-coder:3b`
(7B on CPU too slow for live type-ahead).

The playbook stops + masks the installer's default `ollama.service` and runs its
own named unit `local-autocomplete` instead, to keep the default off `:11434`.

## Service control

Service never auto-starts. Manage manually:

```sh
sudo systemctl start local-autocomplete    # start
sudo systemctl stop local-autocomplete     # stop
systemctl status local-autocomplete        # check
journalctl -u local-autocomplete -f        # logs
curl http://127.0.0.1:11434/api/tags       # liveness
```

## Conventions / gotchas

- Service installed **disabled** by design — don't add `enabled: true`.
- Tuned env in `ollama_env` (playbook vars), kept for latency: `OLLAMA_KEEP_ALIVE=-1`
  (model resident), `OLLAMA_NUM_PARALLEL=1` (single-user), `OLLAMA_FLASH_ATTENTION=1`
  + `OLLAMA_KV_CACHE_TYPE=q8_0` (q8 KV needs flash attention — set both together).
- AMD GPU: ollama user must be in `render`/`video`. Verify ROCm with
  `journalctl -u local-autocomplete | grep -iE "library=rocm|VRAM"` — want
  `library=rocm` + non-zero VRAM, not CPU fallback.
- systemd-only by design (see `ponytail:` note in playbook).

## Neovim side

Plugin config lives in the parent nvim repo at `lua/plugins/minuet.lua` (lazy.nvim,
loads on `InsertEnter`), points at `http://localhost:11434`, Qwen FIM. Override the
plugin's model without editing: `MINUET_MODEL=qwen2.5-coder:3b nvim`.

E2E test (parent repo): `./tests/run-autocomplete.sh`, gated behind `$MINUET_E2E=1`.

## Editing rules

- Change deploy behavior → keep `README.md` "Files"/"Install"/"Run" sections in sync.
- New tuning env var → add to `ollama_env` with a comment explaining why.
