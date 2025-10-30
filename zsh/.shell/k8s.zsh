echo "Sourcing k8s module"

source <(kubectl completion zsh)
export KUBECONFIG="$HOME/.kube/config"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

#
# Echo a pod name, selecting from `kubectl get pods` on a given namespace
#
kget () {
	local resource
	resource="$1"
	shift
	local namespace
	while getopts 'n::' opt
	do
		case $opt in
			(n) namespace=("-n" "$OPTARG")  ;;
			(\?) echo "unexpected argument found $1"
				return 1 ;;
		esac
	done
	local res
	if [[ -n "$namespace" ]]
	then
		res=$(kubectl get ${resource} "${namespace[@]}" | cut -d' ' -f1 | fzf)
	else
		res=$(kubectl get ${resource} | cut -d' ' -f1 | fzf)
	fi
	if [[ -n "$res" ]]
	then
		echo "$res"
	fi
}

#
# Portforward to a pod on a given port. If no pod is specified, select from
# `kubectl get pods` on a given namespace
#
podfwd () {
	local namespace
	local port
	local podname
	local pod
	if [[ -z "$1" || "${1:0:1}" == '-' ]]
	then
		echo "No port specified"
		return 1
	fi
	port="$1"
	shift
	while getopts 'p:n::' opt
	do
		case "$opt" in
			(p) podname="$OPTARG"  ;;
			(n) namespace=("-n" "$OPTARG")  ;;
			(\?) echo "unexpected argument found $1"
				return 1 ;;
		esac
	done
	if [[ -z "$pod" ]]
	then
		pod=$(kget pod "${namespace[@]}")
	fi
	if [[ -n "$namespace" ]]
	then
		kubectl port-forward "${namespace[@]}" "$pod" "$port"
	else
		kubectl port-forward "$pod" "$port"
	fi
}

#
# Exec into a pod. If no pod is specified, select from
# `kubectl get pods` on a given namespace
#
podexec () {
	local namespace
  local ns
	while getopts 'n::' opt
	do
		case "$opt" in
			(n) namespace=("-n" "$OPTARG")  ;;
			(\?) echo "unexpected argument found $1"
				return 1 ;;
		esac
	done
	if [[ -n "$namespace" ]]
	then
		pod=$(kubectl get pods "${namespace[@]}" | cut -d' ' -f1 | fzf)
	else
		pod=$(kubectl get pods | cut -d' ' -f1 | fzf)
    namespace=("-n" "$(kubectl config view --minify -o jsonpath='{..namespace}')")
    
	fi
  echo $ns
	if [[ -n "$pod" ]]
	then
		kubectl exec -it "$pod" "${namespace[@]}"  -- /bin/bash
	fi
}

podfollow () {
	local namespace
	while getopts 'n::' opt
	do
		case "$opt" in
			(n) namespace=("-n" "$OPTARG")  ;;
			(\?) echo "unexpected argument found $1"
				return 1 ;;
		esac
	done
	if [[ -n "$namespace" ]]
	then
		pod=$(kubectl get pods "${namespace[@]}" | cut -d' ' -f1 | fzf)
	else
		pod=$(kubectl get pods | cut -d' ' -f1 | fzf)
	fi
	if [[ -n "$pod" ]]
	then
		kubectl logs -f "$pod"
	fi
}

refresh_dev_for_docker () {
    local new_token
    new_token=$(aws --region us-west-2 eks get-token --cluster-name dev-remote-development-eks-2 --output json --profile dev-devops | jq -r .status.token)
    sed -i '' "s|token:.*|token: ${new_token}|" ${KUBECONFIG}
}


export K8S_FUNCTIONS_SET=1
