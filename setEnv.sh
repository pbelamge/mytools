#!/bin/bash

export CONFIGS_DIR="$(pwd)/configs"
export KUBE_CONFIG_DIR="$HOME/.kube"
export APP_NAME="initEnv"
export NODE_IP="172.16.100.20"
export NODE_MASK="255.255.255.0"
export NODE_DOM="kmaster.com"
export NODE_NAME="kmaster"
export PROXY_ENABLED="true"

export http_proxy=""
export https_proxy=""
export no_proxy=""
export HTTP_PROXY=""
export HTTPS_PROXY=""
export NO_PROXY=""

[[ $PROXY_ENABLED == "true" ]] && . setProxy
