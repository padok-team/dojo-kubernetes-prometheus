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

# Deploy the Redis exporter.
_info "📤 Deploying the Prometheus Redis exporter..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install --wait --namespace=default --create-namespace prometheus-redis-exporter prometheus-community/prometheus-redis-exporter --values=../helm/values/prometheus-redis-exporter.yaml

_info "👍 The Prometheus Redis exporter is deployed."
