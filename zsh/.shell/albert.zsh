echo "Sourcing albert module"

function codegen() {

    local SERVICE="${1}"
    shift
    declare GENERATE PULL

    while [[ "$#" -ge 1 ]]; do
        case "$1" in
        '-g'|'--generate')
            GENERATE='--generate'
            shift ;;
        '-p'|'--pull')
            PULL='--pull'
            shift ;;
        '-c'|'--mount-common')
            COMMON='--mount-common'
            shift ;;
        *)
            echo "unexpected argument found $1 ... exiting"
            exit(1) ;;
        esac
    done
    

    if ! aws s3 ls --profile dev-engineer > /dev/null
    then
        login dev-engineer
    fi

    if [[ ${SERVICE} == 'auth' ]];
    then
        APP_SERVICE='authentication'
    else
        APP_SERVICE=$SERVICE
    fi

    if [[ $(albert dev telepresence-status | rg "User Daemon" | awk -F ':' 'gsub(/^[ \t]+/, "", $0); {print $2}') == 'Not running' ]]
    then
        albert dev telepresence-connect
    fi

    albert dev runlocal -s ${SERVICE} \
        -v ${ALBERT_PROJECTS}looker:/looker,${ALBERT_PROJECTS}albert-dbt-analytics-transforms:/albert-dbt-analytics-transforms \
        ${PULL} \
        ${COMMON} \
        -- python manage.py check_replication_code ${APP_SERVICE} ${GENERATE} 
}

function newcodegen() {

    local SERVICE="${1}"
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
            echo "unexpected argument found $1 ... exiting"
            exit(1) ;;
        esac
    done
    

    if ! aws s3 ls --profile dev-engineer > /dev/null
    then
        login dev-engineer
    fi

    if [[ ${SERVICE} == 'auth' ]];
    then
        APP_SERVICE='authentication'
    else
        APP_SERVICE=$SERVICE
    fi

    if [[ $(albert dev telepresence-status | rg "User Daemon" | awk -F ':' 'gsub(/^[ \t]+/, "", $0); {print $2}') == 'Not running' ]]
    then
        albert dev telepresence-connect
    fi

    albert dev runlocal -s ${SERVICE} \
        -v ${ALBERT_PROJECTS}looker:/looker,${ALBERT_PROJECTS}albert-dbt-analytics-transforms:/albert-dbt-analytics-transforms \
        ${PULL} \
        ${COMMON} \
        -- python manage.py generate_replication_code ${APP_SERVICE} ${CONFIG}
}


export ALBERT_PROJECTS=/Users/$USER/Projects/albert/
export ALBERT_ROOT=/Users/$USER/Projects/albert/albert-main/
export GITHUB_TOKEN=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
export AWS_DEFAULT_PROFILE=dev-engineer
eval "$(_ALBERT_COMPLETE=source_zsh albert)"

reset && activate albert

cd "${ALBERT_PROJECTS}"

export ALBERT_FUNCTIONS_SET=1
