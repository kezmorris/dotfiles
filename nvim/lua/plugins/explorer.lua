-- Explorer (Space e) shows dotfiles and git-ignored files by default.
-- H and I in the explorer still toggle them off for the session.
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}
