export DOTFILES_DIR='/Users/adam/Projects/Config/dotfiles'
# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/opt/libpq/bin:$PATH
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export GHCR_TOKEN=$(cat ~/.ghcr_token)

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

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

#Uncomment the following line to display red dots whilst waiting for completion.
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
plugins=(
    git
    kubectl
)

# set up ohmyzsh
source $ZSH/oh-my-zsh.sh
# end set up ohmyzsh


#install required cli tools (please install brew first)
# touch temp
# if_not_i () {
#     if ! which $1;
#     then
#         echo $1 >> temp
#     fi
# }
#
# if_not_i ctags
# if_not_i exa
# if_not_i fd
# if_not_i fzf
# if_not_i git
# if_not_i jq
# if_not_i htop
# if_not_i neovim
# if_not_i node
# if_not_i pyenv
# if_not_i pyenv-virtualenv
# if_not_i ripgrep
# if_not_i shellcheck
# if_not_i tfenv
# if_not_i tmux
# if_not_i bat
# if_not_i socat
# if_not_i git-delta
# if_not_i ccls
#
#
#
# if [[ `cat temp` != "" ]];
# then
#     brew install `cat temp | xargs`
# fi
# rm temp

#if ! which cargo;
#then
#    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
#fi

#if ! which go;
#then
#    (cd ~/Downloads && curl -O https://golang.org/dl/go1.16.2.darwin-amd64.pkg && cd -)
#    open ~/Downloads/go1.16.2.darwin-amd64.pkg
#    go version
#fi

# end install

# General Exports
export SHELL_SCRIPTS="${HOME}/.shell"
export EDITOR='/usr/local/bin/nvim'
export PATH="$(which cmake):$PATH"
export GO111MODULE=on
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Refresh shell scripts. We need to remove the existing symlinks to pick up new changes
rm -rf "${SHELL_SCRIPTS}"
mkdir -p "${SHELL_SCRIPTS}"
ln -s ${DOTFILES_DIR}/zsh/.shell/* ${SHELL_SCRIPTS}
ln -s ${DOTFILES_DIR}/zsh/.shell/.aliases ${SHELL_SCRIPTS}/.aliases

# Refresh lazy vim symlinks
rm -rf "${HOME}/.config/lazyvim"
mkdir -p "${HOME}/.config/lazyvim"
ln -s ${DOTFILES_DIR}/lazyvim/* ${HOME}/.config/lazyvim

if [[ ! -z "${TMUX+x}" ]]
then
    source <(env | rg '_SET=1' | awk -F '=' '{print "unset "$1}')
fi

if [[ $(env | rg VIMRUNTIME) ]]
then
    source ~/.shell/.aliases
    echo "Running from vim skipping modules"
else
# fzf
[[ ! "$FZF_FUNCTIONS_SET" && -f "${SHELL_SCRIPTS}/fzf.zsh" ]] && source ${SHELL_SCRIPTS}/fzf.zsh
#end fzf functions

# key bindings
[[ -f "${SHELL_SCRIPTS}/bindings.zsh" ]] && source "${SHELL_SCRIPTS}/bindings.zsh"
# end key bindings

# aliases
[ -f "${SHELL_SCRIPTS}/.aliases" ] && source "${SHELL_SCRIPTS}/.aliases"
# end aliases

# git
[[ ! "$GIT_FUNCTIONS_SET" && -f "${SHELL_SCRIPTS}/git.zsh" ]] && source "${SHELL_SCRIPTS}/git.zsh"
# end git

# k8s
[[ ! "$K8S_FUNCTIONS_SET" && -f "${SHELL_SCRIPTS}/k8s.zsh" ]] && source "${SHELL_SCRIPTS}/k8s.zsh"
# end k8s

# pyenv
[[ ! "$PYENV_FUNCTIONS_SET" && -f "${SHELL_SCRIPTS}/pyenv.zsh" ]] && source "${SHELL_SCRIPTS}/pyenv.zsh"
#end pyenv

#aws
[[ ! "$AWS_FUNCTIONS_SET" && -f "${SHELL_SCRIPTS}/aws.zsh" ]] && source "${SHELL_SCRIPTS}/aws.zsh"
# end aws

# terraform
[[ ! "$TERRAFORM_FUNCTIONS_SET" && -f "${SHELL_SCRIPTS}/terraform.zsh" ]] && source "${SHELL_SCRIPTS}/terraform.zsh"
# end aws

# utils
[[ ! "$UTIL_FUNCTIONS_SET" && -f "${SHELL_SCRIPTS}/utils.zsh" ]] && source ${SHELL_SCRIPTS}/utils.zsh
#end utils functions

# notes
[[ ! "$NOTES_FUNCTIONS_SET" && -f "${SHELL_SCRIPTS}/notes.zsh" ]] && source ${SHELL_SCRIPTS}/notes.zsh
#end note
#
# nvim
[[ ! "$NVIM_FUNCTIONS_SET" && -f "${SHELL_SCRIPTS}/notes.zsh" ]] && source ${SHELL_SCRIPTS}/nvim.zsh
#end nvim

# LLM
[[ ! "$LLM_FUNCTIONS_SET" && -f "${SHELL_SCRIPTS}/llm.zsh" ]] && source "${SHELL_SCRIPTS}/albert.zsh"
# end LLM

#Albert
[[ $(whoami) -eq 'adamlefevre' ]] && [[ ! "$ALBERT_FUNCTIONS_SET" && -f "${SHELL_SCRIPTS}/albert.zsh" ]] && [[ ! "$SKIP_ALBERT" ]] && source "${SHELL_SCRIPTS}/albert.zsh"
# end Albert



fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.1.0/bin:$PATH"

[ -f "/Users/adamlefevre/.ghcup/env" ] && source "/Users/adamlefevre/.ghcup/env" # ghcup-env

source ~/.private.env

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
clear


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/Users/adam/.opam/opam-init/init.zsh' ]] || source '/Users/adam/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration

# bun completions
[ -s "/Users/adam/.bun/_bun" ] && source "/Users/adam/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# golang
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$PATH:$GOBIN"
export GEMINI_API_KEY=$(cat ~/.gemini)
