#!/bin/bash

DATE='date +%Y%m%d:%H%M%S'
APP_NAME=${APP_NAME}
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
    export DOCKER_SVCD="/etc/systemd/system/docker.service.d"
    export K8SCONF="/etc/kubernetes/admin.conf"
    export NETCONF="https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml"
    export KUBE_CONFIG_DIR="$HOME/.kube"
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
        [[ ! -d $DOCKER_DIR ]] || sudo mkdir -p $DOCKER_SVCD

        echo "[Service]" | sudo tee $DOCKER_SVCD/http-proxy.conf
        echo "Environment=\"HTTP_PROXY=$PROXY_ADDRESS\"" | sudo tee -a $DOCKER_SVCD/http-proxy.conf
        echo "Environment=\"HTTPS_PROXY=$PROXY_ADDRESS\"" | sudo tee -a $DOCKER_SVCD/http-proxy.conf
        echo "Environment=\"NO_PROXY=$NOPROXY_ADDRESS\"" | sudo tee -a $DOCKER_SVCD/http-proxy.conf

        sudo systemctl daemon-reload
        sudo systemctl show --property Environment docker
        sudo systemctl restart docker
    fi
}

info "===== ~: $BASH_SOURCE :~ ====="

[[ $FORCE_DEPLOY || $OS_UPGRADE -eq 1 ]] && upgradeUbuntu

initEnv

[[ $FORCE_DEPLOY || $SKIP_DOCKER -ne 1 ]] && setupDocker

. installK8s.sh || exit_on_error "$BASH_SOURCE: kubernetes installation failed!!" $?

. kubeInit.sh || exit_on_error "$BASH_SOURCE: kubernetes initialization failed!!" $?

info "===== ~: $BASH_SOURCE - Successful :~ ====="
info ""
