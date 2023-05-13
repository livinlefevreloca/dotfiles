echo "Sourcing utils module"

export BOOKMARKS_DIR="${HOME}/Bookmarks"
export MODULES_DIR="${HOME}/.shell"

#
# Helper function used to select a module by looking in the .shell directory.
#
function _select_mod() {
    if [[ ! -n "${1}" ]]
    then
        local module=$(ls "$MODULES_DIR" | fzf)
    else
        local module="${1}.zsh"
    fi

    echo "${module}"
}

#
# Command to open a give module in nvim. If no module is given
# then a list of modules is presented to the user to select from.
#
function edt_mod() {
    local module_dir="$MODULES_DIR"
    local module=$(_select_mod $@)
    nvim "${module_dir}/${module}"
}

#
# Command to refresh (source) a give module in an isolated fashion.
# If no module is given then a list of modules is presented to 
# the user to select from.
#
function src_mod() {
    local module_dir="$MODULES_DIR"
    local module=$(_select_mod $@)
    source "${module_dir}/${module}"
}

#
# Reset the state of all modules to unset.
#
reset_modules() {
    unset FZF_FUNCTIONS_SET
    unset GIT_FUNCTIONS_SET
    unset PYENV_FUNCTIONS_SET
    unset AWS_FUNCTIONS_SET
    unset TERRAFORM_FUNCTIONS_SET
    unset UTIL_FUNCTIONS_SET
    unset ALBERT_FUNCTIONS_SET
}

#
# Add a link to to the bookmarks directory. as a webloc file.
# This allows Spotlight to index it.
#
bookmark () {
    test [[ ! -d "${BOOKMARKS_DIR}" ]] && mkdir "${BOOKMARKS_DIR}" && echo "Bookmarks missing. Created ${BOOKMARKS_DIR}"
    url=${1}
    title="${2}"
    if [[ -z "${title}" ]]
    then
        title=$(curl -s "${url}" | rg -o "<title>.*</title>" | sed -e "s/<title>//" -e "s/<\/title>//" | tr -d '\n' | tr -d '\r' | tr -d ' ' | tr -d '\t')
    fi
    file="${BOOKMARKS_DIR}/${title}.webloc"
    xml='<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>URL</key>'"<string>"${url}"</string>"'</dict></plist>'
    echo $xml > $file
}

#
# Open a bookmark directly from the command line.
#
bk () {
    open "$(ls $BOOKMARKS_DIR | fzf | xargs -I {} echo "${BOOKMARKS_DIR}/{}")"
}

#
# Remove terminal color codes from a string.
#
decolorize() {
    sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'
}

export UTIL_FUNCTIONS_SET=1
