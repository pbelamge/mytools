#!/bin/bash
info "===== ~: $BASH_SOURCE :~ ====="

info "initializing kubeadm"
sudo -E kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$NODE_IP --service-cidr=10.96.0.0/16 \
        || exit_on_error "$BASH_SOURCE: k8s init failed!!" $?
RETVAL=$?
if [ $RETVAL -ne 0 ]; then
    info "kube init failed"
    exit 1
fi

info "update local .kube configs"
[[ ! -d $KUBE_CONFIG_DIR ]] || mkdir -p $KUBE_CONFIG_DIR
sudo cp -i $K8SCONF $KUBE_CONFIG_DIR/config
sudo chown $(id -u):$(id -g) $KUBE_CONFIG_DIR/config

info "apply net config"
kubectl apply -f $NETCONF

info "===== ~: $BASH_SOURCE - Successful :~ ====="
info ""
