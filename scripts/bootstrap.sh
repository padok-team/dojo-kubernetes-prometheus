#! /usr/bin/env bash

set -e

# Helpers for readability.
bold=$(tput bold)
normal=$(tput sgr0)
function _info() {
    echo "${bold}${1}${normal}"
}

# Run script from directory where the script is stored.
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Create a local Kubernetes cluster.
_info "🔧 Creating a local Kubernetes cluster..."
kind create cluster --name=padok-dojo --config=../kind-cluster.yaml

# Install the NGINX ingress controller.
_info "📥 Installing an ingress controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
kubectl rollout status deployment --namespace=ingress-nginx ingress-nginx-controller
kubectl delete validatingwebhookconfiguration ingress-nginx-admission # Workaround for this issue: https://github.com/kubernetes/ingress-nginx/issues/5401

# Deploy the app.
./deploy-redis.sh
./deploy-producer.sh
./deploy-consumer.sh

_info "🚀 You are ready to go!"
