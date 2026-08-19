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
edt_mod () {
	local module_dir="$MODULES_DIR"
	local module=$(_select_mod $@)
	nvim "${module_dir}/${module}"
}


#
# Command to refresh (source) a give module in an isolated fashion.
# If no module is given then a list of modules is presented to
# the user to select from.
#
src_mod () {
	local module_dir="$MODULES_DIR"
	local module=$(_select_mod $@)
	source "${module_dir}/${module}"
}

scratch () {
  filename="$1"
  if [[ -z "$filename" ]]
  then
    filename=$(python -c 'import uuid; print(uuid.uuid4())').txt
  fi
  local dirname="/tmp/scratch/$(date +%Y%m%d)"
  if [[ ! -d $dirname ]]
  then
    mkdir -p $dirname
  fi

  lvim "${dirname}/${filename}"
}

#
# Reset the state of all modules to unset.
#
reset_modules () {
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
	[[ ! -d "${BOOKMARKS_DIR}" ]] && mkdir "${BOOKMARKS_DIR}" && echo "Bookmarks missing. Created ${BOOKMARKS_DIR}"
	local url=${1}
	local title="${2}"
	if [[ -z "${title}" ]]
	then
		local title=$(curl -s "${url}" | rg -o "<title>.*</title>" | sed -e "s/<title>//" -e "s/<\/title>//" | tr -d '\n' | tr -d '\r' | tr -d ' ' | tr -d '\t')
	fi
	local file="${BOOKMARKS_DIR}/bk ${title}.webloc"
	local xml='<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>URL</key>'"<string>"${url}"</string>"'</dict></plist>'
	echo $xml > $file
}

#
# Open a bookmark directly from the command line.
#
bk () {
    local found="$(ls $BOOKMARKS_DIR | fzf | xargs -I {} echo "${BOOKMARKS_DIR}/{}")"
    if [[ -n "${found}" ]]
    then
        open "${found}"
    fi
}

rm_bookmark () {
	local found="$(ls $BOOKMARKS_DIR | fzf | xargs -I {} echo "${BOOKMARKS_DIR}/{}")"
	if [[ -n "${found}" ]]
	then
		rm "${found}"
	fi
}

#
# Remove terminal color codes from a string.
#
decolorize() {
    sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'
}


#
# Locally forward a port to a remote host.
forward () {
	local listen_port="${1}"
	local remote_host="${2}"
	local remote_port="${3}"
	socat tcp-l:${1},fork,reuseaddr tcp:${2}:${3}
}


d() {
	if [[ -n $1 ]]
	then
		dirs "$@"
	else
		dirs -v | head -n 10
	fi
}

j() {
    tasksfile=/tmp/$(uuidgen)
    pidfile=/tmp/$(uuidgen)
    jobs -p > $tasksfile


    while read -r line
    do
        num=$(echo $line | cut -d' ' -f1)
        pid=$(echo $line | cut -d' ' -f4)
        command=$(ps -o pid,command -ax | rg -v 'rg' | rg $pid | cut -d' ' -f2-)
        echo "$num $pid $command" >> $pidfile
    done < $tasksfile

    num=$(cat $pidfile | fzf | cut -d' ' -f1 | rg -o '\d+')

    if [[ -z $num ]]
    then
        return
    fi

    rm $tasksfile
    rm $pidfile

    fg %$num
}

decolorize () {
	gsed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'
}

mkcd () {
	mkdir -p $@ && cd ${@:$#}
}

chtsht () {
  local query="$@"
  if [[ -z "${query}" ]]
  then
    query=$(curl -s "cheat.sh/:list" | fzf --preview 'curl -s cheat.sh/{}')
  fi
  curl -s "cheat.sh/${query// /+}" | delta
}

htb() {
  TERM=tmux ssh -t livinlefevreloca@10.0.0.243 tmux
}


export UTIL_FUNCTIONS_SET=1
