#!/bin/bash

#set -x

PROGNAME=`basename "$0"`

info "===== ~: $BASH_SOURCE :~ ====="

info "updating ubuntu"
sudo -E apt-get -y update || { retVal=$?; error "$BASH_SOURCE: apt update failed! returning..."; return $retVal; }

info "upgrading ubuntu"
sudo -E apt-get -y upgrade || { retVal=$?; error "$BASH_SOURCE: apt upgrade failed! returning..."; return $retVal; }

info "dist-upgrading ubuntu"
sudo -E apt-get -y dist-upgrade || { retVal=$?; error "$BASH_SOURCE: apt dist-upgrade failed! returning..."; return $retVal; }

info "===== ~: $BASH_SOURCE - Successful :~ ====="
info ""
