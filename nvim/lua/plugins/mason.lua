-- Install every language tool up front, so a fresh machine is ready without
-- having to open a file of each type first. LazyVim merges this list with
-- the tools its language extras already ask for.
return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Go
        "gopls", "gofumpt", "goimports", "golangci-lint", "delve",
        -- TypeScript / JavaScript
        "vtsls", "eslint-lsp", "prettier", "js-debug-adapter",
        -- Python
        "pyright", "ruff", "debugpy",
        -- Config and docs
        "json-lsp", "yaml-language-server", "marksman", "markdownlint-cli2", "markdown-toc",
        "dockerfile-language-server", "docker-compose-language-service", "hadolint",
        -- Lua and shell (for editing this config)
        "lua-language-server", "stylua", "shfmt",
      },
    },
  },
}
