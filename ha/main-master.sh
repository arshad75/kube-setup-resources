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

echo " ------------------ Initiating Kubernetes Cluster Main Master  ----------------"

kubeadm init --config /home/ubuntu/kubeadm-config.yaml

set -e

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

IP=`ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'`
IPCLUSTER=$IP:6443;echo "kubeadm join --token $(kubeadm token list | sed '1d' | head -1| awk '{print $1}') $IPCLUSTER --discovery-token-ca-cert-hash sha256:$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | awk '{print $2}')" > Join-token.txt

echo " ------------------ Installing the Weave CNI plugin ----------------"

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo " ------------------ Installing the Dashboard ----------------"

kubectl apply -f https://gist.githubusercontent.com/lc-kubeadm/5b8896b47ee046d33d73d51ef9dabc48/raw/d89fe9c5446dd9ee4b412d219c308bf2205003e0/kubernetes-dashboard.yaml
