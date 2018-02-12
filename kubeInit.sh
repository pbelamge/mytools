#!/bin/bash
info "===== ~: $BASH_SOURCE :~ ====="

POD_NET_CIDR="--pod-network-cidr=$KUBE_POD_CIDR"
API_SRVR_ADV_ADDR="--apiserver-advertise-address=$NODE_IP"
SVC_CIDR="--service-cidr=$KUBE_SVC_CIDR"

info "initializing kubeadm"
sudo -E kubeadm init $POD_NET_CIDR $API_SRVR_ADV_ADDR $SVC_CIDR || exit_on_error "$BASH_SOURCE: k8s init failed!!" $?

info "update local .kube configs"
[[ ! -d $KUBE_CONFIG_DIR ]] || mkdir -p $KUBE_CONFIG_DIR
sudo cp -i $K8SCONF $KUBE_CONFIG_DIR/config
sudo chown $(id -u):$(id -g) $KUBE_CONFIG_DIR/config

info "apply net config"
kubectl apply -f $NETCONF

info "===== ~: $BASH_SOURCE - Successful :~ ====="
info ""
