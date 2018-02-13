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
    export NODE_IP=${NODE_IP:-"NA"}
    export NODE_MASK=${NODE_MASK:-"NA"}
    export NODE_DOM=${NODE_DOM:-"NA"}
    export NODE_NAME=${NODE_NAME:-"NA"}
    export PROXY_ENABLED=${PROXY_ENABLED:-"false"}
}

function validateEnv {
    info "validating env"
    [[ $NODE_IP == "NA" || $NODE_MASK == "NA" ]] \
        && exit_on_error "NODE_IP and NODE_MASK env vars must be set to correct values." $1

    [[ $NODE_DOM == "NA" || $NODE_NAME == "NA" ]] \
        && exit_on_error "NODE_DOM and NODE_NAME env vars must be set to correct values." $1
}

function setIfConfig {
    info "setting static ip"
    grep -n "$NODE_IP" /etc/network/interfaces
    if [[ $? -ne 0 ]]
    then
        sudo sed -i 's/enp0s8 inet dhcp/enp0s8 inet static/g' /etc/network/interfaces
        echo "	address $NODE_IP" | sudo tee -a /etc/network/interfaces
        echo "	netmask $NODE_MASK" | sudo tee -a /etc/network/interfaces
    fi
}

function setHostsInfo {
    info "setting hosts info"
    . setHostsInfo.sh || exit_on_error "$BASH_SOURCE: hosts/name update failed" $?
}

function upgradeUbuntu {
    info "upgrading ubuntu os"
    . upgradeUbuntu.sh || exit_on_error "$BASH_SOURCE: ubuntu os upgradation failed" $?
}

# Make sure only root can deploy UCP
#[[ "$(id -u)" != "0" ]] && exit_on_error "$BASH_SOURCE: This script must be run as root" 1

info "===== ~: $BASH_SOURCE :~ ====="

initEnv

validateEnv

info "~: Envs Set :~"
info "IP: "$NODE_IP
info "Domain: "$NODE_DOM
info "Sub-Domain: "$NODE_NAME
[[ $PROXY_ENABLED == "true" ]] && info "Proxy: "$PROXY_ADDRESS
[[ $PROXY_ENABLED == "true" ]] && info "No-proxy: "$NOPROXY_ADDRESS
info "~: Done :~"

if [ -f ~/.devopsrc ]; then
   info "removing old devopsrc"
   rm ~/.devopsrc
fi

info "copying new devopsrc"
cp devopsrc ~/.devopsrc

if [ -f ~/.proxyrc ]; then
   info "removing old proxyrc"
   rm ~/.proxyrc
fi

if [[ $PROXY_ENABLED == "true" ]]
then
    echo "export http_proxy=$PROXY_ADDRESS" | tee ~/.proxyrc
    echo "export https_proxy=$PROXY_ADDRESS" | tee -a ~/.proxyrc
    echo "export no_proxy='$NOPROXY_ADDRESS'" | tee -a ~/.proxyrc
fi

info "copying custom bashrc"
cp bashrc ~/.bashrc

[[ $FORCE_DEPLOY || $SKIP_IF_CONFIG -ne 1 ]] && setIfConfig

[[ $FORCE_DEPLOY || $SKIP_ETC_HOSTS -ne 1 ]] && setHostsInfo

[[ $FORCE_DEPLOY || $OS_UPGRADE -eq 1 ]] && upgradeUbuntu

info "===== ~: $BASH_SOURCE - Successful :~ ===== "
info ""

echo "rebooting..."
sudo reboot
