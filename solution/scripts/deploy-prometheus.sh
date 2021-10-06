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

# Deploy Prometheus.
_info "👀 Deploying Prometheus..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install --wait --namespace=prometheus --create-namespace prometheus prometheus-community/kube-prometheus-stack --values=../helm/values/prometheus.yaml

_info "👍 Prometheus is deployed."
