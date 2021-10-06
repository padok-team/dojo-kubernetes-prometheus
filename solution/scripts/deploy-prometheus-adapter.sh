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

# Deploy the Prometheus adapter.
_info " Deploying the Prometheus adapter..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install --wait --namespace=prometheus --create-namespace prometheus-adapter prometheus-community/prometheus-adapter --values=../helm/values/prometheus-adapter.yaml

_info "👍 The Prometheus adapter is deployed."
