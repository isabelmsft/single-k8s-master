#!/bin/bash

if [[ $(id -u) -ne 0 ]]; then
    echo "Root privelege required"
    exit
fi

# Install necessary packages
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
swapoff -a

# Initialize Cluster
kubeadm reset -y
kubeadm init --skip-phases=addon/kube-proxy --skip-phases=addon/coredns --ignore-preflight-errors=FileContent--proc-sys-net-bridge-bridge-nf-call-iptables
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
mkdir -p /etc/cni/net.d
cp 10-flannel.conflist /etc/cni/net.d

# Set up Apache server so SONiC can join Kubernetes master by downloading admin.conf
apt-get install apache2
mkdir -p /var/www/html
mkdir ~/certificates
cd ~/certificates
openssl req -x509 -newkey rsa:4096 -keyout apache.key -out apache.crt -days 365 -nodes
mkdir /etc/apache2/ssl
mv ~/certificates/* /etc/apache2/ssl/.

# Enable Apache SSL module
cp default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
a2enmod ssl
a2ensite default-ssl.conf
service apache2 restart

# Copy config file to be downloaded from Apache server dir
cp $HOME/.kube/config /var/www/html/admin.conf
chmod 755 /var/www/html/admin.conf
