#!/bin/bash

#set -x

DATE='date +%Y/%m/%d:%H:%M:%S'
PROGNAME=`basename "$0"`

info "===== ~: $BASH_SOURCE :~ ====="
grep -n "$NODE_IP" /etc/hosts
if [[ $? -ne 0 ]]
then
    lineNum="$(grep -n "IPv6 capable hosts" /etc/hosts | cut -f1 -d:)"
    atLine=$(($lineNum-1))
    info "Adding '$NODE_IP $NODE_NAME $NODE_DOM' at line: $atLine"
    sudo sed -i "${atLine}i$NODE_IP	$NODE_NAME	$NODE_DOM" /etc/hosts \
        || { retVal=$?; error "setHostsInfo: hosts update failed! returning..."; return $retVal; }
fi

info "Updating hostname to '$NODE_NAME' in /etc/hostname"
echo "$NODE_NAME" | sudo tee /etc/hostname
sudo hostname $NODE_NAME || { retVal=$?; error "setHostsInfo: hostname update failed! returning..."; return $retVal; }

info "===== ~: $BASH_SOURCE - Done :~ ====="
info ""
