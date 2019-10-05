#!/bin/bash

set -e

FUNCTION_NAME="$1"

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
            echo -e "\\e[34m$dt $level: $msg\\e[0m"
        ;;
        DEBUG)
            echo -e "\\e[33m$dt $level: $msg\\e[0m"
        ;;
        ERROR)
            echo -e "\\e[31m$dt $level: $msg\\e[0m"
        ;;
        *)
            echo "$dt $msg"
        ;;
    esac
}

log "INFO" "Building $FUNCTION_NAME..."
faas build -f "./$FUNCTION_NAME.yml"

log "INFO" "Importing $FUNCTION_NAME:latest image to cluster registry..."
k3d import-images "$FUNCTION_NAME:latest"

log "INFO" "Deploying $FUNCTION_NAME function"
faas deploy -f "$FUNCTION_NAME.yml"

faas list
