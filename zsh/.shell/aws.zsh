echo "Sourcing aws module"

function s3du(){
  bucket=`cut -d/ -f3 <<< $1`
  prefix=`awk -F/ '{for (i=4; i<NF; i++) printf $i"/"; print $NF}' <<< $1`
  aws s3api \
    list-objects \
    --bucket $bucket \
    --prefix=$prefix \
    --output text \
    --query '[sum(Contents[].Size), length(Contents[])]' \
    | while read -r size num_objects; do
      jq '. |{ size:.[0],num_objects: .[1]}' <<< "[\"$(numfmt --to=si ${size})\",${num_objects}]"
     done
}

function redshift-prod-psql(){
    local db="${1}"
    PGPASSWORD=$(aws redshift get-cluster-credentials --db-user redshift_data_api_user --db-name ${db} --cluster-identifier albert-production-data-warehouse --profile production | jq '.DbPassword' | tr -d '"' | tr -d '\n') \
    psql "host=10.161.21.44 port=5439 user=IAM:redshift_data_api_user dbname=${db} sslmode=verify-ca sslrootcert=${HOME}/.redshift/redshift-ca-bundle.crt"
}

change_profile () {
    if [[ ! -n "${1}" ]]
    then
        export AWS_DEFAULT_PROFILE=$(cat ~/.aws/config | rg -o '\[profile (\S+)\]' -r '$1' | fzf)
    else
        export AWS_DEFAULT_PROFILE=${1}
    fi
}

login() {
    if [[ ! -n "$1" ]] then
        aws sso login --profile $(cat ~/.aws/config | rg -o '\[profile (\S+)\]' -r '$1' | fzf)
    elif [[ "$1" == '-d' || "$1" == '--default' ]] then
        aws sso login --profile "${AWS_DEFAULT_PROFILE}"
    elif [[ "$1" == '--all' || "$1" == '-a' ]] then
        aws sso login --profile production
        aws sso login --profile dev-engineer
        aws sso login --profile devops
        aws sso login --profile staging
        aws sso login --profile staging-devops
    else
        aws sso login --profile "$1"
    fi
}

AWS_DEFAULT_PROFILE='dev-engineer'
export AWS_FUNCTIONS_SET=1
