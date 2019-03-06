#!/bin/bash

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

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"


apt-get update

apt-get install -y kubelet kubeadm kubectl docker-ce=18.06.1~ce~3-0~ubuntu
apt-mark hold kubelet kubeadm kubectl docker-ce

echo " ------------------ Kubeadm kubernetes installer | Finised  ----------------"

echo " ------------------ Initiating Kubernetes Cluster First Master  ----------------"

kubeadm init --kubeconfig=/home/ubutu/kubeconfig.sh

set -e
