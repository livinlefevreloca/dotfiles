#! /bin/bash

# install nvim
which nvim  || brew install nvim

if [[ ! -f ~/.config/nvim/ ]]; then
    mkdir -p ~/.config/nvim/
fi

if [[ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]]; then
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi


#install useful cli utilities

which fzf || brew install fzf
which exa || brew install exa
which rg  || brew install rg
which lazydocker || brew install lazydocker
which fd || brew install fd


# install dotfiles

git clone  git@github.com:livinlefevreloca/dotfiles.git
mv dotfiles/zsh/.zshrc ~ && mv dotfiles/nvim/init.vim ~/.config/init.vim


# install oh-my-zsh and font patches
if [[ ! -f ~/.oh-my-zsh ]]; then

    sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
    cd ~/.oh-my-zsh
    git clone git@github.com:powerline/fonts.git
    ./install.sh
fi
