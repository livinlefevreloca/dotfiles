echo "Sourcing albert module"

export ALBERT_PROJECTS="/Users/$USER/Projects/albert/"
export ALBERT_ROOT="/Users/$USER/Projects/albert/albert-main/"
export GITHUB_TOKEN="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"
export AWS_DEFAULT_PROFILE=dev-engineer
export DEFAULT_VENV=albert

#
# Run the replication codegen locally via rde runlocal
#
function codegen() {

    local SERVICE="$1"
    shift
    declare GENERATE PULL CONFIG

    while [[ "$#" -ge 1 ]]; do
        case "$1" in
        '-p'|'--pull')
            PULL='--pull'
            shift ;;
        '-c'|'--mount-common')
            COMMON='--mount-common'
            shift ;;
        '-o'|'--config-only')
            CONFIG='--config-only'
            shift ;;
        *)
            echo "unexpected argument found ${1} ... exiting"
            exit(1) ;;
        esac
    done

    if ! aws s3 ls --profile dev-engineer > /dev/null
    then
        login dev-engineer
    fi

    if [[ "$SERVICE" == 'auth' ]];
    then
        APP_SERVICE='authentication'
    else
        APP_SERVICE="$SERVICE"
    fi

    if [[ $(albert dev telepresence-status | rg "User Daemon" | awk -F ':' 'gsub(/^[ \t]+/, "", $0); {print $2}') == 'Not running' ]]
    then
        albert dev telepresence-connect
    fi

    albert dev runlocal -s "$SERVICE" \
        -v "${ALBERT_PROJECTS}looker":/looker,"${ALBERT_PROJECTS}albert-dbt-analytics-transforms":/albert-dbt-analytics-transforms \
        "$PULL" \
        "$COMMON" \
        --no-pull \
        -- python manage.py generate_replication_code "$APP_SERVICE" "$CONFIG"
}

#
# Connect to a given staging database instance via psql. Pull the credentials from AWS Secrets Manager
#
function staging_psql() {
    export cluster="$1"
    shift
    export db=$(echo "$cluster" | cut -d'-' -f2)
    export AWS_PROFILE=staging-devops
    username=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_username" | jq -r ".SecretString")
    password=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_password" | jq -r ".SecretString")
    host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" | jq -r '.DBClusters[0].Endpoint')

    psql "postgres://${username}:${password}@${host}:5432/${db}" $@
}

#
# Echo the DSN for a given staging database instance. Pull the credentials from AWS Secrets Manager
#
function staging_dsn() {
    export cluster="$1"
    shift
    export db=$(echo "$cluster" | cut -d'-' -f2)
    export AWS_PROFILE=staging-devops
    username=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_username" | jq -r ".SecretString")
    password=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_password" | jq -r ".SecretString")
    host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" | jq -r '.DBClusters[0].Endpoint')

    echo "postgres://${username}:${password}@${host}:5432/${db}"
}

#
# Connect to Production Redshift via the redshift_data_api_user using the get-cluster-credentials api
#
function redshift-prod-psql(){
    local db="$1"
    shift;
    PGPASSWORD=$(aws redshift get-cluster-credentials --db-user redshift_data_api_user --db-name "$db" --cluster-identifier albert-production-data-warehouse --profile production | jq '.DbPassword' | tr -d '"' | tr -d '\n') \
    psql "host=10.161.21.44 port=5439 user=IAM:redshift_data_api_user dbname=${db} sslmode=verify-ca sslrootcert=${HOME}/.redshift/redshift-ca-bundle.crt" $@
}

#
# Login in the aws sso and change the default profile to the supplied value
#
login() {
    if [[ ! -n "$1" ]] then
        profile=$(cat ~/.aws/config | rg -o '\[profile (\S+)\]' -r '$1' | fzf)
    fi
    aws sso login
    AWS_DEFAULT_PROFILE="$profile"
}

# reset and activate the default python virtual environment
reset && activate "$DEFAULT_VENV"

# Start in the albert projects directory
cd "$ALBERT_PROJECTS"

export ALBERT_FUNCTIONS_SET=1
