echo "Sourcing fzf module"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

edit () {
    lines=$(fd --full-path "$1")
    
    if [[ "${lines}" == "" ]]
    then
        return 1
    elif [[ $(wc -l <<< "${lines}") -eq 1 ]]
    then
        nvim "$lines"
    else
        nvim -p $(echo "${lines}" | fzf -m)
    fi

}

fnd () {
    
    local filter
    local definition
    
    while [[ "$#" > 1 ]]; do
        case "$1" in
        '-d'|'--def')
            definition=1
            shift ;;
        '-f'|'--filter')
            filter="$2"
            shift
            shift ;;
        *)
            echo "unexpected argument found $1 ... exiting"
            exit(1) ;;
        esac
    done

    local pattern="$1"

    if [[ "$definition" == 1 ]] then
        pattern="(def|class) $pattern"
    fi

    local lines=$(rg --column $pattern -g!"*test*" -t py | awk '!/^$/')
        
    if [[ -n "$filter" ]] then
        lines=$(echo "$lines" | rg -v "$filter")
    fi
    
    if [ "$lines" = "" ]; then
      return 1
    elif [ $(wc -l <<< "$lines") -eq 1 ]; then
        location=$(echo "$lines" | rg -o '^[^:]+:\d+')
        nvim "$location"
    else
        nvim `echo "$lines" | fzf --reverse | rg -o '^[^:]+:\d+'`
    fi

}

cls () {

    local first

    while [[ "$#" > 1 ]]; do
        case "$1" in
        '-1')
            first=1
            shift ;;
        *)
            echo "unexpected argument found $1 ... exiting"
            exit(1) ;;
        esac
    done

    if [[ "$first" != 1 ]] then
        places=`rg --column -t py "class \w*$1\w*(\(|:)"`
        test -n "$places" && place=`echo "$places" | fzf | cut -d: -f1-2`
        test -n "$place" && nvim "$place" && return 0
    
    else
        place=`rg --column -t py "class $1(\(|:)" | cut -d: -f1-2`
        test -n "$place" && nvim "$place" && return 0
    fi
}


export FZF_FUNCTIONS_SET=1
