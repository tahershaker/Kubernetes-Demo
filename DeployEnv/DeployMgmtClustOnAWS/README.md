# Deploy The First - MGMT - Kubernetes Cluster With kubeadm

This Repo is to provide automation scripts and a step-by-step guide to build the first kubernetes cluster for the demo environment. This cluster will act as a management cluster configured with kubeadm and holds all management components such as the **Rancher Manager**.

---

<p align="center">
    <img src="images/KubernetesLogo.png">
</p>

---

## Repo Overview

> Management Cluster - \[Kubeadm\]

This repo provides the first step towards building a demo environment to be used to show the benefits, features, and use cases of the Rancher solutions. The Demo environment consists of three environments all hosted on AWS. This environment is called the **Management Cluster**. This repo will provide automation scripts along with a step-by-step guide to deploy the management cluster.

Please follow the steps listed below to build the management cluster.

---

## Environment Architecture  

The architecture of this environment is based on and AWS three EC2 instance deployed in a single region, single availability zones, and a single VPC. In this VPC there will be 2 subnets, public subnet and a private subnet. This is based on AWS architecture guide lines where the public subnet will be exposed to the internet to accept traffic from outside and the private subnet will hold all components and will be segregated from the internet traffic. The public subnet will have a NAT gateway and a Load Balancer to forward traffic coming in or going out of the environment. 

The three EC2 instance will then be configured with kubeadm to create a kubernetes cluster that will act as the management cluster and will hold all management components such as the **Rancher Manager**. All prerequisite will be installed and configured on this cluster such as Helm, Ingress, and more.

The architecture will be as follow:
* One AWS Region - by default London Region - eu-west-2
* One AWS Availability zone - by default the first AZ in the region
* On VPC with the CIDR of 10.10.0.0/16 - default name is of kube-demo-vpc-01
* Two Subnets
  - Public Subnet with the CIDR of 10.10.10.0/24 - default name is kube-demo-pub-sub-01
  - Private Subnet with the CIDR of 10.10.11.0/24 - default name is kube-demo-priv-sub-01
* Two Security Groups (One for each subnet)
  - Public Security Group allowing tcp ports 22, 443, 6443 from any, any port from 10.10.0.0/16 - default name is kube-demo-pub-sg-01
  - Private Security Group allowing any port from 10.10.0.0/16 - default name is kube-demo-priv-sg-01
* NAT Gateway deployed in the public subnet and act as the GW for the private subnet - default name is of kube-demo-ngw-01
* Internet Gateway attached to the VPC - default name is of kube-demo-igw-01
* Two Routing tables (One for each subnet)
  - Public Routing Table pointing to the Internet Gateway as the default gateway - default name is of kube-demo-pub-rt-01
  - Private Routing Table pointing to the NAT Gateway as the default gateway - default name is of kube-demo-priv-rt-01
* Network Load Balancer deployed in the public subnet for incoming traffic to the Master Node - default name is of kube-demo-nlb-01
* Two Load Balancer Target Groups one for the SSH traffic and the other for the kubectl traffic coming to the Master Node

> Below PIC is a LLD for the Environment Architecture

---

<p align="center">
    <img src="images/LLD-Arch.png">
</p>

---

# Step-By-Step Guide

Please follow the below step-by-step guide to deploy the Management Cluster

---

### Step 1: Deploy the AWS Infrastructure 


