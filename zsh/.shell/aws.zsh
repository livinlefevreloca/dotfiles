echo "Sourcing aws module"

#
# Calculate the size in Mb of the given s3 prefix
#
function s3du(){
    bucket=$(cut -d/ -f3 <<< "$1")
    prefix=$(awk -F/ '{for (i=4; i<NF; i++) printf $i"/"; print $NF}' <<< $1
    aws s3api \
        list-objects \
        --bucket "$bucket" \
        --prefix="$prefix" \
        --output text \
        --query '[sum(Contents[].Size), length(Contents[])]' \
        | while read -r size num_objects; do
            jq '. |{ size:.[0],num_objects: .[1]}' <<< "[\"$(numfmt --to=si ${size})\",${num_objects}]"
        done
}

#
# Change the currently active aws profile
#
change_profile () {
    if [[ ! -n "$1" ]]
    then
        export AWS_DEFAULT_PROFILE=$(cat ~/.aws/config | rg -o '\[profile (\S+)\]' -r '$1' | fzf)
    else
        export AWS_DEFAULT_PROFILE="$1"
    fi
}

AWS_DEFAULT_PROFILE='dev-engineer'
export AWS_FUNCTIONS_SET=1

