# dotfiles

Neovim (LazyVim) + tmux, set up as an IDE.

## Install on a new machine

```sh
git clone <this repo> ~/dotfiles
cd ~/dotfiles && ./install.sh
```

What `install.sh` does:

1. Installs the tools in `Brewfile` (neovim, tmux, ripgrep, fd, lazygit,
   tree-sitter-cli, a Nerd Font). Use `./install.sh --no-brew` if you can't use
   Homebrew and have installed them some other way.
2. Symlinks `~/.config/nvim` → `nvim/` and `~/.tmux.conf` → `tmux/tmux.conf`.
   Anything already there is moved to `*.backup-<timestamp>`, not deleted.
3. Installs the Neovim plugins at the exact versions pinned in `nvim/lazy-lock.json`.
4. Installs the language servers, formatters and debuggers listed in
   `nvim/lua/plugins/mason.lua`, and compiles the syntax parsers.

Re-running it is safe.

It needs `npm`, `go` and `python3` on your PATH for some language tools.
The script warns you about any that are missing.

Afterwards: set the terminal font to **JetBrainsMono Nerd Font** and make
Option act as Meta/Alt.

## Keeping machines in sync

Because the configs are symlinks, editing `~/.config/nvim` edits this repo.

- **Changed a setting?** Commit and push, then `git pull` on the other machine.
- **Updated plugins** (`:Lazy update`)? Commit `nvim/lazy-lock.json`. On the
  other machine, `git pull`, then run `:Lazy restore` in nvim.
- **Added a language?** Add its extra in `nvim/lua/config/lazy.lua` and its
  tools in `nvim/lua/plugins/mason.lua`, then re-run `./install.sh`.

## Layout

| Path | What |
|---|---|
| `nvim/lua/config/lazy.lua` | plugin manager setup + enabled LazyVim extras (languages, debugger, tests) |
| `nvim/lua/plugins/` | additions: tmux navigation, the Mason tool list |
| `nvim/lazy-lock.json` | pinned plugin versions |
| `tmux/tmux.conf` | prefix `Ctrl-a`, `Ctrl-a e`/`E` panes, vim-tmux-navigator |
| `scripts/nvim-bootstrap.lua` | headless installer for Mason tools + parsers |
