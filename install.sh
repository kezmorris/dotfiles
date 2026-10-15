#!/usr/bin/env bash
# Set up Neovim (LazyVim) + tmux from this repo.
#
#   ./install.sh            full install
#   ./install.sh --no-brew  skip Homebrew (install the Brewfile tools yourself)
#
# Safe to re-run: links that are already correct are left alone, and anything
# in the way is moved to <name>.backup-<timestamp> rather than deleted.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
USE_BREW=1
[ "${1:-}" = "--no-brew" ] && USE_BREW=0

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[33m  ! %s\033[0m\n' "$1"; }

# link SOURCE TARGET: make TARGET a symlink to SOURCE, backing up whatever is there.
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ok      $dst"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.backup-$STAMP"
    echo "  backup  $dst -> $dst.backup-$STAMP"
  fi
  ln -s "$src" "$dst"
  echo "  linked  $dst -> $src"
}

step "Tools"
if [ $USE_BREW -eq 1 ]; then
  if ! command -v brew >/dev/null; then
    echo "Homebrew isn't installed. Either install it (https://brew.sh) and re-run,"
    echo "or install the tools in Brewfile yourself and run: ./install.sh --no-brew"
    exit 1
  fi
  brew bundle --file="$DOTFILES/Brewfile"
fi
for cmd in nvim git rg fd tree-sitter cc; do
  command -v "$cmd" >/dev/null || warn "$cmd not found - some features won't work"
done
# Mason builds language tools with these. Not in the Brewfile because you may
# already manage them another way (nvm, pyenv, a company installer...).
command -v npm     >/dev/null || warn "npm not found: TypeScript/JSON/YAML/Docker tools won't install (brew install node)"
command -v go      >/dev/null || warn "go not found: gopls and the Go tools won't install (brew install go)"
command -v python3 >/dev/null || warn "python3 not found: ruff/debugpy won't install"

step "Linking config"
link "$DOTFILES/nvim"           "$HOME/.config/nvim"
link "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"

step "Neovim plugins (pinned versions from lazy-lock.json)"
nvim --headless "+Lazy! restore" +qa

step "Language servers, formatters and syntax parsers (this takes a few minutes)"
nvim --headless -c "luafile $DOTFILES/scripts/nvim-bootstrap.lua" || warn "some tools failed - see above"

if [ -n "${TMUX:-}" ] || tmux info >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" && echo "  reloaded running tmux"
fi

step "Done"
cat <<'MSG'
  - Set your terminal font to "JetBrainsMono Nerd Font".
  - macOS: set your terminal to use Option as Meta/Alt (needed for Alt-h, Alt-j/k).
  - Start tmux, then nvim. tmux prefix is Ctrl-a; Ctrl-a e / Ctrl-a E open panes.
MSG
