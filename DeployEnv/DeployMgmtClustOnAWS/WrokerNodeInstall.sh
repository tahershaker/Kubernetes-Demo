#!/usr/bin/env bash
KUBEVERSION=1.26.4-00

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

#--------- The legacy package repositories have been deprecated and frozen starting from September 13, 2023. 
#--------- Need to add key for new package repository
# Add pkgs.k8s.io package repositories Key to be able to download containerd and other required software
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

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

#   Update apt package index, install kubelet, kubeadm and kubectl, and pin their version
sudo apt-get update && sudo apt-get install -y kubelet=${KUBEVERSION} kubeadm=${KUBEVERSION} kubectl=${KUBEVERSION}

# Disable auto-update
sudo apt-mark hold kubelet kubeadm kubectl

# Disable Sawp
sudo swapoff -a


#------------------------------------------------------------