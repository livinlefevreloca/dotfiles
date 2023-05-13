echo "Sourcing terraform module"

if [[ "$path" != *"tfenv"* ]]
then
    export PATH="$HOME/.tfenv/bin:$PATH"
fi

export TERRAFORM_FUNCTIONS_SET=1
