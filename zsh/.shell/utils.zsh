echo "Sourcing utils module"

function _select_mod() {
    if [[ ! -n "${1}" ]]
    then
        local module=$(ls "${HOME}/.shell/" | fzf)
    else
        local module="${1}.zsh"
    fi

    echo "${module}"
}


function edt_mod() {
    local module_dir="${HOME}/.shell"
    local module=$(_select_mod $@)
    nvim "${module_dir}/${module}"
}

function src_mod() {
    local module_dir="${HOME}/.shell"
    local module=$(_select_mod $@)
    source "${module_dir}/${module}"
}


alert_finish() {
    ($@ && say "Task succeeded") || say "Task Failed"
}

reset_modules() {
    unset FZF_FUNCTIONS_SET
    unset GIT_FUNCTIONS_SET
    unset PYENV_FUNCTIONS_SET
    unset AWS_FUNCTIONS_SET
    unset TERRAFORM_FUNCTIONS_SET
    unset UTIL_FUNCTIONS_SET
    unset ALBERT_FUNCTIONS_SET
}


export UTIL_FUNCTIONS_SET=1
