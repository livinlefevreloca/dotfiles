echo "Sourcing albert module"

export ALBERT_PROJECTS=/Users/$USER/Projects/albert/
export ALBERT_ROOT=/Users/$USER/Projects/albert/albert-main/
export GITHUB_TOKEN=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
export AWS_DEFAULT_PROFILE=dev-engineer
eval "$(_ALBERT_COMPLETE=source_zsh albert)"

reset && activate albert

cd "${ALBERT_PROJECTS}"

export ALBERT_FUNCTIONS_SET=1
