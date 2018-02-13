#!/bin/bash

DATE='date +%Y%m%d:%H%M%S'
APP_NAME=${APP_NAME:-$BASH_SOURCE}
LOG="$APP_NAME.log"
PROGNAME=`basename "$0"`

function log {
    echo `$DATE`"$1" >> $LOG
}

function info {
    log " INFO: $1"
}

function error {
    log " ERROR: $1"
}

function exit_on_error {
    echo `$DATE`" FATAL: $1" 1>&2
    exit $2
}

function initEnv {
    info "initializing env"

    export DOCKER_SVCD="/etc/systemd/system/docker.service.d"
    export K8SCONF="/etc/kubernetes/admin.conf"
    export NETCONF="$KUBE_NET_CONF"
    export NODE_IP=${NODE_IP:-"NA"}
    export NODE_MASK=${NODE_MASK:-"NA"}
    export NODE_DOM=${NODE_DOM:-"NA"}
    export NODE_NAME=${NODE_NAME:-"NA"}
    export PROXY_ENABLED=${PROXY_ENABLED:-"false"}
    if [[ $PROXY_ENABLED == "true" ]]
    then
        export NOPROXY_ADDRESS="$NODE_IP,$KUBE_POD_CIDR,$KUBE_SVC_CIDR,$NOPROXY_ADDRESS,$NODE_NAME"
        export no_proxy=$NOPROXY_ADDRESS
        export NO_PROXY=$NOPROXY_ADDRESS
    fi
}

function validateEnv {
    info "validating env"
    [[ $NODE_IP == "NA" ]] && exit_on_error "NODE_IP env var must be set to correct value." $1

    [[ $NODE_DOM == "NA" || $NODE_NAME == "NA" ]] \
        && exit_on_error "NODE_DOM and NODE_NAME env vars must be set to correct values." $1
}

function upgradeUbuntu {
    info "upgrading ubuntu os"
    . upgradeUbuntu.sh || exit_on_error "$BASH_SOURCE: ubuntu os upgradation failed" $?
}

function setupDocker {
    info "installing docker and jq packages"

    sudo -E apt update || exit_on_error "$BASH_SOURCE: apt update for docker failed" $?
    sudo -E apt -y install docker.io || exit_on_error "$BASH_SOURCE: docker installation failed" $?

    if [[ $PROXY_ENABLED == "true" ]]
    then
        info "setting proxy for docker"
        [[ ! -d $DOCKER_SVCD ]] && sudo mkdir -p $DOCKER_SVCD

        echo "[Service]" | sudo tee $DOCKER_SVCD/http-proxy.conf
        echo "Environment=\"HTTP_PROXY=$PROXY_ADDRESS\"" | sudo tee -a $DOCKER_SVCD/http-proxy.conf
        echo "Environment=\"HTTPS_PROXY=$PROXY_ADDRESS\"" | sudo tee -a $DOCKER_SVCD/http-proxy.conf
        echo "Environment=\"NO_PROXY=$NOPROXY_ADDRESS\"" | sudo tee -a $DOCKER_SVCD/http-proxy.conf

        sudo systemctl daemon-reload
        sudo systemctl show --property Environment docker
        sudo systemctl restart docker
    fi
}

function installK8s {
    info "instaling k8s packages"
    . installK8s.sh || exit_on_error "$BASH_SOURCE: kubernetes installation failed!!" $?
}

function disableSwap {
    info "disabling swap"

    sudo grep -n 'fail-swap-on=false' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    if [[ $? -ne 0 ]]
    then
        info "disable swap"
        echo "Environment=\"KUBELET_EXTRA_ARGS=--fail-swap-on=false\"" | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    fi

    sudo swapoff -a

    info "reloading daemon"
    sudo systemctl daemon-reload

    info "restarting docker service"
    sudo systemctl restart kubelet
}

function kubeInit {
    info "initializing k8s"
    disableSwap
    . kubeInit.sh || exit_on_error "$BASH_SOURCE: kubernetes initialization failed!!" $?
}

function kubeJoin {
    info "joining k8s cluster nodes"
    . kubeJoin.sh || exit_on_error "$BASH_SOURCE: kubernetes initialization failed!!" $?
}

info "===== ~: $BASH_SOURCE :~ ====="

[[ $FORCE_DEPLOY || $OS_UPGRADE -eq 1 ]] && upgradeUbuntu

initEnv

validateEnv

[[ $FORCE_DEPLOY || $SKIP_DOCKER -ne 1 ]] && setupDocker

[[ $FORCE_DEPLOY || $SKIP_K8S_INSTALL -ne 1 ]] && installK8s

[[ $FORCE_DEPLOY || $KUBE_INIT_ENABLE -eq 1 ]] && kubeInit

[[ $FORCE_DEPLOY || $KUBE_JOIN_NODE -eq 1 ]] && kubeJoin

info "===== ~: $BASH_SOURCE - Successful :~ ====="
info ""
