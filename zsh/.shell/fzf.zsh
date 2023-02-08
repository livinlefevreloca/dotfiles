echo "Sourcing fzf module"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

edit () {
    lines=$(fd --full-path --regex "$1")
    
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
    local file_type
    local prefix

    local pattern="$1"
    shift

    local file_type=$(_get_default_file_type)
    while getopts 'dt:' opt; do
        case $opt in
            d)
                definition=1 ;;
            t)
                file_type="${OPTARG}" ;;
            \?)
                echo "unexpected argument found $1"
                exit 1 ;;
            esac
    done


    if [[ "$definition" == 1 ]] then
        echo "file type is ${file_type}" 
        case $file_type in
            'py')
                prefix='(def|class) ' ;;
            'lkml')
                prefix='(dimension|explore).*? ' ;;
            *)
        esac
        
        pattern="${prefix}${pattern}" 
    fi
    
    local lines=$(rg --column $pattern -g!"*test*" | awk '!/^$/')
        
    if [ "$lines" = "" ]; then
      return 1
    elif [ $(wc -l <<< "$lines") -eq 1 ]; then
        location=$(echo "$lines" | rg -o '^[^:]+:\d+')
        nvim "$location"
    else
        file=$(echo "$lines" | fzf --reverse | rg -o '^[^:]+:\d+')
        
        if [ ! -z ${file} ]
        then
            echo opening $file
            nvim ${file} 
        fi
    fi

}


_get_default_file_type() {
    
    echo $(fd . -t f | rg '.*\.(\S+)$' -r '$1' | sort | uniq -c | sort -r | awk 'NR==1{print $2}')
}

export FZF_FUNCTIONS_SET=1
