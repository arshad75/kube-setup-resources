# kube-setup-resources
Kubernetes Cluster setup resources

---------------------------------------------------------------------------------------------------------------------------------
# Set up a High Availability etcd cluster with kubeadm

This task walks through the process of creating a high availability etcd cluster of three members that can be used as an external etcd when using kubeadm to set up a kubernetes cluster.

Launch three Ubuntu Server 16.04 LTS Servers and make sure that the three hosts can talk to each other over ports 2379 and 2380. 

Install # kubectl # kubeadm and # docker by running the below commands 
$sudo su
#curl https://raw.githubusercontent.com/lc-kubeadm/kube-setup-resources/master/ha/etcd/etcd-node.sh > etcd-node.sh ##rupdate the url after the git push from laptop

-#chmod +x etcd-node.sh
-#apt-get update -y
-#./etcd-node.sh

Check the docker kubeadm and kubelet version
-#kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"13", GitVersion:"v1.13.2", GitCommit:"cff46ab41ff0bb44d8584413b598ad8360ec1def", GitTreeState:"clean", BuildDate:"2019-01-10T23:33:30Z", GoVersion:"go1.11.4", Compiler:"gc", Platform:"linux/amd64"}
-#kubelet --version
Kubernetes v1.13.2
-#docker version
Client:
 Version:           18.06.1-ce
 API version:       1.38
 Go version:        go1.10.3
 Git commit:        e68fc7a
 Built:             Tue Aug 21 17:24:56 2018
 OS/Arch:           linux/amd64
 Experimental:      false

Server:
 Engine:
  Version:          18.06.1-ce
  API version:      1.38 (minimum version 1.12)
  Go version:       go1.10.3
  Git commit:       e68fc7a
  Built:            Tue Aug 21 17:23:21 2018
  OS/Arch:          linux/amd64
  Experimental:     false

First run the below command on all the three ETCD cluster hosts {HOST0,HOST1,HOST2} as a privileged user. 

-#cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true
Restart=always
EOF

-#systemctl daemon-reload
-#systemctl restart kubelet

Now, on the first node (HOST0) of the etcd cluster generate the necessary certifigates by running the below shell script

Run the below command on the first Node to generate the ca.crt & ca.key.
#kubeadm init phase certs etcd-ca

This creates two files
 ./etc/kubernetes/pki/etcd/ca.crt
 ./etc/kubernetes/pki/etcd/ca.key
 
Now create certificates for each member by running the below commands. 

-#curl https://github.com/lc-kubeadm/kube-setup-resources/tree/master/ha/etcd-setup/etcd-certs.sh > etcd-certs.sh ##rupdate the url after the git push from laptop
-#chmod +x etcd-certs.sh 
-#vim etcd-certs.sh ## update the HOST0, HOST1, and HOST2 in the script with the ip's of the etcd cluster nodes. 
-#./etcd-certs.sh
-#cd /tmp/   ## The certificates are saved in the temp dir with the host name.

When you run the etcd-certs.sh script the keys and certs for the HOST0 are moved to the /etc/kubernetes/pki and /etc/kubernetes/pki/etcd/ folder respectively and the kubeadmcfg.yaml is saved at /tmp/{HOST0}/ dir.

The certificates and kubeadm configs for the {HOST1 and HOST2} are saved in /tmp/{HOST1} and /tmp/{HOST2} dir of HOST0 Server. 

The certificates have been generated and now they must be moved to their respective hosts.

Copy the /tmp/{HOST1}/pki to {HOST1}/etc/kubernetes/ dir.
Copy the /tmp/{HOST1}/kubeadmcfg.yaml to {HOST1}/etc/ubuntu/ dir.

Copy the /tmp/{HOST2}/pki to {HOST2}/etc/kubernetes/ dir.
Copy the /tmp/{HOST2}/kubeadmcfg.yaml to {HOST1}/etc/ubuntu/ dir.

Ensure all expected files exist after they are copied 

The complete list of required files on $HOST0 is:

/tmp/{HOST0}
└── kubeadmcfg.yaml
---
/etc/kubernetes/pki
  - apiserver-etcd-client.crt
  - apiserver-etcd-client.key
└── etcd
    ├── ca.crt
    ├── ca.key
    ├── healthcheck-client.crt
    ├── healthcheck-client.key
    ├── peer.crt
    ├── peer.key
    ├── server.crt
    └── server.key
    
On HOST1:

/home/ubuntu/
└── kubeadmcfg.yaml
---
/etc/kubernetes/pki
├── apiserver-etcd-client.crt
├── apiserver-etcd-client.key
└── etcd
    ├── ca.crt
    ├── healthcheck-client.crt
    ├── healthcheck-client.key
    ├── peer.crt
    ├── peer.key
    ├── server.crt
    └── server.key

On HOST2

\/home/ubuntu/
\└── kubeadmcfg.yaml
---
\/etc/kubernetes/pki
\├── apiserver-etcd-client.crt
\├── apiserver-etcd-client.key
\└── etcd
\    ├── ca.crt
\    ├── healthcheck-client.crt
\    ├── healthcheck-client.key
\    ├── peer.crt
\    ├── peer.key
\    ├── server.crt
\    └── server.key


Create the static pod manifests
Now that the certificates and configs are in place it’s time to create the manifests. On each host run the kubeadm command to generate a static manifest for etcd.

On HOST0 #kubeadm init phase etcd local --config=/tmp/${HOST0}/kubeadmcfg.yaml
On HOST1 #kubeadm init phase etcd local --config=/home/ubuntu/kubeadmcfg.yaml
On HOST2 #kubeadm init phase etcd local --config=/home/ubuntu/kubeadmcfg.yaml

Check the cluster health on HOST0

#export ETCD_TAG=v3.2.24
#export HOST0=(ip addr of HOST0)

#docker run --rm -it \
--net host \
-v /etc/kubernetes:/etc/kubernetes quay.io/coreos/etcd:${ETCD_TAG} etcdctl \
--cert-file /etc/kubernetes/pki/etcd/peer.crt \
--key-file /etc/kubernetes/pki/etcd/peer.key \
--ca-file /etc/kubernetes/pki/etcd/ca.crt \
--endpoints https://${HOST0}:2379 cluster-health

OUTPUT
...
cluster is healthy
 

---------------------------------------------------------------------------------------------------------------------------
