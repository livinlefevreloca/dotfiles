# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/adam.lefevre/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="xiong-chiamiov-plus-custom"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#



#install required cli tools (please install brew first)
touch temp
if_not_i () {
    if ! which $1;
    then
        echo $1 >> temp
    fi
}

if_not_i ctags
if_not_i exa
if_not_i fd
if_not_i fzf
if_not_i git
if_not_i jq
if_not_i htop
if_not_i hiredis
if_not_i neovim
if_not_i node
if_not_i nmap
if_not_i pyenv
if_not_i pyenv-virtualenv
if_not_i ripgrep
if_not_i shellcheck
if_not_i tfenv
if_not_i tmux

if [[ `cat temp` != "" ]];
then
    brew install `cat temp | xargs`
fi
rm temp

if ! which cargo;
then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

if ! which go;
then
    (cd ~/Downloads && curl -O https://golang.org/dl/go1.16.2.darwin-amd64.pkg && cd -)
    open ~/Downloads/go1.16.2.darwin-amd64.pkg
    go version
fi

# end install


# Example aliases
export EDITOR='/usr/local/bin/nvim'
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

#git

branch() { git branch | grep '\*' | awk '{print $2}' }

push() { git push ${1:-} origin $(branch); }
pull() { git pull origin $(branch); }

checkout () {
        git checkout `git branch | fzf`
        pull
}

cp_branch () {
	git branch | grep '\*.*' | cut -d' ' -f2 | pbcopy
}


pick-to-branch () {
        hash=`git log > temp && head -1 temp | cut -d' ' -f2`
        git checkout "$1"
        git cherry-pick "$hash"
        rm temp
}


fast_push () {
    git commit -am "$@"
    push
}

select-branch () {
    git branch | fzf
}
#end

#aws 

change_profile () {
    export AWS_PROFILE=${1}
}
#end aws

# fzf functions
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

fzview () {
    local flag=
    if [[ $1 == '-s' ]]
    then
        local flag='-p'
    fi    
    bat $flag $(fd -H . ~ | fzf)
}


fzedit () {
    local root=~
    if [[ $1 == '-r' ]]
    then
        local root=/
    fi    
    local file=$(fd -H . "$root" | fzf)
    if [[ -n "$file" ]];
        then
            nvim -p $file
        fi
}
#end fzf functions

#useful functions

tgrep () {
    local pattern=$1
    awk "NR == 1 {print}; /$pattern/"
}

#end useful functions

#terraform
export PATH="$HOME/.tfenv/bin:$PATH"

if [[ -n $TMUX ]]; then
    export RPROMPT=''
fi

# pyenv

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"


activate () {
    pyenv activate $1
    export VENV=$1
    fix
    if ! pip freeze | grep "neovim" || ! pip freeze | grep "jedi" || ! pip freeze | grep "pylint"; then
        pip install neovim jedi pylint
    fi
}
reset () {
    pyenv deactivate
    unset VENV
}

#end pyenv

#kubectl
source <(kubectl completion zsh)
export KUBECONFIG="$HOME/.kube/config"


k8s_dash () {
  k8s_token && k port-forward svc/management-dashboard-kubernetes-dashboard -n kube-system 2020:443
}
fix_kubeconfig () {
  aws eks --region us-east-1 update-kubeconfig --name beta-eks-cluster
  aws eks --region us-east-1 update-kubeconfig --name prod-eks-cluster
  k config rename-context arn:aws:eks:us-east-1:197867815768:cluster/beta-eks-cluster beta
  k config rename-context arn:aws:eks:us-east-1:197867815768:cluster/prod-eks-cluster prod
}

fix
