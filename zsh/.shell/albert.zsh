echo "Sourcing albert module"

export ALBERT_PROJECTS="/Users/adam/Projects/albert/"
export ALBERT_ROOT="/Users/adam/Projects/albert/albert-main/"
export LOOKER_DIR="${ALBERT_PROJECTS}looker"
export AWS_DEFAULT_PROFILE=dev-engineer
export CRONITOR_CONFIG=~/.cronitor/cronitor.json

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
        export db=$(echo "$cluster" | cut -d'-' -f2 | rg -o '[a-z]+')

        export AWS_PROFILE=prod-devops
        secret_data=$(aws secretsmanager get-secret-value --secret-id "app_config/prod/rds/${db}" --profile $AWS_PROFILE | jq -r ".SecretString")
        username=$(echo $secret_data | jq -r '."role.master"')
        password=$(echo $secret_data | jq -r '."role.master.password"')
        database=$(echo $secret_data | jq -r '."aurora.database_name"')
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
        echo "postgres://${username}:${password}@${host}:5432/${database}"
}

prod_psql () {
        USE_WRITER=0
        INSTANCE=0
        READ_ONLY=1
        SKIP_CONFIRM=0
        while [[ "$#" -gt 0 ]]
        do
          case "$1" in
            ('-w' | '--writer') USE_WRITER=1
              shift ;;
            ('-s' | '--superuser') READ_ONLY=0
              shift ;;
            ('-y' | '--yes') SKIP_CONFIRM=1
              shift ;;
            ('-i' | '--instance') INSTANCE=$2
              shift 2 ;;
            ('--') shift; break ;;
            (-*) echo "unexpected option ${1} ... exiting"
              return 1 ;;
            (*) break ;;
          esac
        done

        if [[ -z "$1" ]]
        then
                cluster=$(_select_cluster)
        else
                export cluster="$1"
                shift
        fi
        export db=$(echo "$cluster" | cut -d'-' -f2 | rg -o '[a-z]+')
        if [[ $USE_WRITER == 1 && $READ_ONLY == 0 && $SKIP_CONFIRM == 0 ]];
        then
          echo
          echo -n "**WARNING** YOU ARE ATTACHING TO THE WRITER INSTANCE OF THE ${cluster} CLUSTER as super user. CONTINUE? (yes/no) "
          read -r confirm
          if [[ $confirm != 'yes' ]]
          then
            return 0
          fi
        fi

        if [[ $READ_ONLY == 1 ]];
        then
          export PGOPTIONS='-c default_transaction_read_only=on'
        fi


        export AWS_PROFILE=prod-devops
        secret_data=$(aws secretsmanager get-secret-value --secret-id "app_config/prod/rds/${db}" --profile $AWS_PROFILE | jq -r ".SecretString")
        username=$(echo $secret_data | jq -r '."role.master"')
        password=$(echo $secret_data | jq -r '."role.master.password"')
        database=$(echo $secret_data | jq -r '."aurora.database_name"')
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
          if [[ $(echo $member | jq -r '.IsClusterWriter') == 'true' && $SKIP_CONFIRM == 0 ]];
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
        psql "postgres://${username}:${password}@${host}:5432/${database}" "$@"
        unset PGOPTIONS
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
        >&2 echo $db
        >&2 echo $user
    fi
	PGPASSWORD=$(aws redshift get-cluster-credentials --db-user $user --db-name "$db" --cluster-identifier albert-production-data-warehouse --profile prod-devops | jq '.DbPassword' | tr -d '"' | tr -d '\n') PSQL_HISTORY=$HOME/.psql_history_12 /opt/homebrew/Cellar/postgresql@12/12.22_2/bin/psql "host=10.161.21.44 port=5439 user=IAM:${user} dbname=${db} sslmode=verify-ca sslrootcert=${HOME}/.redshift/redshift-ca-bundle.crt" $@
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

# Find the hash image tag for a given ecr repo
find_branch_image() {
  tag=$(aws ecr list-images --repository-name $1 \
    --registry-id 538001969475 \
    --filter tagStatus=TAGGED \
    --max-items 10000 \
    --profile devops-devops \
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


export ALBERT_FUNCTIONS_SET=1

# remove shim created by pyenv
rm /Users/adam/.pyenv/shims/albert &> /dev/null
