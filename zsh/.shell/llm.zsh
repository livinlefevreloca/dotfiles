echo "Sourcing llm module"

alias claude='claude --append-system-prompt "$(cat $HOME/.claude/Claude.md)"'
