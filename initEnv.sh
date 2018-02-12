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

function setIfConfig {
    info "setting static ip"
    grep -n "$NODE_IP" /etc/network/interfaces
    if [[ $? -ne 0 ]]
    then
        sudo sed -i 's/enp0s8 inet dhcp/enp0s8 inet static/g' /etc/network/interfaces
        echo "	address $NODE_IP" | sudo tee -a /etc/network/interfaces
        echo "  netmask $NODE_MASK" | sudo tee -a /etc/network/interfaces
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

info "~: Envs Set :~"
info "IP: "$NODE_IP
info "Domain: "$NODE_DOM
info "Sub-Domain: "$NODE_NAME
info "Proxy: "$PROXY_ADDRESS
info "No-proxy: "$NOPROXY_ADDRESS
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

echo "export http_proxy=$PROXY_ADDRESS" | tee ~/.proxyrc
echo "export https_proxy=$PROXY_ADDRESS" | tee -a ~/.proxyrc
echo "export no_proxy='$NOPROXY_ADDRESS'" | tee -a ~/.proxyrc

info "copying custom bashrc"
cp bashrc ~/.bashrc

[[ $FORCE_DEPLOY || $SKIP_IF_CONFIG -ne 1 ]] && setIfConfig

[[ $FORCE_DEPLOY || $SKIP_ETC_HOSTS -ne 1 ]] && setHostsInfo

[[ $FORCE_DEPLOY || $OS_UPGRADE -eq 1 ]] && upgradeUbuntu

info "===== ~: $BASH_SOURCE - Successful :~ ===== "
info ""

echo "rebooting..."
sudo reboot
