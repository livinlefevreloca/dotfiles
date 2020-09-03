# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/adam.lefevre/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="adam"

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

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

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
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/adam.lefevre/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/adam.lefevre/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/adam.lefevre/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/adam.lefevre/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
#git

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

#notes

notes () {
    
    cd ~/notes 
    nvim -p "$@"

}


#aws 
export AWS_PROFILE=tempusdevops-adam-lefevre

change_profile () {

    export AWS_PROFILE=${1}
}
#end aws


#end

#rust
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/usr/local/opt/libpq/bin:$PATH"

if [ -f ~/.aliases ]; then
    . ~/.aliases
fi


google () {
	IFS="+"
	firefox --new-window 'https://google.com/search?q='"$*"
}

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
    nvim $(fd -H . "$root" | fzf)
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#pyspark                                
export JAVA_HOME=/Library/java/JavaVirtualMachines/adoptopenjdk-8.jdk/contents/Home/                                
export JRE_HOME=/Library/java/JavaVirtualMachines/openjdk-13.jdk/contents/Home/jre/                                
export SPARK_HOME=/usr/local/Cellar/apache-spark/2.4.5/libexec                                
export PATH=/usr/local/Cellar/apache-spark/2.4.5/bin:$PATH                                
export PYSPARK_PYTHON=/usr/local/bin/python3                                
export PYSPARK_DRIVER_PYTHON=jupyter                                
export PYSPARK_DRIVER_PYTHON_OPTS='notebook'                                
                                
#venvs                                
export VENV_PATH="/Users/adam.lefevre/projects/venvs"                                
activate () {                                
    source "$VENV_PATH/$1/bin/activate"                                
    }                                
make_venv () {                                
        cd $VENV_PATH                                
        virtualenv $1                                
        cd -                                
}                         

###_begin_ttt_install_block_###
if [[ ${PATH} != '*ttt*' ]]; then
    export PATH=/Users/adam.lefevre/.ttt_home:$PATH
fi

online () {
    local ret;
    aws s3 ls &> /dev/null;
    ret=$?
    if [[ $ret != 0 ]]; then
        ttt aws-refresh write 
        eval $(ttt aws-refresh load tempusdevops-adam-lefevre) 
        ssh-add 
        cat ~/.aws/credentials | head -n $(( $(cat ~/.aws/credentials | wc -l | xargs) - 5))> ~/.aws/credentials 
        cat ~/.aws/credentials ~/.aws/staging_user.txt ~/.aws/cp.aws > temp && mv temp ~/.aws/credentials
    fi
}
###_end_ttt_install_block_###

if [[ ${PATH} != '*~/bin:*' ]]; then
    export PATH=~/bin:$PATH
fi
online
fix
# eval "$(starship init zsh)"
