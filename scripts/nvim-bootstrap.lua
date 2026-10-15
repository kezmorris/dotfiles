-- Run by install.sh inside `nvim --headless` once plugins are restored.
-- Installs every Mason tool and treesitter parser the config asks for, then
-- waits for them to finish (headless nvim would otherwise quit mid-install).
local function log(msg) io.stdout:write(msg .. "\n") end

vim.schedule(function()
  -- Treesitter parsers (compiled locally with tree-sitter-cli + a C compiler).
  local parsers = LazyVim.opts("nvim-treesitter").ensure_installed or {}
  log(("Installing %d treesitter parsers..."):format(#parsers))
  local ok, err = pcall(function()
    require("nvim-treesitter").install(parsers, { summary = true }):wait(600000)
  end)
  if not ok then log("  treesitter: " .. tostring(err)) end

  -- Mason tools.
  require("lazy").load({ plugins = { "mason.nvim" } })
  local registry = require("mason-registry")
  registry.refresh(function()
    local wanted = LazyVim.opts("mason.nvim").ensure_installed or {}
    for _, name in ipairs(wanted) do
      local found, pkg = pcall(registry.get_package, name)
      if not found then
        log("  mason: unknown package " .. name)
      elseif not pkg:is_installed() then
        log("  mason: installing " .. name)
        pkg:install()
      end
    end

    local deadline = vim.uv.now() + 900000
    local function wait()
      for _, pkg in ipairs(registry.get_all_packages()) do
        if pkg:is_installing() and vim.uv.now() < deadline then
          return vim.defer_fn(wait, 1000)
        end
      end
      local missing = {}
      for _, name in ipairs(wanted) do
        if not registry.is_installed(name) then missing[#missing + 1] = name end
      end
      if #missing > 0 then
        log("Mason: these failed to install: " .. table.concat(missing, ", "))
        log("  Open nvim and run :Mason to see why (often a missing npm, go or python3).")
        vim.cmd("cquit 1")
      else
        log(("Mason: all %d tools installed."):format(#wanted))
        vim.cmd("qa!")
      end
    end
    wait()
  end)
end)
