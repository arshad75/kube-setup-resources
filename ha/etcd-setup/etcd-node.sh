#!/bin/bash

#exit -1
KUBELET_VERSION="1.13.2-00"
KUBEADM_VERSION="1.13.2-00"
KUBECTL_VERSION="1.13.2-00"
DOCKER_VERSION="18.06.1~ce~3-0~ubuntu"


echo " ------------------ Kubeadm kubernetes installer ----------------"
echo " ------------------ installer for ETCD node    ----------------"

#apt-mark unhold kubelet kubeadm docker-ce
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

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"


apt-get update

apt-get install  kubelet=$KUBELET_VERSION kubeadm=$KUBEADM_VERSION docker-ce=$DOCKER_VERSION -y

#apt install kubectl=$KUBECTL_VERSION && apt-mark hold kubectl

apt-mark hold kubelet kubeadm  docker-ce


cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true
Restart=always
EOF

systemctl daemon-reload
systemctl restart kubelet
