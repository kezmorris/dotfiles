-- Point markdownlint at the global settings in ~/dotfiles/markdownlint
-- (turns off the line-length rule everywhere).
return {
  {
    "mfussenegger/nvim-lint",
    opts = function()
      local config = vim.fn.expand("~/dotfiles/markdownlint/.markdownlint-cli2.yaml")
      require("lint").linters["markdownlint-cli2"].args = { "--config", config, "-" }
    end,
  },
}
