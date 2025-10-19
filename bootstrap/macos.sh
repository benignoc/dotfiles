#!/usr/bin/env bash

# Execute from dotfiles folder
set -euo pipefail

xcode-select --install 2>/dev/null || true

# Homebrew
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew update && brew upgrade
brew install neovim ripgrep fd fzf git lazygit node stow oh-my-posh tmux

# FZF key-bindings (optional)
"$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-bash --no-fish --no-zsh

# Symlink dotfiles with stow (run from repo root)
cd "$(dirname "$0")/.." # go to dotfiles repo root

# Install TPM for tmux plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# back it up safely (timestamped)
bak="$HOME/.config/nvim/.backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$bak"
mv ~/.config/nvim/lua/config/options.lua "$bak/"

# try stow again from the dotfiles repo root
cd ~/dotfiles
# Stow only what you want; this creates symlinks under $HOME
stow -v nvim
stow -v ohmyposh
stow -v shell

# already in shell/.zshenv
# NOTES_DIR env (adjust to your notes repo location)
# if ! grep -q 'NOTES_DIR' "$HOME/.zshrc" 2>/dev/null; then
#   echo 'export NOTES_DIR="$HOME/notes"' >>"$HOME/.zshrc"
#   echo 'export EDITOR="nvim"' >>"$HOME/.zshrc"
# fi

echo "Done. Open a new terminal. Check links with: ls -l ~/.config/nvim"
