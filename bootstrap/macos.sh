#!/usr/bin/env bash
set -euo pipefail

xcode-select --install 2>/dev/null || true
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew update
brew install neovim ripgrep fd fzf git lazygit node pnpm python3
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-bash --no-zsh --no-fish

# Symlink nvim config
mkdir -p ~/.config/nvim
rsync -a --delete "$(pwd)/nvim/" ~/.config/nvim/

# Shell config
grep -q 'NOTES_DIR' ~/.zshrc 2>/dev/null || cat "$(pwd)/shell/mac.zsh" >>~/.zshrc

echo "Done. Open a new terminal. NOTES_DIR must point to your notes repo path."
