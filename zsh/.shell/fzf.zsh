echo "Sourcing fzf module"

#
# Enable fzf
#
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#
# Open file similar to the passed name. If there are multiple matches, open fzf to select
#
edit () {
    local pattern
    local hidden
    local ignore
    if [[ -n "$1" && "${1:0:1}" != "-" ]]
    then
        pattern="$1"
        shift;
    fi
    while getopts 'hi' opt; do
        case "$opt" in
            h)
                hidden='-H' ;;
            i)
                ignore='-I' ;;
            \?)
                echo "unexpected argument found ${1}"
                return 1 ;;
        esac
    done
    
    if [[ -n "$pattern" ]]
    then
        pattern="${pattern}"
    else
        pattern=".*"
    fi
    lines=$(fd $hidden $ignore --full-path --regex "$pattern" .)

    if [[ "$lines" == "" ]]
    then
        return 1
    elif [[ $(wc -l <<< "$lines") -eq 1 ]]
    then
        nvim "$lines"
    else
        nvim $(echo "$lines" | fzf -m)
    fi

}

#
# Find lines of code that match the passed pattern. If there are multiple matches, open fzf to select
#
fnd () {

    local filter
    local definition
    local file_type
    local prefix

    local pattern="$1"
    shift

    local file_type=$(_get_default_file_type)
    while getopts 'dt:' opt; do
        case "$opt" in
            d)
                definition=1 ;;
            t)
                file_type="$OPTARG" ;;
            \?)
                echo "unexpected argument found $1"
                return 1 ;;
            esac
    done


    if [[ "$definition" == 1 ]] then
        echo "file type is ${file_type}" 
        case "$file_type" in
            'py')
                prefix='(def|class) ' ;;
            'lkml')
                prefix='(dimension|explore).*? ' ;;
            *)
        esac

        pattern="${prefix}${pattern}" 
    fi

    local lines=$(rg --column "$pattern" -g!"*test*" | awk '!/^$/')

    if [ "$lines" = "" ]; then
      return 1
    elif [ $(wc -l <<< "$lines") -eq 1 ]; then
        location=$(echo "$lines" | rg -o '^[^:]+:\d+')
        nvim "$location"
    else
        file=$(echo "$lines" | fzf --reverse | rg -o '^[^:]+:\d+')

        if [ ! -z "$file" ]
        then
            nvim "$file"
        fi
    fi

}

#
# Enhanced cd using fzf to list directories for selection
#
jmp () {
    local hidden
    local ignore
    local dir
    local target

    if [[ -n "$1" && "${1:0:1}" != "-" ]]
    then
        cd "$1"
        return 0
    fi

    while getopts 'hicd::' opt; do
        case "$opt" in
            h)
                hidden='-H' ;;
            i)
                ignore='-I' ;;
            c)
                dir=$(pwd) ;;
            d)
                if [[ -n "$dir" ]]
                then
                    echo "WARN: -c (current directory) option is set. ignoring directory argument"
                fi
                dir="$OPTARG" ;;
            \?)
                echo "unexpected argument found ${1}"
                return 1 ;;
            esac
    done
    if [[ -n "$dir" ]]
    then
        target=$(fd . "$dir" -d 4 $hidden $ignore -t d  | fzf --tiebreak=length)
    else
        target=$(fd . "$HOME" -d 4 $hidden $ignore -t d | fzf --tiebreak=length)
    fi

    if [[ -n "$target" ]]
    then
        cd "$target"
    fi
}

#
# Get the most common filetpye in the current directory
#
_get_default_file_type() {
    echo $(fd . -t f | rg '.*\.(\S+)$' -r '$1' | sort | uniq -c | sort -r | awk 'NR==1{print $2}')
}

export FZF_FUNCTIONS_SET=1
