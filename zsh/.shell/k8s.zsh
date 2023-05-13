echo "Sourcing k8s module"

source <(kubectl completion zsh)
export KUBECONFIG="$HOME/.kube/config"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

#
# Echo a pod name, selecting from `kubectl get pods` on a given namespace
#
fn podget() {
    local namespace
    while getopts 'n::' opt; do
        case $opt in
            n)
                namespace=( "-n" "$OPTARG" ) ;;
            \?)
                echo "unexpected argument found $1"
                return 1 ;;
        esac
    done
    if [[ -n "$namespace" ]]; then
        pod=$(kubectl get pods "${namespace[@]}" | cut -d' ' -f1 | fzf)
    else
        pod=$(kubectl get pods | cut -d' ' -f1 | fzf)
    fi
    if [[ -n "$pod" ]] then
        echo "$pod"
    fi
}

#
# Portforward to a pod on a given port. If no pod is specified, select from
# `kubectl get pods` on a given namespace
#
fn podfwd() {
    local namespace
    local port
    local podname
    local pod

    if [[ -z "$1" || "${1:0:1}" == '-' ]]; then
        echo "No port specified"
        return 1
    fi
    port="$1"
    shift;

    while getopts 'p:n::' opt; do
        case "$opt" in
            p)
                podname="$OPTARG";;
            n)
                namespace=( "-n" "$OPTARG" ) ;;
            \?)
                echo "unexpected argument found $1"
                return 1 ;;
        esac
    done
    if [[ -z "$pod" ]] then
        pod=$(podget "${namespace[@]}")
    fi

    if [[ -n "$namespace" ]]; then
        kubectl port-forward "${namespace[@]}" "$pod"  "$port"
    else
        kubectl port-forward "$pod" "$port"
    fi
}

#
# Exec into a pod. If no pod is specified, select from
# `kubectl get pods` on a given namespace
#
fn podexec() {
    local namespace
    while getopts 'n::' opt; do
        case "$opt" in
            n)
                namespace=( "-n" "$OPTARG" ) ;;
            \?)
                echo "unexpected argument found $1"
                return 1 ;;
        esac
    done
    if [[ -n "$namespace" ]]; then
        pod=$(kubectl get pods "${namespace[@]}" | cut -d' ' -f1 | fzf)
    else
        pod=$(kubectl get pods | cut -d' ' -f1 | fzf)
    fi
    if [[ -n "$pod" ]] then
        kubectl exec -it "$pod" -- /bin/bash
    fi
}

#
# Connect to a postgres database in a given namespace.
#  NOTE: The pod must be port-forwarded to the local machine.
#
fn rdepsql() {
    local database
    while getopts 's:d:n::' opt; do
        case "$opt" in
            d)
                database="$OPTARG";;
            \?)
                echo "unexpected argument found $1"
                return 1 ;;
        esac
    done
    psql "postgres://postgres:postgres@localhost:5432/${database}"
}

export K8S_FUNCTIONS_SET=1
