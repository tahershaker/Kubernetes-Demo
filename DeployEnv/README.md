# Deploying Demo Environment

This Repo is created to hold several sub-repos that list automation scripts and step-by-step guides to build and deploy the demo environment. 

---

<p align="center">
    <img src="images/RancherDeploy.png">
</p>

---

## Repo Overview 

As a Solution Architect, you are asked to perform multiple **_Demos_** and **_Online Sessions_** to customers, partners, or new prospects. Delivering the **_Demos_** and **_Online Sessions_** requires having a Kubernetes environment up and running with Rancher solutions installed, and depending on the audience, some advanced features may need to be configured. Once the Kubernetes environment is built and Rancher is installed with the required advanced features configured, then you may use it as a lab for the **_Demos_** and **_Online Sessions_**.

This repo will help Solutions Architect to automate the building and the installation of the kubernetes environment along with the Rancher solution. The main objective of this repo is to add all required scripts, notes, diagrams, and step-by-step activities to perform the demo. Thus this repo will help deploying the required infrastructure, install the required solutions and applications, and list all use-cases to be perform in this demo. This repo will hold code, installation steps, configuration files, and much more to help Solution Architects build labs quickly and efficiently utilize their time. This repo will hold all the below:
* Code to automate the deployment of a Kubernetes environment (Mgmt Cluster) on AWS, this will include EC2, VPC, NAT, LB, and more.
* Code to automate the installation of a kubernetes cluster (Mgmt Cluster) using kubeadm
* Code to guide and automate the installation of kubernetes CNI (Calico) and Ingress on the Mgmt Cluster
* Step-By-Step Guide to deploy Rancher Manager on the Kubernetes Mgmt Cluster
* Code to automate the deployment of a Kubernetes environment (Prod Cluster) on AWS, this will include EC2, VPC, NAT, LB, and more.
* Code to automate the installation of a kubernetes cluster (Prod Cluster) using kubeadm
* Code to guide and automate the installation of kubernetes CNI (Calico) and Ingress on the Prod Cluster
* Demo configuration files (such as app YAML files and more) to configure the lab with some supporting resources to show-case Rancher features.
* Explanation of Use-Cases along with the supporting configuration files.
* Several reference pages to be used to explain the functionality of the product.

**Please Note:**
> Some code available in the repo may need to be adjusted from one SA to another to match the need and the identity of the SA. This is going to be highlighted in any sub-repo available in this main repo as needed.

---

## Demo Architecture

This demo environment is built and designed in a way to give the Solution Architect the ability to show as much use-cases as possible. Thus, the demo environment is going to be built with two different environment all deployed on AWS. The two environment and the purpose of each one are listed and explained as follow:
* **First Environment** is the main and called the **Management Environment (Mgmt)**. This environment consist of three EC2 instances and all the supporting objects (VPC, NAT GW, Load Balancer, and more...) to run these EC2 instance on AWS. These three EC2 instances will run a kubernetes cluster installed using kubeadm. This kubernetes cluster will act as the management cluster that will hold the Rancher Manager, Harbor, and any other management tools required for this demo. This cluster will be imported to the Rancher Manager.
* **Second Environment** is a supporting kubernetes cluster and is called **Prod Cluster**. This environment consist of three EC2 instances and all the supporting objects (VPC, NAT GW, Load Balancer, and more...) to run these EC2 instance on AWS. These three EC2 instances will run a kubernetes cluster installed using kubeadm. This cluster will be the main focus of the demos as it will hold all applications running to show the use cases in this demo. This cluster will be imported to the Rancher Manager.

> Below PIC provide a high-level design of the demo lab infrastructure

---

<p align="center">
    <img src="images/HLD-Main-Arch.png">
</p>

---

## Repo Usability

To use this repo, there are several steps to be executed which most of the are automated. Once all steps listed below are completed, then the solution architect will have a functional demo environment to start showing the use cases of the solutions.

> Step-By-Step

---

1. Deploy The Management Environment and Install all Required Components
   - To complete this step, please complete all actions listed in this [link](https://github.com/tahershaker/Kubernetes-Demo/tree/main/DeployEnv/DeployMgmtClustOnAWS).
   - Once this is completed, the management cluster will be up and running and all management components (including Rancher Manager) will be deployed.
2. Deploy the Prod Environment
   - To complete this step, please complete all actions listed in this [link](https://github.com/tahershaker/Kubernetes-Demo/tree/main/DeployEnv/DeployProdClusterOnAWS).

---

Once the above tasks are completed successfully, you can start with the Demo and showing the Use cases. 

_Please Note:_ During the completion of the above tasks, some of the use cases may have been already covered such as importing a kubernetes cluster through Rancher Manager.

As a next step, a solution architect should start the demo process and go through the required solution use cases. To help with the demo and showing the use cases, some use cases have been documented and automation script are also provided to save time, please refer to this [link](https://github.com/tahershaker/Kubernetes-Demo/tree/main/UseCases) if needed.

---

**Enjoy** :blush:

