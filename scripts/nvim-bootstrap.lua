-- Run by install.sh inside `nvim --headless` once plugins are restored.
-- Installs every Mason tool and treesitter parser the config asks for, then
-- waits for them to finish (headless nvim would otherwise quit mid-install).
local function log(msg) io.stdout:write(msg .. "\n") end

-- Never hang: give up after 15 minutes whatever happens.
vim.defer_fn(function()
  log("Timed out after 15 minutes. Open nvim and run :Mason to see what's left.")
  vim.cmd("cquit 1")
end, 15 * 60 * 1000)

vim.schedule(function()
  -- Treesitter parsers. LazyVim starts compiling these itself at startup, so
  -- just wait for it (installing them here as well makes the two collide).
  local parsers = LazyVim.opts("nvim-treesitter").ensure_installed or {}
  log(("Waiting for %d treesitter parsers..."):format(#parsers))
  local function missing()
    local have, out = {}, {}
    for _, lang in ipairs(require("nvim-treesitter").get_installed()) do have[lang] = true end
    for _, lang in ipairs(parsers) do
      if not have[lang] then out[#out + 1] = lang end
    end
    return out
  end
  -- If nothing has progressed for 30s, install whatever is still missing ourselves.
  local last, stalled, retried = -1, 0, false
  local done = vim.wait(10 * 60 * 1000, function()
    local m = missing()
    if #m == 0 then return true end
    if #m == last then stalled = stalled + 1 else last, stalled = #m, 0 end
    if stalled >= 30 and not retried then
      retried = true
      log("  installing parsers: " .. table.concat(m, ", "))
      pcall(function() require("nvim-treesitter").install(m) end)
    end
    return false
  end, 1000)
  if not done then log("  parsers still missing: " .. table.concat(missing(), ", ")) end

  -- Mason tools.
  require("lazy").load({ plugins = { "mason.nvim" } })
  local registry = require("mason-registry")
  registry.refresh(function()
    -- LazyVim's own Mason setup starts installing the same list as soon as
    -- Mason loads. Only start what it hasn't, and never let an error here
    -- stop us from waiting below.
    local wanted = LazyVim.opts("mason.nvim").ensure_installed or {}
    for _, name in ipairs(wanted) do
      local found, pkg = pcall(registry.get_package, name)
      if not found then
        log("  mason: unknown package " .. name)
      elseif not pkg:is_installed() and not pkg:is_installing() then
        pcall(pkg.install, pkg)
      end
    end
    log("Mason: waiting for installs to finish...")

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
