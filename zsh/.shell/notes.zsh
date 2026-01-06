echo "Sourcing notes module"
export NOTES_DIR="$ALBERT_PROJECTS/claude-notes/"

new_note () {
  local note_title="$1"
  local note_file="$NOTES_DIR/$(date +%Y-%m-%d).md"
  touch "$note_file"
  echo "## $note_title" >> "$note_file"
  lvim "$note_file"

}

open_notes () {
  lvim "$NOTES_DIR/$(date +%Y-%m-%d).md"
}

search_notes () {
	local search_term="$1"
	files=$(rg -n "$search_term" "$NOTES_DIR" | fzf)
	if [[ -n "$files" ]]
	then
		file=$(echo "$files" | cut -d ":" -f 1)
		line_num=$(echo "$files" | cut -d ":" -f 2)
		nvim +:"$line_num" "$file"
	fi
}

export NOTES_FUNCTIONS_SET=1
