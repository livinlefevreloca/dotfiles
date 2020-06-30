#! /usr/local/bin/bash

# install oh-my-zsh and font patches
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
cd ~/.oh-my-zsh 
git clone git@github.com:powerline/fonts.git
./install.sh

#install useful cli utilities

brew install fzf
brew install lazydocker
brew install exa
brew install rgrep
brew install nvim


# install dotfiles


