# Kubernetes Demo with Rancher Solutions

This Repo is created to provide a level of understanding of **Rancher** solutions offerings, cloud-native architecture, and building a CI/CD pipeline with Rancher product offerings.

---

<p align="center">
    <img src="images/RancherLogo.png">
</p>

---

## Repo Overview 

As a Solution Architect, you are asked to perform multiple **_Demos_** and **_Online Sessions_** to customers, partners, or new prospects. Delivering the **_Demos_** and **_Online Sessions_** requires having a Kubernetes environment up and running with Rancher solutions installed, and depending on the audience, some advanced features may need to be configured. Once the Kubernetes environment is built and Rancher is installed with the required advanced features configured, then you may use it as a lab for the **_Demos_** and **_Online Sessions_**.

This repo will help Solutions Architect to automate the building and the installation of the kubernetes environment along with the Rancher solution. The main objective of this repo is to add all required scripts, notes, diagrams, and step-by-step activities to perform the demo. Thus this repo will help deploying the required infrastructure, install the required solutions and applications, and list all use-cases to be perform in this demo. This repo will hold code, installation steps, configuration files, and much more to help SA build labs quickly and efficiently utilize their time. This repo will hold all the below:
* Code to automate the deployment of a Kubernetes environment (Mgmt Cluster) on AWS, this will include EC2, VPC, NAT, LB, and more.
* Code to guide and automate the installation of kubernetes CNI (Calico) and Ingress on the Mgmt Cluster
* Code to automate the installation of a kubernetes cluster (Mgmt Cluster) using kubeadm
* Code + Step-By-Step Guide to deploy Rancher Manager on the Kubernetes Mgmt Cluster
* Code to automate the deployment of a secondary kubernetes environment (RKE2 Cluster) on AWS without the installation of RKE2
* Code to automate the deployment of an EKS cluster on AWS
* Demo configuration files (Such as app YAML files and more) to configure the lab with some supporting resources to show-case Rancher features.
* Explanation of Use-Cases along with the supporting configuration files.
* Several reference pages to be used to explain the functionality of the product.

**Please Note:**
> Some code available in the repo may need to be adjusted from one SA to another to match the need and the identity of the SA. This is going to be highlighted in any sub-repo available in this main repo as needed.

---




## Demo Architecture

Below PIC provide a high-level design of the demo lab infrastructure

---

<p align="center">
    <img src="images/HLD-Main-Arch.png">
</p>

---