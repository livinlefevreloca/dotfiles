echo "Sourcing albert module"

export ALBERT_PROJECTS="/Users/$USER/Projects/albert/"
export ALBERT_ROOT="/Users/$USER/Projects/albert/albert-main/"
export LOOKER_DIR="${ALBERT_PROJECTS}looker"
export AWS_DEFAULT_PROFILE=dev-engineer
export DEFAULT_VENV=albert

#
# Run the replication codegen locally via rde runlocal
#
codegen () {
	local SERVICE="$1"
	shift
	declare GENERATE PULL CONFIG
	while [[ "$#" -ge 1 ]]
	do
		case "$1" in
			('-p' | '--pull') PULL='--pull'
				shift ;;
			('-c' | '--mount-common') COMMON='--mount-common'
				shift ;;
			('-o' | '--config-only') CONFIG='--config-only'
				shift ;;
			(*) echo "unexpected argument found ${1} ... exiting"
				exit(1) ;;
		esac
	done
	if ! aws s3 ls --profile dev-engineer > /dev/null
	then
		login dev-engineer
	fi
	if [[ "$SERVICE" == 'auth' ]]
	then
		APP_SERVICE='authentication'
	else
		APP_SERVICE="$SERVICE"
	fi
	if [[ $(albert dev telepresence-status | rg "User Daemon" | awk -F ':' 'gsub(/^[ \t]+/, "", $0); {print $2}') == 'Not running' ]]
	then
		albert dev telepresence-connect
	fi
	albert dev runlocal -s "$SERVICE" -v "${ALBERT_PROJECTS}looker":/looker,"${ALBERT_PROJECTS}albert-dbt-analytics-transforms":/albert-dbt-analytics-transforms "$PULL" "$COMMON" -e DBT_REPO_PATH='/albert-dbt-analytics-transforms' -e LOOKER_REPO_PATH='/looker' --no-pull -- python manage.py generate_replication_code "$APP_SERVICE" "$CONFIG"
}

#
# Select a cluster from staging with fzf
#
function _select_cluster() {
    echo $(aws rds describe-db-clusters | jq -r '.DBClusters[] | .DBClusterIdentifier' | grep -E '^db' | fzf)
}


#
# Connect to a given staging database instance via psql. Pull the credentials from AWS Secrets Manager
#
staging_psql () {
	if [[ -z "$1" ]]
	then
		cluster=$(_select_cluster)
	else
		export cluster="$1"
		shift
	fi
	export db=$(echo "$cluster" | cut -d'-' -f2)
	export AWS_PROFILE=staging-devops
	username=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_username" --profile staging-devops | jq -r ".SecretString")
	password=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_password" --profile staging-devops | jq -r ".SecretString")
	host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" --profile staging-devops | jq -r '.DBClusters[0].Endpoint')
	pgcli "postgres://${username}:${password}@${host}:5432/${db}" $@
}

#
# Echo the DSN for a given staging database instance. Pull the credentials from AWS Secrets Manager
#
staging_dsn () {
	if [[ -z "$1" ]]
	then
		cluster=$(_select_cluster)
	else
		export cluster="$1"
	fi
	export db=$(echo "$cluster" | cut -d'-' -f2)
	export AWS_PROFILE=staging-devops
	username=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_username" --profile staging-devops | jq -r ".SecretString")
	password=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_password" --profile staging-devops | jq -r ".SecretString")
	host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" --profile staging-devops | jq -r '.DBClusters[0].Endpoint')
	echo "postgres://${username}:${password}@${host}:5432/${db}"
}

#
# Connect to Production Redshift via the redshift_data_api_user using the get-cluster-credentials api
#
redshift-prod-psql () {
	local db
	local user
	while getopts "s" opt
	do
		case $opt in
			(s) user="guteqqidwjrb"  ;;
		esac
	done
	shift $((OPTIND -1))
	if [[ -z "$1" ]]
	then
		echo "Please provide a database name"
		return 1
	fi
	db="$1"
	if [[ -z "$user" ]]
	then
		user="redshift_data_api_user"
	fi
	echo $db
	echo $user
	PGPASSWORD=$(aws redshift get-cluster-credentials --db-user $user --db-name "$db" --cluster-identifier albert-production-data-warehouse --profile prod | jq '.DbPassword' | tr -d '"' | tr -d '\n') /opt/homebrew/Cellar/postgresql@11/11.22_1/bin/psql "host=10.161.21.44 port=5439 user=IAM:${user} dbname=${db} sslmode=verify-ca sslrootcert=${HOME}/.redshift/redshift-ca-bundle.crt" $@
}

#
# Login in the aws sso and change the default profile to the supplied value
#
login () {
	if [[ ! -n "$1" ]]
	then
		profile=$(cat ~/.aws/config | rg -o '\[profile (\S+)\]' -r '$1' | fzf)
	fi
	AWS_DEFAULT_PROFILE="$profile"
	aws sso login
}

#
# Open a Looker explore from the command line
#
looker () {
	local model="$1"
	local explore="$2"
	if [[ ! -n "$model" ]]
	then
		model=$(ls "${LOOKER_DIR}/tables/" | fzf)
	fi
	if [[ ! -n "$explore" ]]
	then
		explore=$(ls "${LOOKER_DIR}/tables/${model}/" | cut -d'.' -f1 | fzf)
	fi
	open "https://albert.cloud.looker.com/explore/${model}/${explore}"
}

backup_rde_dbs () {
	while getopts "n:d:" opt
	do
		case $opt in
			(n) namespace="$OPTARG"  ;;
			(d) dbs="$OPTARG"  ;;
		esac
	done
	local service
	albert dev route-rde -n $namespace
	backup_dir="/tmp/$(date +'%Y-%m-%d-%H-%M-%S')"
	mkdir -p $backup_dir
	for db in $(echo $dbs | sed 's/,/ /g')
	do
		if [[ "$db" == 'lyfe' ]]
		then
			service='main'
		else
			service="$db"
		fi
		echo "Backing up $db from $service"
		pg_dump -v "postgres://postgres:postgres@${service}-postgres.${namespace}:5432/${db}" > "${backup_dir}/${db}.sql"
	done
}

al () {
	local all
	local root
	local apath
	while getopts "ar" opt
	do
		case $opt in
			(a) all=1  ;;
			(r) root=1  ;;
		esac
	done
	shift $((OPTIND -1))
	if [[ $# -gt 0 ]]
	then
		apath="$1"
	else
		apath="."
	fi
	if [[ $root -eq 1 ]]
	then
		echo "cd to $ALBERT_PROJECTS"
		cd $ALBERT_PROJECTS
		return
	fi
	if [[ $all -eq 1 ]]
	then
		places=$(ls -D ${ALBERT_PROJECTS} | rg $apath)
		if [[ -z ${places} ]]
		then
			echo "No projects found"
			return
		fi
		if [[ $(echo $places | wc -l) -gt 1 ]]
		then
			cd "${ALBERT_PROJECTS}$(echo $places | fzf)"
		else
			echo "cd to ${ALBERT_PROJECTS}$(echo $places)"
			cd "${ALBERT_PROJECTS}$(echo $places)"
		fi
		return
	else
		places=$(ls -D ${ALBERT_PROJECTS} | rg albert- | rg $apath)
		if [[ -z ${places} ]]
		then
			echo "No projects found"
			return
		fi
		if [[ $(echo $places | wc -l) -gt 1 ]]
		then
			cd "${ALBERT_PROJECTS}$(echo $places | fzf)"
		else
			echo "cd to ${ALBERT_PROJECTS}$(echo $places)"
			cd "${ALBERT_PROJECTS}$(echo $places)"
		fi
		return
	fi
}

restore_rde_db () {
	while getopts "n:b:" opt
	do
		case $opt in
			(n) namespace="$OPTARG"  ;;
			(b) backup_file="$OPTARG"  ;;
		esac
	done
	local service
	local base_url
	albert dev route-rde -n $namespace
	db=$(basename $backup_file | sed 's/.sql//')
	if [[ "$db" == 'lyfe' ]]
	then
		service='main'
	else
		service="$db"
	fi
	base_url="postgres://postgres:postgres@${service}-postgres.${namespace}:5432"
	echo "Restoring $db for $service"
	psql "${base_url}/postgres" -c "select pg_terminate_backend(pid) from pg_stat_activity where datname = '${db}'"
	psql "${base_url}/postgres" -c "drop database ${db}"
	psql "${base_url}/postgres" -c "create database ${db}"
	psql "${base_url}/${db}" < ${backup_file}
}


# reset and activate the default python virtual environment
deact && activate "$DEFAULT_VENV"

# Start in the albert projects directory
cd "$ALBERT_PROJECTS"

export ALBERT_FUNCTIONS_SET=1


