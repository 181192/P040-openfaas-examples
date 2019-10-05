#!/bin/bash

set -e

function log {
    local dt
    dt=$(date '+%Y/%m/%d %H:%M:%S')
    local level=$1
    local msg=$2

    if [[ $# == 1 ]]; then
        msg=$1
    fi

    case $level in
        INFO)
            echo -e "\e[34m$dt $msg\e[0m"
        ;;
        DEBUG)
            echo -e "\e[33m$dt $msg\e[0m"
        ;;
        ERROR)
            echo -e "\e[31m$dt $msg\e[0m"
        ;;
        *)
            echo "$dt $msg"
        ;;
    esac
}

function require {
  command -v "$1" >/dev/null 2>&1 || { log "ERROR" "Script requires $1 but it's not installed. Aborting..."; exit 1; }
}

require docker
require kubectl
require k3d
require faas-cli

PASSWORD="admin"
FUNCTION_NAME="hello-python"

GATEWAY_URL="127.0.0.1:8080"

if [[ $(k3d list | grep k3s-default) != *"k3s-default"* ]]; then
    k3d create --publish 8080:8080@k3d-k3s-default-worker-0 --workers 3 --wait 300
fi

log "INFO" "Getting kubeconfig"
sleep 10

KUBECONFIG="$(k3d get-kubeconfig --name='k3s-default')"
export KUBECONFIG

while [[ $(kubectl get po -n kube-system -l k8s-app=kube-dns --output=jsonpath='{.items[*].metadata.labels.k8s-app}') != "kube-dns" ]]; do
    log "DEBUG" "Waiting for core-dns pod to be created..."
    sleep 1
done

log "DEBUG" "Waiting for core-dns pod to be ready..."
kubectl -n kube-system wait --for=condition=ready --timeout=300s pod/"$(kubectl get pod -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[0].metadata.name}')"

log "INFO" "Creating namespaces..."
kubectl apply -f namespaces.yml

log "INFO" "Creating openfaas basic-auth secret..."
kubectl -n openfaas create secret generic basic-auth \
--from-literal=basic-auth-user=admin \
--from-literal=basic-auth-password="$PASSWORD" \
--save-config \
--dry-run \
--output yaml | kubectl apply -f -

log "INFO" "Installing openfaas..."
kubectl apply -f ./setup/

while [[ $(kubectl get po -n openfaas -l app=gateway --output=jsonpath='{.items[*].metadata.labels.app}') != "gateway" ]]; do
    log "DEBUG" "Waiting for gateway pod to be created..."
    sleep 1
done

log "DEBUG" "Waiting for gateway pod to be ready..."
kubectl -n openfaas wait --for=condition=ready --timeout=300s pod/"$(kubectl get pod -n openfaas -l app=gateway -o jsonpath='{.items[0].metadata.name}')"

log "INFO" "Login to openfaas..."
echo -n $PASSWORD | faas login --username admin --password-stdin --gateway "$GATEWAY_URL"

log "INFO" "Building $FUNCTION_NAME..."
faas build -f ./$FUNCTION_NAME.yml

log "INFO" "Importing $FUNCTION_NAME:latest image to cluster registry..."
k3d import-images $FUNCTION_NAME:latest

log "INFO" "Deploying $FUNCTION_NAME function"
faas deploy -f $FUNCTION_NAME.yml

faas list

log "INFO" "Invoking $FUNCTION_NAME function"
curl "$GATEWAY_URL/function/$FUNCTION_NAME" -d "Demo"
