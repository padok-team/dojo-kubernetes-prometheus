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

# Package the producer inside a container image.
_info "📦 Packaging the producer inside a container image..."
docker build --tag="padok.fr/producer:${IMAGE_TAG}" ../producer

# Deploy the producer.
_info "🚚 Deploying the producer..."
kind load docker-image --name=padok-dojo "padok.fr/producer:${IMAGE_TAG}"
helm upgrade --install --wait --namespace=default producer ../helm/charts/producer --set="version=${IMAGE_TAG}"

_info "👍 The producer is deployed."
