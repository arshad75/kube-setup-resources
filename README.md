# kube-setup-resources
Kubernetes Cluster setup resources

---------------------------------------------------------------------------------------------------------------------------------
# Set up a High Availability etcd cluster with kubeadm

This task walks through the process of creating a high availability etcd cluster of three members that can be used as an external etcd when using kubeadm to set up a kubernetes cluster.  

Launch three Ubuntu 16.04 LTS Servers and make sure that the three hosts can talk to each other over ports 2379 and 2380.   

Install # kubelet # kubeadm and # docker by running the below commands   
$sudo su  
#apt-get update -y  
#curl https://raw.githubusercontent.com/lc-kubeadm/kube-setup-resources/master/ha/etcd-setup/etcd-node.sh > etcd-node.sh  
#chmod +x etcd-node.sh  
#./etcd-node.sh  

Check the docker kubeadm and kubelet version  
#kubeadm version  
kubeadm version: &version.Info{Major:"1", Minor:"13", GitVersion:"v1.13.2", GitCommit:"cff46ab41ff0bb44d8584413b598ad8360ec1def", GitTreeState:"clean", BuildDate:"2019-01-10T23:33:30Z", GoVersion:"go1.11.4", Compiler:"gc", Platform:"linux/amd64"}
#kubelet --version  
Kubernetes v1.13.2  
#docker version  
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

Now, on the first node (HOST0) of the etcd cluster generate the necessary certifigates by running the below shell script    
  
Run the below command on the first Node to generate the ca.crt & ca.key.  
#kubeadm init phase certs etcd-ca  
  
This creates two files  
 ./etc/kubernetes/pki/etcd/ca.crt  
 ./etc/kubernetes/pki/etcd/ca.key  
   
Now create certificates for each member by running the below commands.  
  
#curl https://raw.githubusercontent.com/lc-kubeadm/kube-setup-resources/master/ha/etcd-setup/etcd-certs.sh > etcd-certs.sh 
#chmod +x etcd-certs.s  
#vim etcd-certs.sh ## update the HOST0, HOST1, and HOST2 in the script with the ip's of the etcd cluster nodes.  
#./ha/etcd-setup/etcd-certs.sh  
#cd /tmp/  ## The certificates are saved in the temp dir with the host name.  
  
When you run the etcd-certs.sh script the keys and certs for the HOST0 are moved to the /etc/kubernetes/pki and /etc/kubernetes/pki/etcd/ folder respectively and the kubeadmcfg.yaml is saved at /tmp/{HOST0}/ dir.  
  
The certificates and kubeadm configs for the {HOST1 and HOST2} are saved in /tmp/{HOST1} and /tmp/{HOST2} dir of HOST0 Server.  
  
The certificates have been generated and now they must be moved to their respective hosts.  
  
Copy the /tmp/{HOST1}/pki to {HOST1}/etc/kubernetes/ dir.  
Copy the /tmp/{HOST1}/kubeadmcfg.yaml to {HOST1}/etc/ubuntu/ dir.  

Copy the /tmp/{HOST2}/pki to {HOST2}/etc/kubernetes/ dir.  
Copy the /tmp/{HOST2}/kubeadmcfg.yaml to {HOST1}/etc/ubuntu/ dir.  
    
Ensure all expected files exist after they are copied  
  
The complete list of required files on $HOST0 is:  
  
On HOST0  
  
/tmp/{HOST0}  
- kubeadmcfg.yaml  
/etc/kubernetes/pki  
  - apiserver-etcd-client.crt  
  - apiserver-etcd-client.key  
 - etcd  
    - ca.crt  
    - ca.key  
    - healthcheck-client.crt  
    - healthcheck-client.key  
    - peer.crt  
    - peer.key  
    - server.crt  
    - server.key  
      
On HOST1  
  
/home/ubuntu/  
- kubeadmcfg.yaml  
/etc/kubernetes/pki  
  - apiserver-etcd-client.crt  
  - apiserver-etcd-client.key  
 - etcd  
    - ca.crt  
    - healthcheck-client.crt  
    - healthcheck-client.key  
    - peer.crt  
    - peer.key  
    - server.crt  
    - server.key  
  
On HOST2  
  
/home/ubuntu/  
- kubeadmcfg.yaml  
 /etc/kubernetes/pki  
  - apiserver-etcd-client.crt  
  - apiserver-etcd-client.key    
 - etcd  
    - ca.crt  
    - healthcheck-client.crt  
    - healthcheck-client.key  
    - peer.crt  
    - peer.key  
    - server.crt  
    - server.key  
  
Create the static pod manifests  
Now that the certificates and configs are in place it’s time to create the manifests. On each host run the kubeadm command to generate a static manifest for etcd.  
  
On HOST0 #kubeadm init phase etcd local --config=/tmp/${HOST0}/kubeadmcfg.yaml  
On HOST1 #kubeadm init phase etcd local --config=/home/ubuntu/kubeadmcfg.yaml  
On HOST2 #kubeadm init phase etcd local --config=/home/ubuntu/kubeadmcfg.yaml  
  
Check the cluster health on HOST0  
  
#export ETCD_TAG=v3.2.24  
#export HOST0=(ip addr of HOST0)  

#curl https://raw.githubusercontent.com/lc-kubeadm/kube-setup-resources/master/ha/etcd-setup/cluster-health.sh > cluster-health.sh  
#chmod +x cluster-health.sh  
#./cluster-health.sh  
  
OUTPUT  
...  
cluster is healthy  

# Setting up HA Proxy Load Balancer  

Launch an Ubuntu 16.04 LTS Server.  

Run the below commands to install the HA Proxy Server.

$sudo su
#apt-get update && apt-get install -y haproxy 
#mv /etc/haproxy/haproxy.cfg{,.back}

#vi /etc/haproxy/haproxy.cfg

update the hostname and ip address of all the masters in the haproxy.cfg.

Now, start the HAProxy server
#systemctl start haproxy
  
# Kubernetes Main Master Initialization  
  
Launch an Ubuntu 16.04 LTS Server.  


SSH to the server and run the below commands.  

### Copy the {ca.crt apiserver-etcd-client.crt & apiserver-etcd-client.key} certificates from HOST0 of the ETCD cluster to the Main Master Server and save the apiserver-etcd-client.crt & apiserver-etcd-client.key to /etc/kubernetes/pki and car.crt to /etc/kubernetes/pki/etcd dir of the Main Master Server.   

#sudo su  
#apt-get update -y  
#cd /home/ubuntu  
#curl https://raw.githubusercontent.com/lc-kubeadm/kube-setup-resources/master/ha/kubeadm-config.yaml > kubeadm-config.yaml   
#vim kubeadm-config.yaml  
Edit the kubeadm-config.yaml and update the HOST0,HOST1,HOST2 IPs and controlPlaneEndpoint: "10.X.X.X:6443" with the IP address of the HA Proxy Load Balancer.  
  
##### Install # kubectl # kubelet # kubeadm and # docker by running the below commands  
#curl https://raw.githubusercontent.com/lc-kubeadm/kube-setup-resources/master/ha/main-master.sh > main-master.sh      
#chmod +x main-master.sh  
#./main-master.sh  
  
Once the Main master is initialized, run the below command to save the token to a text file.  

IPCLUSTER=$IP:6443;echo "kubeadm join --token $(kubeadm token list | sed '1d' | head -1| awk '{print $1}') $IPCLUSTER --discovery-token-ca-cert-hash sha256:$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | awk '{print $2}')" > Join-token.txt  
  
  
# Adding More Masters  
  
Launch an Ubuntu 16.04 LTS Server.  
  
SSH to the server and run the below commands.  
#sudo su  
#apt-get update -y  
#cd /home/ubuntu  
#curl https://raw.githubusercontent.com/lc-kubeadm/kube-setup-resources/master/ha/masters.sh > masters.sh   
#chmod +x masters.sh  
#./masters.sh
 
Now, Join the Cluster as a Master Node.  
- Make sure the first control plane node is fully initialized.  
- Copy certificates between the first control plane node and the other control plane nodes.  
- Join each control plane node with the join command that you saved to a text file, plus add the --experimental-control-plane flag.  
  

# Adding Worker Nodes  

Now, add Worker Nodes to  
  
Launch an Ubuntu 16.04 LTS Server.   
    
SSH to the server and run the below commands.  
#sudo su  
#apt-get update -y  
#cd /home/ubuntu  
#curl https://raw.githubusercontent.com/lc-kubeadm/kube-setup-resources/master/ha/worker-setup.sh > worker-setup.sh 
#chmod +x worker-setup.sh  
#./worker-setup.sh  
  
Now, Join the Cluster as a Worker Node by running the join command that you saved to a text file and do not add --experimental-control-plane flag.  


Add Worker Role to the workers by running the below command. 

kubectl label NODE-NAME node-role.kubernetes.io/worker=worker


# Accessing the Dashboard   
  
To access the Dashboard Import the kubecfg.p12 certificate, reopen your browser, and visit the Kubernetes Dashboard URL. Accept any warning and you should see the authentication page. You can skip the login and check you are not able to perform any task.  
  
kubecfg.p12 certificate was generated during the Main Master Setup and is stored on the Main Master Server at /home/ubuntu/kubecfg.p12.  
  
  
#### https://HA-PROXY-SERVER-IP:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login  
  
The TOKEN to login to the Dashboard was generated during the Main Master setup and has been saved at /home/ubuntu/login_token   
  
SSH to the Main Master and cat /home/ubuntu/login_token to get the login token.  


# Configuring remote cluster control

One more things that we left to do is to configure a remote kubectl utility, that we’ll use for controlling our cluster.

Launch an Ubuntu 16.04 LTS Server.   
    
SSH to the server and run the below commands.  
#sudo su  
#apt-get update -y  
#cd /home/ubuntu  
#curl https://raw.githubusercontent.com/lc-kubeadm/kube-setup-resources/master/ha/remote-api-server.sh > remote-api-server.sh   
#chmod +x remote-api-server.sh     
#./remote-api-server.sh   
  
Copy the kubectl config file from the Main Master node to the Remote API Server Node.   
The Kubectl config file is located at ~/.kube/config on the Main Master Node, extract the config file and import it to the Remote API Server at ~/.kube/ dir.   
  
Now, run the below command to confirm from the remote API server 
$ kubectl get nodes  
  
    
    
