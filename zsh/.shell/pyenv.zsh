echo "Sourcing pyenv module"

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"


# activate a virtualenv and install required packages for vim in it if they are not already installed
activate () {
	pyenv activate "$1" && . ~/bin/fix.sh && export VENV="$1"
	if ! pip freeze | rg --multiline --multiline-dotall '.*\bblack\b.*\bflake8\b.*\bjedi\b.*\bneovim\b.*\bpylint\b.*\bruff\b.*' > /dev/null
	then
		pip3 install neovim jedi pylint flake8 black ruff
	fi
	VENV="$1"
}

deact () {
	pyenv deactivate
	export VENV=?
}

export PATH="/Users/adamlefevre/.pyenv/shims:${PATH}"

export PYENV_FUNCTIONS_SET=1
