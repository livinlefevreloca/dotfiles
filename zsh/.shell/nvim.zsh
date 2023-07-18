echo "Sourcing nvim module"

function n() {
    if [ $# -eq 0 ]; then
        nvim .
    else
        nvim $@
    fi
}

export NVIM_FUNCTIONS_SET=1
