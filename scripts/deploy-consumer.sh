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

# Define a unique tag for the image.
IMAGE_TAG="$(date +%s)"

# Package the consumer inside a container image.
_info "📦 Packaging the consumer inside a container image..."
docker build --tag="padok.fr/consumer:${IMAGE_TAG}" ../consumer

# Deploy the consumer.
_info "🚚 Deploying the consumer..."
kind load docker-image --name=padok-dojo "padok.fr/consumer:${IMAGE_TAG}"
helm upgrade --install --wait --namespace=default consumer ../helm/charts/consumer --set="version=${IMAGE_TAG}"

_info "👍 The consumer is deployed."
