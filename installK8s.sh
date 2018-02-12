#!/bin/bash

info "===== ~: $BASH_SOURCE :~ ====="

info "adding apt-key"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

info "adding k8s repo"
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

info "update apt"
sudo -E apt-get -y update || exit_on_error "$BASH_SOURCE: apt update failed!!" $?

info "install k8s tools"
sudo -E apt-get install -y kubelet kubeadm kubectl || exit_on_error "$BASH_SOURCE: k8s pkg installation failed!!" $?

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

info "===== ~: $BASH_SOURCE - Successful :~ ====="
info ""
