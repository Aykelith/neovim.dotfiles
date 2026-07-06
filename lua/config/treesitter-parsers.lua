-- Shared with tests/run.sh, which waits for all of these to finish
-- compiling before the E2E suite starts (nvim-treesitter installs parsers
-- asynchronously, so a cold clone must not be assumed to be ready yet).
return {
  "bash", "css", "diff", "dtd", "go", "gomod", "gosum", "gowork", "html",
  "javascript", "jsdoc", "json", "json5", "luadoc", "luap", "php",
  "php_only", "printf", "python", "regex", "ron", "rust", "scss", "sql",
  "toml", "tsx", "typescript", "xml", "yaml",
}
