#!/bin/bash

#exit -1
KUBECTL_VERSION="1.13.2-00"

echo " ------------------ Kubectl kubernetes installer ----------------"
echo " ------------------ installer for Kubernetes Remote API Server ----------------"

#apt purge kubelet kubeadm kubectl docker-ce

apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update


apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common -y

apt-get update

apt install kubectl=$KUBECTL_VERSION && apt-mark hold kubectl

apt-mark hold kubectl

echo " ------------------  kubernetes Remote API Server installer | Finised  ----------------"
