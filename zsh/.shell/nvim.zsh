echo "Sourcing nvim module"

vim () {
	if [ $# -eq 0 ]
	then
		nvim .
	else
		nvim $@
	fi
}

export NVIM_FUNCTIONS_SET=1
