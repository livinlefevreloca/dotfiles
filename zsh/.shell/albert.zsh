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
			('-p' | '--pull') PULL='--no-pull'
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
	export database=$(echo "$cluster" | cut -d'-' -f2)

  db=$database

  if [[ $database == 'main16' ]]
  then
      database='main'
  elif [[ $database == 'investing16' ]]
  then
      database='investing'
  elif [[ $database == 'transactionsmap16' ]]
  then
      database='transactionsmap'
  fi

	export AWS_PROFILE=staging-devops
	username=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_username" --profile staging-devops | jq -r ".SecretString")
	password=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_password" --profile staging-devops | jq -r ".SecretString")
	host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" --profile staging-devops | jq -r '.DBClusters[0].Endpoint')
	psql "postgres://${username}:${password}@${host}:5432/${database}" $@
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
		shift
	fi
	export database=$(echo "$cluster" | cut -d'-' -f2)

  db=$database

  if [[ $database == 'main16' ]]
  then
      database='main'
  elif [[ $database == 'investing16' ]]
  then
      database='investing'
  elif [[ $database == 'transactionsmap16' ]]
  then
      database='transactionsmap'
  fi

	export AWS_PROFILE=staging-devops
	username=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_username" --profile staging-devops | jq -r ".SecretString")
	password=$(aws secretsmanager get-secret-value --secret-id "rds/staging/${db}/master_password" --profile staging-devops | jq -r ".SecretString")
	host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" --profile staging-devops | jq -r '.DBClusters[0].Endpoint')
	echo "postgres://${username}:${password}@${host}:5432/${database}"
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

prod_dsn () {
        USE_WRITER=0
        INSTANCE=0
        while [[ "$#" -gt 1 ]]
        do
          case "$1" in
            ('-w' | '--writer') USE_WRITER=1
              shift ;;
            ('-i' | '--instance') INSTANCE=$2
              shift; shift ;;
            (*) echo "unexpected argument found ${1} ... exiting"
              exit(1) ;;
          esac
        done

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

        if [[ $USE_WRITER == 1 ]];
        then
          echo
          echo -n "**WARNING** YOU ARE ATTACHING TO THE WRITER INSTANCE OF THE ${cluster} CLUSTER. CONTINUE? (yes/no) "
          read -r confirm
          if [[ $confirm != 'yes' ]]
          then
            return 0
          fi
        fi


        export AWS_PROFILE=prod-devops
        username=$(aws secretsmanager get-secret-value --secret-id "rds/production/${db}/master_username" --profile $AWS_PROFILE | jq -r ".SecretString")
        password=$(aws secretsmanager get-secret-value --secret-id "rds/production/${db}/master_password" --profile $AWS_PROFILE | jq -r ".SecretString")
        if [[ $USE_WRITER == 1 ]];
        then
          host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" --profile $AWS_PROFILE | jq -r '.DBClusters[0].Endpoint')
        elif [[ $INSTANCE != 0 ]];
        then
          member=$(aws rds describe-db-clusters --profile prod-devops --db-cluster-identifier "$cluster" | jq -r '.DBClusters[0].DBClusterMembers' | jq '.[] | select(.DBInstanceIdentifier |endswith("'"$INSTANCE"'"))')
          if [[ -z "$member" ]];
          then
            echo "No instance matching $INSTANCE found in cluster $cluster"
            return 1
          fi
          if [[ $(echo $member | jq -r '.IsClusterWriter') == 'true' ]];
          then
            echo
            echo -n "**WARNING** YOU ARE ATTACHING TO THE WRITER INSTANCE OF THE ${cluster} CLUSTER. CONTINUE? (yes/no) "
            read -r confirm
            if [[ $confirm != 'yes' ]]
            then
              return 0
            fi
          fi
          host="$(echo $member | jq -r '.DBInstanceIdentifier').c2cdgqnf2abq.us-west-2.rds.amazonaws.com"
        else
          host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" --profile $AWS_PROFILE | jq -r '.DBClusters[0].ReaderEndpoint')
        fi
        echo "postgres://${username}:${password}@${host}:5432/${db}"
}

prod_psql () {
        USE_WRITER=0
        INSTANCE=0
        while [[ "$#" -gt 1 ]]
        do
          case "$1" in
            ('-w' | '--writer') USE_WRITER=1
              shift ;;
            ('-i' | '--instance') INSTANCE=$2
              shift; shift ;;
            (*) echo "unexpected argument found ${1} ... exiting"
              exit(1) ;;
          esac
        done

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

        if [[ $USE_WRITER == 1 ]];
        then
          echo
          echo -n "**WARNING** YOU ARE ATTACHING TO THE WRITER INSTANCE OF THE ${cluster} CLUSTER. CONTINUE? (yes/no) "
          read -r confirm
          if [[ $confirm != 'yes' ]]
          then
            return 0
          fi
        fi


        export AWS_PROFILE=prod-devops
        username=$(aws secretsmanager get-secret-value --secret-id "rds/production/${db}/master_username" --profile $AWS_PROFILE | jq -r ".SecretString")
        password=$(aws secretsmanager get-secret-value --secret-id "rds/production/${db}/master_password" --profile $AWS_PROFILE | jq -r ".SecretString")
        if [[ $USE_WRITER == 1 ]];
        then
          host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" --profile $AWS_PROFILE | jq -r '.DBClusters[0].Endpoint')
        elif [[ $INSTANCE != 0 ]];
        then
          member=$(aws rds describe-db-clusters --profile prod-devops --db-cluster-identifier "$cluster" | jq -r '.DBClusters[0].DBClusterMembers' | jq '.[] | select(.DBInstanceIdentifier |endswith("'"$INSTANCE"'"))')
          if [[ -z "$member" ]];
          then
            echo "No instance matching $INSTANCE found in cluster $cluster"
            return 1
          fi
          if [[ $(echo $member | jq -r '.IsClusterWriter') == 'true' ]];
          then
            echo
            echo -n "**WARNING** YOU ARE ATTACHING TO THE WRITER INSTANCE OF THE ${cluster} CLUSTER. CONTINUE? (yes/no) "
            read -r confirm
            if [[ $confirm != 'yes' ]]
            then
              return 0
            fi
          fi
          host="$(echo $member | jq -r '.DBInstanceIdentifier').c2cdgqnf2abq.us-west-2.rds.amazonaws.com"
        else
          host=$(aws rds describe-db-clusters --db-cluster-identifier "$cluster" --profile $AWS_PROFILE | jq -r '.DBClusters[0].ReaderEndpoint')
        fi
        echo "connecting to host ${host} as user: ${username}"
        echo
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
	PGPASSWORD=$(aws redshift get-cluster-credentials --db-user $user --db-name "$db" --cluster-identifier albert-production-data-warehouse --profile prod | jq '.DbPassword' | tr -d '"' | tr -d '\n') PSQL_HISTORY=$HOME/.psql_history_12 /opt/homebrew/Cellar/postgresql@12/12.22_1/bin/psql "host=10.161.21.44 port=5439 user=IAM:${user} dbname=${db} sslmode=verify-ca sslrootcert=${HOME}/.redshift/redshift-ca-bundle.crt" $@
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

staging_pgb_admin() {
  pod=$(kubectl get pods -n pgbouncer --context staging-us-west-2-eks-4 -l "albert.com/db=${1},albert.com/context=${2},albert.com/workload-type=pgbouncer-ha" -o json | jq -r '.items[] | .metadata.name' | fzf)
  kubectl exec -c pgbouncer -n pgbouncer --context staging-us-west-2-eks-4 -it $pod -- sh -c 'psql postgres://${AURORA_DB_USER__MASTER}:${AURORA_DB_PASSWORD__MASTER}@localhost:6432/pgbouncer'
}


staging_pgb_admin_pf() {
  if [[ "$3" == '-r' ]]; then
    pod=$(kubectl get pods -n pgbouncer --context staging-us-west-2-eks-4 -l "albert.com/db=${1},albert.com/context=${2},albert.com/workload-type=pgbouncer-ha" -o json | jq -r '.items[0] | .metadata.name')
    shift
    shift
    shift
  else
    pod=$(kubectl get pods -n pgbouncer --context staging-us-west-2-eks-4 -l "albert.com/db=${1},albert.com/context=${2},albert.com/workload-type=pgbouncer-ha" -o json | jq -r '.items[] | .metadata.name' | fzf)
    shift
    shift
  fi
  kubectl port-forward -n pgbouncer --context staging-us-west-2-eks-4 $pod 6432:6432 &> /dev/null &
  pf_pid=$!
  dsn=$(kubectl exec -c pgbouncer -n pgbouncer --context staging-us-west-2-eks-4 -it $pod -- sh -c 'echo -n postgres://${AURORA_DB_USER__MASTER}:${AURORA_DB_PASSWORD__MASTER}')"@localhost:6432/pgbouncer"
  psql $dsn $@
  kill $pf_pid
}

al () {
	local all
	local root
	local apath
	while getopts "r" opt
	do
		case $opt in
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
  places=$(fd . -td -d1 ${ALBERT_PROJECTS} | awk -F '/' '{print $(NF-1)}'| rg $apath)
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

# Find the hash image tag for a given ecr repo
find_branch_image() {
  tag=$(aws ecr list-images --repository-name $1 \
    --registry-id 538001969475 \
    --filter tagStatus=TAGGED \
    --max-items 10000 \
    --profile devops \
    | jq -r '
        .imageIds
        | sort_by(.imageDigest)
        | group_by(.imageDigest)[]
        | select(any(.imageTag | test("'$2'.*amd64")))[]
        | select(.imageTag | contains("hash")).imageTag
      ' \
  )
  echo -n $tag | y
  echo "Copied image tag: $tag to clipboard"
}


# reset and activate the default python virtual environment
deact && activate "$DEFAULT_VENV"

export ALBERT_FUNCTIONS_SET=1

# remove shim created by pyenv
rm /Users/adam/.pyenv/shims/albert &> /dev/null
