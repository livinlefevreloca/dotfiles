echo "Sourcing fzf module"

#
# Enable fzf
#
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export BAT_THEME='gruvbox-dark'

#
# Open file similar to the passed name. If there are multiple matches, open fzf to select
#
edit () {
    local query
    local hidden
    local ignore
    local target
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
    shift $((OPTIND -1))
    query="$1"

    if [[ -f $(echo "$query" | cut -d":" -f1) ]]
    then
        nvim "$query"
        return 0
    fi

    lines=$(fd --full-path $hidden $ignore -t f "$query")
    if [[ $(echo "$lines" | wc -l) -eq 1 ]]
    then
        nvim "$lines"
        return 0
    fi
    lines=$(fd $hidden $ignore -t f --full-path)

    if [[ "$lines" == "" ]]
    then
        return 1
    else
        target=$(echo "$lines" | fzf -q "$query" -m --preview 'bat {} --color=always' | xargs)
    fi

    if [[ -n "$target" ]]
    then
        nvim $(echo $target)
    fi
}

#
# Find lines of code that match the passed pattern. If there are multiple matches, open fzf to select
#
fnd () {

    local filter="-g!'**test**'"
    local definition
    local file_type
    local prefix
    local hidden
    local ignore

    local file_type="$(_get_default_file_type)"
    while getopts 'adhint:' opt; do
        case "$opt" in
            a)
                file_type='all' ;;
            d)
                definition=1 ;;
            h)
                hidden="--hidden" ;;
            i)
                ignore="--no-ignore" ;;
            n)
                filter='' ;;
            t)
                if [[ "$file_type" == 'all' ]]
                then
                    echo "cannot specify file type when searching all files"
                    return 1
                fi
                file_type=$(echo "$OPTARG" | xargs) ;;
            \?)
                echo "unexpected argument found $1"
                return 1 ;;
            esac
    done

    shift $((OPTIND -1))
    local pattern="$1"

    if [[ "$definition" == 1 ]] then
        case "$file_type" in
            'py')
                prefix='(def|class) ' ;;
            'lkml')
                prefix='(dimension|explore) ' ;;
            'rs')
                prefix='(pub|fn|struct|enum|mod|type|trait|const|static|impl|macro_rules) ' ;;
            *)
        esac

        pattern="${prefix}${pattern}"
    fi

    echo "$file_type is the file type"

    if (rg --type-list | cut -d':' -f1 | rg "^${file_type}$" > /dev/null)
    then
        file_type="-t${file_type}"
    elif [[ "$file_type" == 'all' ]]
    then
        file_type=''
    else
        file_type="-g'**.${file_type}'"
    fi

    echo rg --column "$pattern" $hidden $ignore ${filter//"'"/} ${file_type//"'"/}
    local lines=$(rg --column "$pattern" $hidden $ignore ${filter//"'"/} ${file_type//"'"/} | awk '!/^$/')

    if [ "$lines" = "" ]; then
      return 1
    elif [ $(wc -l <<< "$lines") -eq 1 ]; then
        location=$(echo "$lines" | rg '.*(^[^:]+):(\d+).*' -r '$1' | xargs)
        line=$(echo "$lines" | rg '.*(^[^:]+):(\d+).*' -r '$2' | xargs)
        nvim $location +:$line
    else
        files=$(echo "$lines" | fzf -m --reverse --preview 'line=$(echo {} | cut -d":" -f2); bat -r $((line - 20 < 0 ? 1 : line - 20)): -H $line  --color=always $(echo {} | cut -d":" -f1)'| rg '.*(^[^:]+):(\d+).*' -r '$1 +:$2' | xargs)
        if [ ! -z "$files" ]
        then
            nvim $(echo $files)
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
    local query
    local target

    if [[ -n "$1" && ("${1:0:1}" != "-" || "$1" == "-") ]]
    then
        if [[ -d "$1" ]]
        then
            cd "$1"
            return 0
        else
            query="$1"
            shift;
        fi
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
                dir="$OPTARG" ;;
            \?)
                echo "unexpected argument found ${1}"
                return 1 ;;
            esac
    done

    if [[ -n "$dir" ]]
    then
        target=$(fd . "$dir" -d 4 $hidden $ignore -t d  | fzf --query "$query" --tiebreak=length --preview 'exa -lR {}')
    else
        target=$(fd . "$HOME" -d 4 $hidden $ignore -t d | fzf --query "$query" --tiebreak=length --preview 'exa -lR {}')
    fi

    if [[ -n "$target" ]]
    then
        cd "$target"
    fi
}

#
# Get the most common filetpye in the current directory filtering out png
#
_get_default_file_type() {
    echo $(fd . -t f | rg -v '.*png' |rg '.*\.(\S+)$' -r '$1' | sort | uniq -c | sort -r | awk 'NR==1{print $2}')
}

export FZF_FUNCTIONS_SET=1
