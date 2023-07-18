echo "Sourcing notes module"
export NOTES_DIR="$HOME/Documents/notes"

if [ ! -d "$NOTES_DIR" ]; then
    mkdir -p "$NOTES_DIR"
fi

function notes() {
    local date
    local file_path
    local lines
    local headerline
    local headerline_file
    local headerline_num
    local header

    while getopts "cd::" opt; do
        case $opt in
            c)
                file_path=$(ls -d $NOTES_DIR/* | fzf --tac --preview='less {}' --bind shift-up:preview-page-up,shift-down:preview-page-down)
                if [[ -z "$file_path" ]]; then
                    return 1
                fi
                ;;
            d)
                date="$OPTARG"
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                ;;
        esac
    done

    if [ ! -n "$date" ]; then
        date=$(date +%Y-%m-%d)
    fi

    if [ ! -n "$file_path" ]; then
        file_path="${NOTES_DIR}/${date}.md"
    fi

    if [ ! -f "$file_path" ]; then
        echo "Creating new notes file"
        touch "$file_path"
        echo "# Notes for $date" >> "$file_path"
        lines=$(rg --line-number '@remind' "$NOTES_DIR")
        IFS=$'\n'
        for headerline in ${=lines}; do
            headerline_file=$(echo "$headerline" | cut -d ":" -f 1)
            headerline_num=$(echo "$headerline" | cut -d ":" -f 2)
            header=$(echo "$headerline" | cut -d ":" -f 3)
            content=$(rg --pcre2 --multiline --multiline-dotall --only-matching --no-line-number "${header}.*?(^##|\Z)" "$headerline_file" | rg -v '^##')
            cleaned_header=$(echo $header | sed 's/## //' | sed 's/ @remind//')
            read "?Would you like to carry over the reminder for ${cleaned_header}? [y/n] " response

            if [[ $response == 'y' ]]
            then
                echo "Adding reminder for $cleaned_header"
                echo "" >> "$file_path"
                echo $header >> "$file_path"
                echo '[continued from]('"${headerline_file}:${headerline_num}"')' >> "$file_path"
                echo "" >> "$file_path"
                echo "$content" >> "$file_path"
            else
                echo "removing reminder for $header"
            fi
            unset response
            cat $headerline_file | sed "${headerline_num}s/ @remind//" > /tmp/tmp
            mv /tmp/tmp $headerline_file
        done


        nvim "$file_path"
    else
        nvim "$file_path"
    fi
    IFS=' '
}


function cont_note() {
    local header="$1"
    local date
    local from_file_path
    local to_file_path
    local details
    local header_line
    local header_line_num

    if [[ ! -n "$header" ]]; then
        echo "Must provide a header"
        return 1
    fi

    while getopts "cd:" opt; do
        case $opt in
            c)
                date=$(ls -d $NOTES_DIR/* | fzf --preview='less {}' --bind shift-up:preview-page-up,shift-down:preview-page-down | cut -d "/" -f 5 | cut -d "." -f 1)
                ;;
            d)
                date="$OPTARG"
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                ;;
        esac
    done

    if [[ ! -n "$date" ]]; then
        from_file_path="${NOTES_DIR}"
    else
        from_file_path="${NOTES_DIR}/${date}.md"
    fi

    to_file_path="${NOTES_DIR}/$(date +%Y-%m-%d).md"

    if [[ "$from_file_path" != "$NOTES_DIR" && ! -f "$from_file_path" ]]; then
        echo "No file found for date: $from_file_path"
        return 1
    fi

    if [[ ! -f "$to_file_path" ]]; then
        touch "$to_file_path"
        echo "# Notes for $(date +%Y-%m-%d)" >> "$to_file_path"
    fi

    headerline=$(rg -n "#+ .*$header" "$from_file_path" | fzf -0 -1 )

    if [[ "$from_file_path" == "$NOTES_DIR" ]]; then
        headerline_file=$(echo "$details" | cut -d ":" -f 1)
        headerline_num=$(echo "$details" | cut -d ":" -f 2)
        header=$(echo "$details" | cut -d ":" -f 3-)
    else
        headerline_num=$(echo "$details" | cut -d ":" -f 2)
        header=$(echo "$details" | cut -d ":" -f 3-)
    fi

    if [[ ! -n "$header" ]]; then
        echo "No results found for: $header"
        return 1
    fi
    local cont_line='[continued from]('"${from_file_path}:${headerline_num}"')'

    echo "" >> "$headerline_file"
    echo "${header}\n${cont_line}" >> "$to_file_path"
    echo "Successfuly Added notes Continuation!"
}


function search_notes() {
    local search_term="$1"
    files=$(rg -n "$search_term" "$NOTES_DIR" | fzf)
    if [[ -n "$files" ]]; then
        file=$(echo "$files" | cut -d ":" -f 1)
        line_num=$(echo "$files" | cut -d ":" -f 2)
        nvim +:"$line_num" "$file"
    fi
}

export NOTES_FUNCTIONS_SET=1
