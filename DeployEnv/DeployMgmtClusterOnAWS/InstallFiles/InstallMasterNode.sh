#!/usr/bin/env bash

#References: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
#References: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
#References: https://github.com/containerd/containerd/blob/main/docs/getting-started.md

# Add Kubernetes version and the IP CIDR that will be used in variables to be used in the script
KUBEVERSION=1.26.4-00
PODCIDR=172.30.0.0/16
SVCCIDR=172.29.0.0/16

# 1- Install containerd and require prerequisits
#-----------------------------------------------

# Disable Sawp
sudo swapoff -a

# Add overlay and br_netfilter kernel modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

# Load kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Enable IP Forwarding
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

#   Update the apt package and install required packages 
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl ipvsadm ipset watch tcpdump gpg

# Add Docker Repository Keys to download containerd and other required software
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

#   Update the apt package and install containerd
sudo apt-get update && sudo apt-get install -y containerd.io

# Apply required containerd configuration
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# restart and enable containerd service
sudo systemctl restart containerd && sudo systemctl enable containerd

#-----------------------------------------------

# 2- Install kubernetes using kubeadm
#------------------------------------

#--------- The legacy package repositories have been deprecated and frozen starting from September 13, 2023. 
#--------- Need to add key for new package repository
# Add pkgs.k8s.io package repositories Key to be able to download containerd and other required software
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list


# Download the public signing key for the Google package repositories
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/kubernetes-xenial.gpg

# Add the appropriate Kubernetes apt repository
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

#   Update apt package index, install kubelet, kubeadm and kubectl, and pin their version
sudo apt-get update && sudo apt-get install -y kubelet=${KUBEVERSION} kubeadm=${KUBEVERSION} kubectl=${KUBEVERSION}

# Disable auto-update
sudo apt-mark hold kubelet kubeadm kubectl

#   Initialize Kubeadm with required configuration
sudo kubeadm init --pod-network-cidr=${PODCIDR} --service-cidr=${SVCCIDR}

# Execute the following commands to configure kubectl (also returned by kubeadm init)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Print the kubeadm join command again just in case
sudo kubeadm token create --print-join-command

#------------------------------------------------------------
