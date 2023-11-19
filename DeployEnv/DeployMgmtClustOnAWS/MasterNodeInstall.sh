#!/usr/bin/env bash
KUBEVERSION=1.26.4-00
PODCIDR=172.30.0.0/16
SVCCIDR=172.29.0.0/16

#Install Containerd On Server
#References: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
#   Load kernel modules and modify system settings as a prerequisites (Overlay - Netfilter - IpForwarding).

# Modify system setting and configuration by adding overlay and br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Load kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

#   Install Containerd
sudo apt-get update && sudo apt-get install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd

#------------------------------------------------------------


#Install Kubeadm and Kubernetes Components using Kubeadm
#References: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
#   Let IPTables to see the bridged traffic.

# Configure Bridge NetFilter
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

# Configure IPTables to see bridge traffic
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Reload systemclt
sudo sysctl --system

#   Update the apt package index and install required packages 
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl ipvsadm ipset watch tcpdump gpg

#   Download the public signing key for the Kubernetes package repositories
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

#   Add the Kubernetes apt repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

#   Update apt package index, install kubelet, kubeadm and kubectl, and pin their version
sudo apt-get update && sudo apt-get install -y kubelet=${KUBEVERSION} kubeadm=${KUBEVERSION} kubectl=${KUBEVERSION}

# Disable auto-update
sudo apt-mark hold kubelet kubeadm kubectl

# Disable Sawp
sudo swapoff -a

#   Initialize Kubeadm with required configuration
sudo kubeadm init --pod-network-cidr=${PODCIDR} --service-cidr=${SVCCIDR}

# Execute the following commands to configure kubectl (also returned by kubeadm init)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


#------------------------------------------------------------