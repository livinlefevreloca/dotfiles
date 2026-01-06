echo "Sourcing tmux module"

export FLOAX=$HOME/.tmux/plugins/tmux-floax/scripts/floax.sh

floax () {
  $FLOAX $@
}

t () {
  tmux new-session -d $@
}


if [[ -n "$TMUX" ]]; then
    export RPROMPT=''
fi

if [[ -n "$TMUX" ]]; then
    export RPROMPT=''
fi
