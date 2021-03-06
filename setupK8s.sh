#!/bin/bash

set -x

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
    export KUBE_JOIN_PARAM=${KUBE_JOIN_PARAM:-"NA"}
    export NETCONF="$KUBE_NET_CONF"
    export NODE_IP=${NODE_IP:-"NA"}
    export MASTER_IP=${MASTER_IP:-"NA"}
    export NODE_MASK=${NODE_MASK:-"NA"}
    export NODE_DOM=${NODE_DOM:-"NA"}
    export NODE_NAME=${NODE_NAME:-"NA"}
    export PROXY_ENABLED=${PROXY_ENABLED:-"false"}
    if [[ $PROXY_ENABLED == "true" ]]
    then
        if [[ $NODE_IP == $MASTER_IP ]]
        then
            export NOPROXY_ADDRESS="$NODE_IP,$KUBE_POD_CIDR,$KUBE_SVC_CIDR,$NOPROXY_ADDRESS,$NODE_NAME"
        elif [[ $MASTER_IP != "NA" ]]
        then
            export NOPROXY_ADDRESS="$MASTER_IP,$NODE_IP,$KUBE_POD_CIDR,$KUBE_SVC_CIDR,$NOPROXY_ADDRESS,$NODE_NAME"
        else
            exit_on_error "MASTER_IP env must be set for kube join!!" 5
        fi
        export no_proxy=$NOPROXY_ADDRESS
        export NO_PROXY=$NOPROXY_ADDRESS
    fi
}

function validateEnv {
    info "validating env"
    [[ $NODE_IP == "NA" ]] && exit_on_error "NODE_IP env var must be set to correct value." $1

    [[ $NODE_DOM == "NA" || $NODE_NAME == "NA" ]] \
        && exit_on_error "NODE_DOM and NODE_NAME env vars must be set to correct values." $1

    [[ $KUBE_JOIN_PARAM == "NA" ]] && exit_on_error "KUBE_JOIN_PARAM env var must be set to correct value." $1
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
    
    POD_NET_CIDR="--pod-network-cidr=$KUBE_POD_CIDR"
    API_SRVR_ADV_ADDR="--apiserver-advertise-address=$NODE_IP"
    SVC_CIDR="--service-cidr=$KUBE_SVC_CIDR"

    sudo -E kubeadm init $POD_NET_CIDR $API_SRVR_ADV_ADDR $SVC_CIDR || exit_on_error "$BASH_SOURCE: k8s init failed!!" $?

    info "update local .kube configs"
    [[ ! -d $KUBE_CONFIG_DIR ]] && mkdir -p $KUBE_CONFIG_DIR
    sudo cp -i $K8SCONF $KUBE_CONFIG_DIR/config
    sudo chown $(id -u):$(id -g) $KUBE_CONFIG_DIR/config

    info "apply net config"
    kubectl apply -f $NETCONF || exit_on_error "$BASH_SOURCE: k8s net-conf apply failed!!" $?
}

function kubeJoin {
    info "joining k8s cluster nodes"

    disableSwap

    sudo -E kubeadm join $KUBE_JOIN_PARAM || exit_on_error "$BASH_SOURCE: k8s init failed!!" $?
}

info "===== ~: $BASH_SOURCE :~ ====="

[[ $FORCE_DEPLOY || $OS_UPGRADE -eq 1 ]] && upgradeUbuntu

initEnv

validateEnv

[[ $FORCE_DEPLOY || $SKIP_DOCKER -ne 1 ]] && setupDocker

[[ $FORCE_DEPLOY || $SKIP_K8S_INSTALL -ne 1 ]] && installK8s

[[ $KUBE_INIT_ENABLE -eq 1 && $KUBE_JOIN_NODE -ne 1 ]] && kubeInit

[[ $KUBE_JOIN_NODE -eq 1 && $KUBE_INIT_ENABLE -ne 1 ]] && kubeJoin

info "===== ~: $BASH_SOURCE - Successful :~ ====="
info ""
