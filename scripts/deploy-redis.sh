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

# Deploy Redis.
_info "🏓 Deploying Redis..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install --wait --namespace=default redis bitnami/redis --values=../helm/values/redis.yaml

_info "👍 Redis is deployed."
