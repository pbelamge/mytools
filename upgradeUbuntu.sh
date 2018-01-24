#!/bin/bash

#set -x

DATE='date +%Y/%m/%d:%H:%M:%S'
PROGNAME=`basename "$0"`

info "===== ~: $BASH_SOURCE :~ ====="

info "updating ubuntu"
apt-get -y update || { retVal=$?; error "upgradeUbuntu: apt update failed! returning..."; return $retVal; }

info "upgrading ubuntu"
apt-get -y upgrade || { retVal=$?; error "upgradeUbuntu: apt upgrade failed! returning..."; return $retVal; }

info "dist-upgrading ubuntu"
apt-get -y dist-upgrade || { retVal=$?; error "upgradeUbuntu: apt dist-upgrade failed! returning..."; return $retVal; }

info "===== ~: $BASH_SOURCE - Successful :~ ====="
info ""
