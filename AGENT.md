# AGENT.md - nvim config

This is the configuration of Neovim/NVIM.

## Structure

- `ftplugin` - directory containing all the file-type specific plugins;
- `lua/config` - configurations files (non-plugins related);
- `lua/methods` - custom methods;
- `lua/plugins` - directory with all the plugins; auto-loaded by Lazy;
- `scripts` - bash scripts;
- `tests` - end-to-end tests;
- `init.lua` - entry file.

## Plugins

- using `Lazy`, [folke/lazy.nvim](https://github.com/folke/lazy.nvim), as plugins manager;
- each time a plugin change update `PLUGINS.md`;
- plugins are locked at the commit or version they are set at; new versions are explicit from the user only;
- if you need to add settings or configurations to a plugin in order to fix a problem or a bug or a problem
with another plugin then add the change and why it was needed in the `Observations` section of `PLUGINS.md`;

## Keymaps

- each new shortcut/keymap must be updated in `KEYMAPS.md`;
- check for no conflicts between keymaps/shortcuts;

## LSP

- native `vim.lsp.enable`, configs from `nvim-lspconfig`, servers managed by `Mason`;
- servers: `lua_ls`, `gopls`, `ts_ls` (Mason-installed), `rust_analyzer` (from PATH);
- config in `lua/plugins/lsp.lua`.

## Tests

- end-to-end tests drive a real child nvim over msgpack-rpc (neovim builtin, no
test framework), simulating keystrokes and verifying LSP attaches;
- run them with: `./tests/run.sh`;
- this installs plugins (`Lazy! sync`) then runs the suite. To run the suite
alone (plugins already installed): `nvim --headless -u NONE -c "luafile tests/run.lua"`;
- exit code is non-zero on failure. The LSP E2E test needs `rust-analyzer` on
PATH. Add tests in `tests/e2e_spec.lua` (helpers in `tests/helpers.lua`);
- autocomplete E2E (`minuet` -> local Ollama): `./tests/run-autocomplete.sh`.
It starts the `local-autocomplete` docker server if it's down, drives a child
nvim through a real FIM completion (asserts inline ghost text appears), then
stops the container only if the script started it. The test itself is gated
behind `$MINUET_E2E=1`, so the normal suite skips it when the server is down.
Override the server repo path with `AUTOCOMPLETE_DIR=`;
- if a new plugin is added, removed or changed or if a configuration is changed you should
run all the tests again;
- you should write and adjust tests for every new plugin that is added or changed;

