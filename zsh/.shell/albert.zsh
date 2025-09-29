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
	albert dev runlocal -s "$SERVICE" -v "${ALBERT_PROJECTS}looker":/looker,"${ALBERT_PROJECTS}albert-dbt-analytics-transforms":/albert-dbt-analytics-transforms "$PULL" "$COMMON" -e DBT_REPO_PATH='/albert-dbt-analytics-transforms' -e LOOKER_REPO_PATH='/looker' -- python manage.py generate_replication_code "$APP_SERVICE" "$CONFIG"
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

    if [[ $db == 'main16' ]]
    then
        db='main'
    elif [[ $db == 'investing16' ]]
    then
        db='investing'
    elif [[ $db == 'transactionsmap16' ]]
    then
        db='transactionsmap'
    fi

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

    if [[ $db == 'main16' ]]
    then
        db='main'
    elif [[ $db == 'investing16' ]]
    then
        db='investing'
    elif [[ $db == 'transactionsmap16' ]]
    then
        db='transactionsmap'
    fi

	export AWS_PROFILE=staging-devops
	username=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_username" --profile staging-devops | jq -r ".SecretString")
	password=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_password" --profile staging-devops | jq -r ".SecretString")
	host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" --profile staging-devops | jq -r '.DBClusters[0].Endpoint')
	echo "postgres://${username}:${password}@${host}:5432/${db}"
}


#
# Connect to a given testex database instance via psql. Pull the credentials from AWS Secrets Manager
#
testex_psql () {
        if [[ -z "$1" ]]
        then
                cluster=$(_select_cluster)
        else
                export cluster="$1"
                shift
        fi
        export db=$(echo "$cluster" | cut -d'-' -f2)
        if [[ $db == 'main16' ]]
        then
                db='main'
        elif [[ $db == 'investing16' ]]
        then
                db='investing'
        elif [[ $db == 'transactionsmap16' ]]
        then
                db='transactionsmap'
        fi
        export AWS_PROFILE=testex-devops
        username=$(aws secretsmanager get-secret-value --secret-id "rds/test-ex/${db}/master_username" --profile $AWS_PROFILE | jq -r ".SecretString")
        password=$(aws secretsmanager get-secret-value --secret-id "rds/test-ex/${db}/master_password" --profile $AWS_PROFILE | jq -r ".SecretString")
        host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" --profile $AWS_PROFILE | jq -r '.DBClusters[0].Endpoint')
        psql -X "postgres://${username}:${password}@${host}:5432/${db}" $@
}

#
# Connect to Production Redshift via the redshift_data_api_user using the get-cluster-credentials api
#
redshift-prod-psql () {
	local db
	local user
    local quiet=0
	while getopts "sq" opt
	do
		case $opt in
			s) user="guteqqidwjrb"  ;;
            q)   quiet=1;;
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
    if [[ $quiet != 1 ]]
    then
        echo $db
        echo $user
    fi
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
		places=$(ls ${ALBERT_PROJECTS} | rg $apath)
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
		places=$(ls ${ALBERT_PROJECTS} | rg albert- | rg $apath)
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


pi_monitor() {
    if ! pip freeze | rg -q termgraph
    then
        echo "Installing termgraph for visualizing the PI metrics"
        pip install termgraph
    fi

    cluster="$1"
    if [[ "$cluster" =~ '.*production' ]]
    then
        profile='prod-devops'
    elif [[ "$cluster" =~ '.*staging' ]]
    then
        profile='staging-devops'
    else
        echo "Cluster $cluster is not a production or staging cluster."
        return 1
    fi
    echo "Using profile: $profile"
    writer_instance=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" --profile "$profile" | jq -r '.DBClusters[0].DBClusterMembers[] | select(.IsClusterWriter).DBInstanceIdentifier')
    pi_identifier=$(aws rds describe-db-instances --db-instance-identifier "$writer_instance" --profile "$profile" | jq -r '.DBInstances[0].DbiResourceId')

    jq_script='
      # keep only dimensioned metrics (exclude the total)
      (.MetricList | map(select(.Key.Dimensions?))) as $ml
      |
      # header: "@" prefix + Timestamp + each wait_event.name
      ("@ " + (($ml | map(.Key.Dimensions["db.wait_event.name"])) | join(","))),
      # rows: align by index across DataPoints
      ( [range(0; ($ml[0].DataPoints | length))] | .[] as $i
        | [ $ml[0].DataPoints[$i].Timestamp ] + ($ml | map(.DataPoints[$i].Value))
        | @csv
      )
    '

    clear
    while true;
    do
        aws pi get-resource-metrics --service-type RDS \
            --identifier $pi_identifier \
            --metric-queries '{"Metric":"db.load.avg","GroupBy":{"Group":"db.wait_event","Limit":6}}' \
            --start-time $(date -v -300S +%Y-%m-%d\T%H:%M:%S) \
            --end-time $(date +%Y-%m-%d\T%H:%M:%S) \
            --period-in-seconds 60 \
            --profile "$profile" > /tmp/pi_monitor_output.json
        jq -r "$jq_script" /tmp/pi_monitor_output.json | termgraph --stacked --color {red,blue,green,magenta,yellow,black} --title "PI Monitor for $cluster" --width 40
        sleep 10
        clear
    done
}


# reset and activate the default python virtual environment
deact && activate "$DEFAULT_VENV"

# Start in the albert projects directory
cd "$ALBERT_PROJECTS"

export ALBERT_FUNCTIONS_SET=1

# remove shim created by pyenv
rm /Users/adam/.pyenv/shims/albert

