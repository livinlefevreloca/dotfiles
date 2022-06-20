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
    aws redshift get-cluster-credentials --db-user redshift_data_api_user --db-name albert_data_lake --cluster-identifier albert-production-data-warehouse --profile production | jq '.DbPassword' | tr -d '"' | tr -d '\n' | pbcopy
    psql "host=10.161.21.44 port=5439 user=IAM:redshift_data_api_user dbname=albert_data_lake sslmode=verify-ca sslrootcert=${HOME}/.redshift/redshift-ca-bundle.crt"
}

change_profile () {
    export AWS_DEFAULT_PROFILE=${1}
}

login() {
    if [[ -n "$1" ]] then
        aws sso login --profile "$1"
        return
    fi
    aws sso login --profile production
    aws sso login --profile dev-engineer
    aws sso login --profile devops
}

AWS_DEFAULT_PROFILE='dev-engineer'
export AWS_FUNCTIONS_SET=1
