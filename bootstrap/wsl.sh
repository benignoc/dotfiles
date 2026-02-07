#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y neovim ripgrep fd-find git curl python3-pip nodejs npm

# fd binary name varies on Ubuntu
if ! command -v fd >/dev/null && command -v fdfind >/dev/null; then
  sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

# nvim config
mkdir -p ~/.config/nvim
rsync -a --delete "$(pwd)/win_home/dotfiles/nvim/" ~/.config/nvim/

# shell
grep -q 'NOTES_DIR' ~/.bashrc 2>/dev/null || cat "$(pwd)/win_home/dotfiles/shell/wsl.bash" >>~/.bashrc

echo "Done. Reopen terminal. Ensure NOTES_DIR points to /home/<user>/notes (or your path)"
