# Deploy The Second - Prod - Kubernetes Cluster With kubeadm

This Repo is to provide automation scripts and a step-by-step guide to build the second kubernetes cluster for the demo environment. This cluster will act as a production cluster configured with kubeadm and holds all workload applications components.

---

<p align="center">
    <img src="images/KubernetesLogo.png">
</p>

---

## Repo Overview

> Production Cluster - \[Kubeadm\]

This repo provides the second step towards building a demo environment to be used to show the benefits, features, and use cases of the Rancher solutions. The Demo environment consists of two environments all hosted on AWS. This environment is called the **Production Cluster**. This repo will provide automation scripts along with a step-by-step guide to deploy the production cluster.

Please follow the steps listed below to build the production cluster.

---

## Environment Architecture  

The architecture of this environment is based on and AWS three EC2 instance deployed in a single region, single availability zones, and a single VPC. In this VPC there will be 2 subnets, public subnet and a private subnet. This is based on AWS architecture guide lines where the public subnet will be exposed to the internet to accept traffic from outside and the private subnet will hold all components and will be segregated from the internet traffic. The public subnet will have a NAT gateway and a Load Balancer to forward traffic coming in or going out of the environment. 

The three EC2 instance will then be configured with kubeadm to create a kubernetes cluster that will act as the production cluster and will hold all workload application components. All prerequisite will be installed and configured on this cluster such as Helm, Ingress, and more.

The architecture will be as follow:
* One AWS Region - by default London Region - eu-west-2
* One AWS Availability zone - by default the first AZ in the region
* On VPC with the CIDR of 10.11.0.0/16 - default name is of kube-demo-prod-vpc-01
* Two Subnets
  - Public Subnet with the CIDR of 10.11.10.0/24 - default name is kube-demo-prod-pub-sub-01
  - Private Subnet with the CIDR of 10.11.11.0/24 - default name is kube-demo-prod-priv-sub-01
* Two Security Groups (One for each subnet)
  - Public Security Group allow tcp ports 22, 443, 6443 from any, any port from 10.11.0.0/16 - default name is kube-demo-prod-pub-sg-01
  - Private Security Group allowing any port from 10.11.0.0/16 - default name is kube-demo-prod-priv-sg-01
* NAT Gateway deployed in the public subnet and act as the GW for the private subnet - default name is of kube-demo-prod-ngw-01
* Internet Gateway attached to the VPC - default name is of kube-demo-prod-igw-01
* Two Routing tables (One for each subnet)
  - Public Routing Table pointing to the Internet Gateway as the default gateway - default name is of kube-demo-prod-pub-rt-01
  - Private Routing Table pointing to the NAT Gateway as the default gateway - default name is of kube-demo-prod-priv-rt-01
* Network Load Balancer deployed in the public subnet for incoming traffic to the Master Node - default name is of kube-demo-prod-nlb-01
* Load Balancer Target Groups for the SSH traffic coming to the Master Node

> Below PIC is a LLD for the Environment Architecture

---

<p align="center">
    <img src="images/LLD-Arch.png">
</p>

---

## Pre-Requisites  

To be able to follow along with this below step-by-step guid, several pre-requisites must be available first.
1. Download this Repo to your local machine (preferred to download the full repository not only this sub-repo)
2. AWS CLI version 2 to be installed
3. JQ to be installed
4. AWS account with sufficient privilege (preferred admin privilege)
5. AWS STS Token or account credentials to be configured for the AWS CLI

> Please Note: The used script in this repo is only tested on a MacBook, development is taking place to ensure success of the used scripts on other operating systems

---

## Step-By-Step Guide

Please follow the below step-by-step guide to deploy the Management Cluster

> Summary 

1. Step 1: Deploy AWS Infrastructure using provided bash/AWS CLI script - [Link](#Step-1---Deploy-AWS-Infrastructure)
2. Step 2: Install Kubernetes Cluster on EC2 Instances using provided bash/Kubeadm script - [Link](#Step-2---Install-Kubernetes-Cluster-on-EC2-Instances)
3. Step 3: Install Ingress on the Kubernetes Cluster using provided step-by-step guide - [Link](#Step-3---Install-Ingress-on-the-Kubernetes-Cluster)
4. Step 4: Install Helm in your kubernetes using provided step-by-step guide - [Link](#Step-4---Install-Helm-in-your-kubernetes)
5. Step 5: Deploy and Install Cert Manager through Helm using provided step-by-step guide - [Link](#Step-5---Deploy-and-Install-Cert-Manager-through-Helm)

---

### Step 1 - Deploy AWS Infrastructure

First step in this guide is to deploy the AWS infrastructure based on the provided architecture. To help in this process, and automation script is provided in this [link](https://github.com/tahershaker/Kubernetes-Demo/blob/main/DeployEnv/DeployProdClustOnAWS/AwsDeployProdCluster.sh) that will automatically deploy all the AWS infrastructure. Please Note: To run the script, first you need to download the repo and add the AWS credentials to the AWS CLI.

Unfortunately, all the variables are hard-coded in to the script and development is in place to allow passing argument to the script to provide the ability to change the variables. These variable will hold the Region, Name Prefix, IP Addresses, Folder Location and more. List of the variables that are hard-coded are:

```bash
S_DIR=$(dirname "$0") # Get PWD of the running Script
MN01_1_CONF="${S_DIR}/ConfigFiles/kube-demo-mn01.yml" # Add File path for the CloudInit config file for the master node
WN01_1_CONF="${S_DIR}/ConfigFiles/kube-demo-wn01.yml" # Add File path for the CloudInit config file for the first worker node
WN02_1_CONF="${S_DIR}/ConfigFiles/kube-demo-wn02.yml" # Add File path for the CloudInit config file for the second worker node
REGION="eu-west-2" #Add default for the region to be London Region
AZ1="${REGION}a" # Add defualt Availability Zone
OWNER="Taher" #Add default for the owner to be Taher
PREFIX="kube-demo-Mgmt-" #Add default for the prefix used with the names of all resources to be kube-demo-
TAG="kube-demo" #Add default for the TAG added to all resources to be kube-demo
FOLDER="/Users/shakert/Downloads/" #Add default for the output folder to be /Users/shakert/Downloads/
AMI="ami-0ff1c68c6e837b183" #Add default for the AMI ID to be ami-02556c56aa890545b - Ubuntu Server 20.04 LTS (HVM), SSD Volume Type 64-bit x86
KEYPAIR_NAME="kube-demo-key-pairs" #Add default for the Key-Pair name to be kube-demo-key-pairs
KEYPAIR_FILE="${FOLDER}${KEYPAIR_NAME}.pem" # Add default folder path to download EC2 Key-Pair if not exist
VPC_NAME="${PREFIX}vpc-01" # Add default name for VPC
SUBNET1_NAME="${PREFIX}pub-sub-01" # Add default name for Public Subnet
SUBNET1A_NAME="${PREFIX}priv-sub-01" # Add default name for Private Subnet
PUBRT_NAME="${PREFIX}pub-rt-01" # Add default name for Public Subnet routing table
PRIVRT1_NAME="${PREFIX}priv-rt-01" # Add default name for Private Subnet Routing Table
PUBSGROUP_NAME="${PREFIX}pub-sg-01" # Add default name for Public Security Group
PRIVSGROUP_NAME="${PREFIX}priv-sg-01" # Add default name for Private Security Group
EIP1_NAME="${PREFIX}eip-01" # Add default name for Elastic IP
IGW_NAME="${PREFIX}igw-01" # Add default name for Internet Gateway
NATGW1_NAME="${PREFIX}ngw-01" # Add default name for NAT Gateway
NETLB1A_NAME="${PREFIX}netlb-01a" # Add default name for Network Load Balancer
LB1_SSH_TG_NAME="${PREFIX}01-ssh-tg-01" # Add default name for load Balancer target group for SSH
LB1_Kubectl_TG_NAME="${PREFIX}01-kube-tg-01" # Add default name for load Balancer target group for Kubectl
MHOST_DISK_CONFIG='DeviceName=/dev/sda1,Ebs={VolumeSize=90,DeleteOnTermination=true}'
WHOST_DISK_CONFIG='DeviceName=/dev/sda1,Ebs={VolumeSize=70,DeleteOnTermination=true}'
MNODE1A_NAME="${PREFIX}01-master-01" # Add default name for Master Node
MNODE1A_IP="10.10.11.100" # Add default IP address for Master Node
WNODE1A_NAME="${PREFIX}01-worker-01" # Add default name for Worker Node 1
WNODE1A_IP="10.10.11.101" # Add default IP address for worker Node 1
WNODE1B_NAME="${PREFIX}01-worker-02" # Add default name for Worker Node 2
WNODE1B_IP="10.10.11.102" # Add default IP address for Worker Node 2
JSON_FILE="${FOLDER}resources-ids-$(date '+%Y-%m-%d-%H-%M-%S').json"
```

1. Navigate to the script location and make the script file excusable, Script name is AwsDeployMgmtCluster.sh

```bash 
chmod u+x AwsDeployProdCluster.sh
```
<p align="center">
    <img src="images/ScriptExcutable.png">
</p>

2. Run the Script, Please Note: Running the script is going to take several minutes.

```bash
./AwsDeployMgmtCluster.sh
```
<p align="center">
    <img src="images/RunScript.png">
</p>

3. Get the Public FQDN and IP of the Load balancer.

- Once the script successfully completed, it will print the public FQDN of the load balancer at the end of the script. Copy this IFQDN and save it somewhere. Also use nslookup to get the IP of the FQDN and save it with the FQDN.
```bash 
nslookup <fqdn>
```
<p align="center">
    <img src="images/GetFqdnIp.png">
</p>

- The Output of starting the script should look like
<p align="center">
    <img src="images/StartOfScript.png">
</p>

- The output of the end of the script should look like
<p align="center">
    <img src="images/EndOfScript.png">
</p>

---