echo "Sourcing pyenv module"

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"


activate () {
    pyenv activate $1 && \
    fix && \
    export VENV=$1
    if ! pip3 freeze | grep "neovim" || ! pip3 freeze | grep "jedi" || ! pip3 freeze | grep "flake8" || ! pip3 freeze | grep "pylint" || ! pip3 freeze | grep "black" 
    then
        pip3 install neovim jedi pylint flake8 black
    fi
    VENV="$PYENV_VERSION"
}
reset () {
    pyenv deactivate
    export VENV=?
}

export PATH=/Users/adamlefevre/.pyenv/shims:$PATH

export PYENV_FUNCTIONS_SET=1
