sudo apt-get upgrade
sudo apt-get update
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl

curl https://pyenv.run | bash

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
source ~/.bashrc
pyenv install -v 3.8.0
pyenv install 3.7.4
pyenv global 3.8.0
sudo apt-get install tmux
sudo apt-get install neovim
python -m pip install pipx
pip install --upgrade pip
pipx install visidata
pipx ensurepath
pipx inject pandas lxml pyyaml numpy requests openpyxl pypng 
pipx inject visidata pandas lxml pyyaml numpy requests openpyxl pypng 
pipx install youtube-dl
git clone https://github.com/benignoc/dotfiles.git
source make_linux_links.sh 
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod u+x Miniconda3-latest-Linux-x86_64.sh 
./Miniconda3-latest-Linux-x86_64.sh
cd ~
mkdir scripts
cd scripts
wget https://github.com/neovim/neovim/releases/download/v0.4.3/nvim.appimage
./nvim.appimage --appimage-extract
echo "alias nvim='~/scripts/squashfs-root/usr/bin/nvim'" >> dotfiles/.bash_aliases
cd ~
ln -s dotfiles/.bash_aliases .bash_aliases
