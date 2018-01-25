#!/bin/bash

export CONFIGS_DIR="$(pwd)/configs"
export KUBE_CONFIG_DIR="$HOME/.kube"
export APP_NAME="ucpdev"
export NODE_IP=""
export NODE_DOM="node1.com"
export NODE_NAME="node1"
export PROXY_ENABLE="false"
export PROXY_ADDRESS="http://proxy.example.com:8888"
export NOPROXY_ADDRESS='127.0.0.1,127.0.1.1,localhost'

if [[ $PROXY_ENABLED == "true" ]]
then
    export http_proxy=$PROXY_ADDRESS
    export https_proxy=$PROXY_ADDRESS
    export no_proxy=$NOPROXY_ADDRESS
    export HTTP_PROXY=$PROXY_ADDRESS
    export HTTPS_PROXY=$PROXY_ADDRESS
    export NO_PROXY=$NOPROXY_ADDRESS
else
    export http_proxy=""
    export https_proxy=""
    export no_proxy=""
    export HTTP_PROXY=""
    export HTTPS_PROXY=""
    export NO_PROXY=""
fi

export CEPH_CLUSTER_NET="172.16.100.0/24"
export CEPH_PUBLIC_NET="172.16.100.0/24"
export GENESIS_NODE_IP=${NODE_IP:-"172.16.100.5"}
export MASTER_NODE_IP=""
export NODE_NET_IFACE="enp0s8"
export PROMENADE_IMAGE="quay.io/attcomdev/promenade:latest"
export ARMADA_IMAGE="quay.io/attcomdev/armada:latest"
export DRYDOCK_IMAGE="quay.io/attcomdev/drydock:latest"
export GENESIS_NODE_NAME=${NODE_NAME:-"node1"}
export MASTER_NODE_NAME="node2"
export NAMESERVER_1=""
export NAMESERVER_2=""
