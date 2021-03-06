#!/bin/bash

#set -x

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
    info "setting required ENV vars"

    # Setup environmental variables
    # with stable defaults

    # Network
    export CEPH_CLUSTER_NET=${CEPH_CLUSTER_NET:-"NA"}
    export CEPH_PUBLIC_NET=${CEPH_PUBLIC_NET:-"NA"}
    export GENESIS_NODE_IP=${GENESIS_NODE_IP:-"NA"}
    export DRYDOCK_NODE_IP=${DRYDOCK_NODE_IP:-${GENESIS_NODE_IP}}
    export DRYDOCK_NODE_PORT=${DRYDOCK_NODE_PORT:-31000}
    export MAAS_NODE_IP=${MAAS_NODE_IP:-${GENESIS_NODE_IP}}
    export MAAS_NODE_PORT=${MAAS_NODE_PORT:-31900}
    export MASTER_NODE_IP=${MASTER_NODE_IP:-"NA"}
    export NODE_NET_IFACE=${NODE_NET_IFACE:-"eth0"}
    export AIRFLOW_NODE_PORT=${AIRFLOW_NODE_PORT:-32080}
    export SHIPYARD_NODE_PORT=${SHIPYARD_NODE_PORT:-31901}
    export ARMADA_NODE_PORT=${ARMADA_NODE_PORT:-31903}

    # UCP Service Config
    export SHIPYARD_PROD_DEPLOY=${SHIPYARD_PROD_DEPLOY:-"true"}
    export AIRFLOW_PATH_DAG=${AIRFLOW_PATH_DAG:-"/var/tmp/airflow/dags"}
    export AIRFLOW_PATH_PLUGIN=${AIRFLOW_PATH_PLUGIN:-"/var/tmp/airflow/plugins"}
    export AIRFLOW_PATH_LOG=${AIRFLOW_PATH_LOG:-"/var/tmp/airflow/logs"}
    export MAAS_CACHE_ENABLED=${MAAS_CACHE_ENABLED:-"false"}
    # NOTE - Pool size of 1 is NOT production-like. Workaround for Ceph Luminous
    # until disk targetting is implemented to have multiple OSDs on Genesis
    export CEPH_OSD_POOL_SIZE=${CEPH_OSD_POOL_SIZE:-"1"}

    # Storage
    export CEPH_OSD_DIR=${CEPH_OSD_DIR:-"/var/lib/openstack-helm/ceph/osd"}
    export ETCD_KUBE_DATA_PATH=${ETCD_KUBE_DATA_PATH:-"/var/lib/etcd/kubernetes"}
    export ETCD_KUBE_ETC_PATH=${ETCD_KUBE_ETC_PATH:-"/etc/etcd/kubernetes"}
    export ETCD_CALICO_DATA_PATH=${ETCD_CALICO_DATA_PATH:-"/var/lib/etcd/calico"}
    export ETCD_CALICO_ETC_PATH=${ETCD_CALICO_ETC_PATH:-"/etc/etcd/calico"}

    # Hostnames
    export GENESIS_NODE_NAME=${GENESIS_NODE_NAME:-"node1"}
    export GENESIS_NODE_NAME=$(echo $GENESIS_NODE_NAME | tr '[:upper:]' '[:lower:]')
    export MASTER_NODE_NAME=${MASTER_NODE_NAME:-"node2"}
    export MASTER_NODE_NAME=$(echo $MASTER_NODE_NAME | tr '[:upper:]' '[:lower:]')

    # Charts
    export HTK_CHART_REPO=${HTK_CHART_REPO:-"https://github.com/openstack/openstack-helm"}
    export HTK_CHART_PATH=${HTK_CHART_PATH:-"helm-toolkit"}
    export HTK_CHART_BRANCH=${HTK_CHART_BRANCH:-"master"}
    export CEPH_CHART_REPO=${CEPH_CHART_REPO:-"https://github.com/openstack/openstack-helm"}
    export CEPH_CHART_PATH=${CEPH_CHART_PATH:-"ceph"}
    export CEPH_CHART_BRANCH=${CEPH_CHART_BRANCH:-"master"}
    export DRYDOCK_CHART_REPO=${DRYDOCK_CHART_REPO:-"https://github.com/att-comdev/drydock"}
    export DRYDOCK_CHART_PATH=${DRYDOCK_CHART_PATH:-"charts/drydock"}
    export DRYDOCK_CHART_BRANCH=${DRYDOCK_CHART_BRANCH:-"master"}
    export MAAS_CHART_REPO=${MAAS_CHART_REPO:-"https://github.com/att-comdev/maas"}
    export MAAS_CHART_PATH=${MAAS_CHART_PATH:-"charts/maas"}
    export MAAS_CHART_BRANCH=${MAAS_CHART_BRANCH:-"master"}
    export DECKHAND_CHART_REPO=${DECKHAND_CHART_REPO:-"https://github.com/att-comdev/deckhand"}
    export DECKHAND_CHART_PATH=${DECKHAND_CHART_PATH:-"charts/deckhand"}
    export DECKHAND_CHART_BRANCH=${DECKHAND_CHART_BRANCH:-"master"}
    export SHIPYARD_CHART_REPO=${SHIPYARD_CHART_REPO:-"https://github.com/att-comdev/shipyard"}
    export SHIPYARD_CHART_PATH=${SHIPYARD_CHART_PATH:-"charts/shipyard"}
    export SHIPYARD_CHART_BRANCH=${SHIPYARD_CHART_BRANCH:-"master"}
    export ARMADA_CHART_REPO=${ARMADA_CHART_REPO:-"https://github.com/att-comdev/armada"}
    export ARMADA_CHART_PATH=${ARMADA_CHART_PATH:-"charts/armada"}
    export ARMADA_CHART_BRANCH=${ARMADA_CHART_BRANCH:-"master"}
    export DIVINGBELL_CHART_REPO=${DIVINGBELL_CHART_REPO:-"https://github.com/att-comdev/divingbell"}
    export DIVINGBELL_CHART_PATH=${DIVINGBELL_CHART_PATH:-"divingbell"}
    export DIVINGBELL_CHART_BRANCH=${DIVINGBELL_CHART_BRANCH:-"master"}
    export TILLER_CHART_REPO=${TILLER_CHART_REPO:-"https://github.com/att-comdev/armada"}
    export TILLER_CHART_PATH=${TILLER_CHART_PATH:-"charts/tiller"}
    export TILLER_CHART_BRANCH=${TILLER_CHART_BRANCH:-"master"}

    #Kubernetes artifacts
    export KUBE_PROXY_IMAGE=${KUBE_PROXY_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export KUBE_ETCD_IMAGE=${KUBE_ETCD_IMAGE:-"quay.io/coreos/etcd:v3.0.17"}
    export KUBE_ETCDCTL_IMAGE=${KUBE_ETCDCTL_IMAGE:-"quay.io/coreos/etcd:v3.0.17"}
    export KUBE_ANCHOR_IMAGE=${KUBE_ANCHOR_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export KUBE_COREDNS_IMAGE=${KUBE_COREDNS_IMAGE:-"coredns/coredns:0.9.9"}
    export KUBE_APISERVER_IMAGE=${KUBE_APISERVER_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export KUBE_CTLRMGR_IMAGE=${KUBE_CTLRMGR_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export KUBE_SCHED_IMAGE=${KUBE_SCHED_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export KUBECTL_IMAGE=${KUBECTL_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export CALICO_CNI_IMAGE=${CALICO_CNI_IMAGE:-"quay.io/calico/cni:v1.11.0"}
    export CALICO_CTL_IMAGE=${CALICO_CTL_IMAGE:-"quay.io/calico/ctl:v1.6.1"}
    export CALICO_NODE_IMAGE=${CALICO_NODE_IMAGE:-"quay.io/calico/node:v2.6.1"}
    export CALICO_POLICYCTLR_IMAGE=${CALICO_POLICYCTLR_IMAGE:-"quay.io/calico/kube-controllers:v1.0.0"}
    export CALICO_ETCD_IMAGE=${CALICO_ETCD_IMAGE:-"quay.io/coreos/etcd:v3.0.17"}
    export CALICO_ETCDCTL_IMAGE=${CALICO_ETCDCTL_IMAGE:-"quay.io/coreos/etcd:v3.0.17"}
    export KUBE_KUBELET_TAR=${KUBE_KUBELET_TAR:-"https://dl.k8s.io/v1.8.6/kubernetes-node-linux-amd64.tar.gz"}

    # Images
    export TILLER_IMAGE=${TILLER_IMAGE:-"gcr.io/kubernetes-helm/tiller:v2.7.2"}
    export DRYDOCK_IMAGE=${DRYDOCK_IMAGE:-"quay.io/attcomdev/drydock:latest"}
    export ARMADA_IMAGE=${ARMADA_IMAGE:-"quay.io/attcomdev/armada:latest"}
    export PROMENADE_IMAGE=${PROMENADE_IMAGE:-"quay.io/attcomdev/promenade:latest"}
    export DECKHAND_IMAGE=${DECKHAND_IMAGE:-"quay.io/attcomdev/deckhand:latest"}
    export SHIPYARD_IMAGE=${SHIPYARD_IMAGE:-"quay.io/attcomdev/shipyard:latest"}
    export AIRFLOW_IMAGE=${AIRFLOW_IMAGE:-"quay.io/attcomdev/airflow:latest"}
    export MAAS_CACHE_IMAGE=${MAAS_CACHE_IMAGE:-"quay.io/attcomdev/maas-cache:latest"}
    export MAAS_REGION_IMAGE=${MAAS_REGION_IMAGE:-"quay.io/attcomdev/maas-region:latest"}
    export MAAS_RACK_IMAGE=${MAAS_RACK_IMAGE:-"quay.io/attcomdev/maas-rack:latest"}

    # Docker
    export DOCKER_SVCD="/etc/systemd/system/docker.service.d"
    export DOCKER_REPO_URL=${DOCKER_REPO_URL:-"http://apt.dockerproject.org/repo"}
    export DOCKER_PACKAGE=${DOCKER_PACKAGE:-"docker-engine=1.13.1-0~ubuntu-xenial"}

    # Filenames
    export ARMADA_CONFIG=${ARMADA_CONFIG:-"armada.yaml"}
    export UP_SCRIPT_FILE=${UP_SCRIPT_FILE:-"genesis.sh"}
}

function validateEnv {
    info "validating required ENV vars"

    # Validate environment
    [[ $GENESIS_NODE_IP == "NA" || $MASTER_NODE_IP == "NA" ]] \
        && exit_on_error "GENESIS_NODE_IP and MASTER_NODE_IP env vars must be set to correct IP addresses." $1

    [[ $CEPH_CLUSTER_NET == "NA" || $CEPH_PUBLIC_NET == "NA" ]] \
        && exit_on_error "CEPH_CLUSTER_NET and CEPH_PUBLIC_NET env vars must be set to correct IP subnet CIDRs." $1

    [[ $(hostname) != $GENESIS_NODE_NAME ]] \
        && exit_on_error "Local node hostname $(hostname) does not match GENESIS_NODE_NAME $GENESIS_NODE_NAME." $1

    [[ -z $(grep $GENESIS_NODE_NAME /etc/hosts | grep $GENESIS_NODE_IP) ]] \
        && exit_on_error "No /etc/hosts entry found for $GENESIS_NODE_NAME. Please add one." $1

    info "saving deployment environment to deploy-env.sh."
    env | xargs -n 1 -d '\n' echo "export" >> deploy-env.sh
}

function upgradeUbuntu {
    info "upgrading ubuntu os"
    . upgradeUbuntu.sh || exit_on_error "ucpdev: ubuntu os upgradation failed" $?
}

function setHostsInfo {
    info "setting hosts info"
    . setHostsInfo.sh || exit_on_error "ucpdev: hosts/name update failed" $?
}

function setupDocker {
    info "installing docker and jq packages"

    apt -qq update || exit_on_error "ucpdev: apt update for docker failed" $?
    apt -y install docker.io jq || exit_on_error "ucpdev: docker/jq installation failed" $?

    if [[ $PROXY_ENABLED == "true" ]]
    then 
        info "setting proxy for docker"
    	export DOCKER_SVCD="/etc/systemd/system/docker.service.d"
	mkdir $DOCKER_SVCD || error "ucpdev: failed to create '$DOCKER_SVCD'" $?
	
	echo "[Service]" | tee $DOCKER_SVCD/http-proxy.conf
	echo "Environment=\"HTTP_PROXY=$PROXY_ADDRESS\"" | tee -a $DOCKER_SVCD/http-proxy.conf
	echo "Environment=\"HTTPS_PROXY=$PROXY_ADDRESS\"" | tee -a $DOCKER_SVCD/http-proxy.conf
	echo "Environment=\"NO_PROXY=127.0.0.1,localhost,$GENESIS_NODE_NAME\"" | tee -a $DOCKER_SVCD/http-proxy.conf
	
	systemctl daemon-reload
	systemctl show --property Environment docker
        systemctl restart docker
    fi
}

function generateCerts {
    info "generating promenade certificates"

    # Generate certificates
    if [[ $PROXY_ENABLED == "true" ]]
    then
        docker run -e "http_proxy=$PROXY_ADDRESS" -e "https_proxy=$PROXY_ADDRESS" \
                   --rm -t -w /target \
                   -v $CONFIGS_DIR:/target ${PROMENADE_IMAGE} promenade generate-certs \
                   -o /target $(ls $CONFIGS_DIR) || exit_on_error "ucpdev: Promenade certificate generation failed." $?
    else
        docker run \
                   --rm -t -w /target \
                   -v $CONFIGS_DIR:/target ${PROMENADE_IMAGE} promenade generate-certs \
                   -o /target $(ls $CONFIGS_DIR) || exit_on_error "ucpdev: Promenade certificate generation failed." $?
    fi
}

function generateArtifacts {
    info "generating promenade artifacts"

    # Generate promenade join artifacts
    if [[ $PROXY_ENABLED == "true" ]]
    then
        docker run -e "http_proxy=$PROXY_ADDRESS" -e "https_proxy=$PROXY_ADDRESS" \
                   --rm -t -w /target \
                   -v $CONFIGS_DIR:/target ${PROMENADE_IMAGE} promenade build-all \
                   -o /target \
                   --validators $(ls $CONFIGS_DIR) || exit_on_error "ucpdev: Promenade artifacts generation failed." $?
    else
        docker run \
               --rm -t -w /target \
               -v $CONFIGS_DIR:/target ${PROMENADE_IMAGE} promenade build-all \
               -o /target \
               --validators $(ls $CONFIGS_DIR) || exit_on_error "ucpdev: Promenade artifacts generation failed." $?
    fi
}

function prepareConfigs {
    info "preparing configs"

    if [[ -d $CONFIGS_DIR ]]
    then
        info "removing $CONFIGS_DIR folder"
        rm -rf $CONFIGS_DIR || exit_on_error "ucpdev: failed to remove '$CONFIGS_DIR'" $?
    fi

    mkdir $CONFIGS_DIR || exit_on_error "ucpdev: failed to create '$CONFIGS_DIR'" $?
    chmod 777 $CONFIGS_DIR

    cat joining-host-config.yaml.sub | envsubst > $CONFIGS_DIR/joining-host-config.yaml
    cat armada-resources.yaml.sub | envsubst > $CONFIGS_DIR/armada-resources.yaml
    cat armada.yaml.sub | envsubst > ${ARMADA_CONFIG}
    cat Genesis.yaml.sub | envsubst > $CONFIGS_DIR/Genesis.yaml
    cat HostSystem.yaml.sub | envsubst > $CONFIGS_DIR/HostSystem.yaml
    cp Kubelet.yaml.sub $CONFIGS_DIR/Kubelet.yaml
    cat $K8S_NETWORK_YAML | envsubst > $CONFIGS_DIR/KubernetesNetwork.yaml
    cp Docker.yaml $CONFIGS_DIR/
    cp ArmadaManifest.yaml $CONFIGS_DIR/

    # Support a custom deployment for shipyard developers
    if [[ $SHIPYARD_PROD_DEPLOY == 'false' ]]
    then
      mkdir -p $AIRFLOW_PATH_DAG || exit_on_error "ucpdev: failed to create '$AIRFLOW_PATH_DAG'" $?
      mkdir -p $AIRFLOW_PATH_PLUGIN || exit_on_error "ucpdev: failed to create '$AIRFLOW_PATH_PLUGIN'" $?
      mkdir -p $AIRFLOW_PATH_LOG || exit_on_error "ucpdev: failed to create '$AIRFLOW_PATH_LOG'" $?
    fi
}

function runGenesis {
    info "running genesis"

    [[ $FORCE_DEPLOY || $SKIP_CONFIG_PREPARE -ne 1 ]] && prepareConfigs

    [[ $FORCE_DEPLOY || $SKIP_DOCKER -ne 1 ]] && setupDocker

    [[ $FORCE_DEPLOY || $SKIP_CERTS -ne 1 ]] && generateCerts

    [[ $FORCE_DEPLOY || $SKIP_ARTIFACTS -ne 1 ]] && generateArtifacts

    if [[ $FORCE_DEPLOY || $SKIP_GENESIS -ne 1 ]]
    then
        # Do Promenade genesis process
        . $CONFIGS_DIR/genesis.sh || exit_on_error "ucpdev: genesis process failed." $?
    fi

    # Setup kubeconfig
    mkdir $KUBE_CONFIG_DIR
    cp -r /etc/kubernetes/admin/pki $KUBE_CONFIG_DIR/pki
    cat /etc/kubernetes/admin/kubeconfig.yaml | sed -e 's/\/etc\/kubernetes\/admin/./' > $KUBE_CONFIG_DIR/config
}

function initHelm {
    info "initializing Helm"

    helm init
}

function deployUcp {
    info "deploying UCP"

    while [[ -z $(kubectl get pods -n kube-system | grep tiller | grep Running) ]]
    do
      echo 'Waiting for tiller to be ready.'
      sleep 10
    done

    if [[ $PROXY_ENABLED == "true" ]]
    then
        docker run -e "http_proxy=$PROXY_ADDRESS" -e "https_proxy=$PROXY_ADDRESS" \
                   -t -v ~/.kube:/armada/.kube \
                   -v $(pwd):/target --net=host ${ARMADA_IMAGE} apply /target/${ARMADA_CONFIG} || exit_on_error "ucpdev: deployment failed" $?
    else
        docker run -t -v ~/.kube:/armada/.kube \
                   -v $(pwd):/target --net=host ${ARMADA_IMAGE} apply /target/${ARMADA_CONFIG} || exit_on_error "ucpdev: deployment failed" $?
    fi

    echo 'UCP control plane deployed.'
}

# Make sure only root can deploy UCP
[[ "$(id -u)" != "0" ]] && exit_on_error "ucpdev: This script must be run as root" 1

info "===== ~: $BASH_SOURCE :~ ====="

[[ $FORCE_DEPLOY || $SKIP_OS_UPGRADE -ne 1 ]] && upgradeUbuntu

[[ $FORCE_DEPLOY || $SKIP_ETC_HOSTS -ne 1 ]] && setHostsInfo

initEnv

validateEnv

[[ $FORCE_DEPLOY || $SKIP_RUN_GENESIS -ne 1 ]] && runGenesis

[[ $FORCE_DEPLOY || $SKIP_HELM_INIT -ne 1 ]] && initHelm

deployUcp

info "===== ~: $BASH_SOURCE - Successful :~ ===== "
info ""
