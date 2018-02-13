#!/bin/bash

export APP_NAME=""
export NODE_IP=""
export NODE_MASK=""
export NODE_DOM=""
export NODE_NAME=""
export PROXY_ENABLED=""

export http_proxy=""
export https_proxy=""
export no_proxy=""
export HTTP_PROXY=""
export HTTPS_PROXY=""
export NO_PROXY=""

[[ $PROXY_ENABLED == "true" ]] && . setProxy
