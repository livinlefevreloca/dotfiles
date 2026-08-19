echo "Sourcing notes module"
export NOTES_DIR="${ALBERT_PROJECTS}notes"

notes() {

  local filename="${NOTES_DIR}/$(date +%Y-%m-%d).md"

  if [[ ! -f $filename ]]; then
    echo "# Notes `date +%Y-%m-%d`" > $filename
  fi

  lvim $filename
}

export NOTES_FUNCTIONS_SET=1
