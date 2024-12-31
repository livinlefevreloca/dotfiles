echo "Sourcing aws module"

#
# Calculate the size in Mb of the given s3 prefix
#
s3du () {
	if [[ ! -n "$1" ]]
	then
		echo "Usage: s3du s3://bucket/prefix [--profile profile_name]"
		return 1
	fi
	s3path="$1"
	if [[ "$2" == "--profile" ]] && [[ -n "$3" ]]
	then
		profile="$3"
	else
		profile="$AWS_PROFILE"
	fi
	if [[ -z "$profile" ]]
	then
		echo "No profile specified"
		return 1
	fi
	bucket=$(cut -d/ -f3 <<< "$s3path")
	prefix=$(awk -F/ '{for (i=4; i<NF; i++) printf $i"/"; print $NF}')  <<< "$s3path"
	aws s3api list-objects --bucket "$bucket" --prefix="$prefix" --output text --query '[sum(Contents[].Size), length(Contents[])]' --profile "$profile" | while read -r size num_objects
	do
		jq '. |{ size:.[0],num_objects: .[1]}' <<< "[\"$(numfmt --to=si ${size})\",${num_objects}]"
	done
}

#
# Change the currently active aws profile
#
change_profile () {
	if [[ ! -n "$1" ]]
	then
		export AWS_PROFILE=$(cat ~/.aws/config | rg -o '\[profile (\S+)\]' -r '$1' | fzf)
	else
		export AWS_PROFILE="$1"
	fi
}

AWS_PROFILE='dev-engineer'
export AWS_FUNCTIONS_SET=1

