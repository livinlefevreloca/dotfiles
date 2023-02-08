echo "Sourcing k8s module"

source <(kubectl completion zsh)
export KUBECONFIG="$HOME/.kube/config"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export K8S_FUNCTIONS_SET=1
