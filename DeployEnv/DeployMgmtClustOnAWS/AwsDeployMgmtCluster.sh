#!/usr/bin/env bash

#=================================================================================

##########################################################################
# This script is used to deploy the AWS infrastructre for the Mgmt Cluster
# This script is going to only deploy the infrastructre components
# After the execution of this script, configuring the infrastrucre is required
# This script is going to deploy and configure the following
#   VPC, Routing, Gateway, NAT, Loadbalancing, Security Groups
#   EC2 Instances - Ubuntu based AMI, Key-Paris (if not exist) 
# All the above components are going to be deploy in the London (eu-west-2) region
# The AMI used in this script is for Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
# Some variables are hard-coded, thus to change, edit the script
##########################################################################

#=================================================================================

############################################################
# Section 1: Defining Variables to be Used Within the Script
############################################################

#Create Output Color & Text Mode Variabels To Be Used With Echo
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
Cyan=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Create Environment Variables to be used with the script and the AWS CLI commands
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
SUBNET1_NAME="${PREFIX}public-sub-01" # Add default name for Public Subnet
SUBNET1A_NAME="${PREFIX}priv-sub-01a" # Add default name for Private Subnet
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

#Set Script to Stop on Any Error
set -e

#=================================================================================

#############################################################
# Section 3: Defining Functions To Be Used During The Script
#############################################################

# Create function to be used when creating NAT Gateways to check the status of the NAT Gateway and return when it is available
check_nat_gw () {
    while true; do 
        STATE=$(aws ec2 describe-nat-gateways --region $REGION --nat-gateway-ids $1 --output json | jq '.NatGateways[].State'| sed -e 's/^"//' -e 's/"$//')
        if [[ $STATE == "available" ]]
        then
            echo $YELLOW "          NAT Gateway created and is now up and runing." $RESET
            break
        else
            echo $YELLOW "          Waiting for NAT Gateway to be created..." $RESET
        fi
        sleep 20
    done
}
        #-------------------------------------------------------------------------

# Create function to be used when creating EC2 Instances to check the status of the EC2 Instance and return when it is available
check_ec2 () {
    while true; do 
        STATE=$(aws ec2 describe-instance-status --region $REGION --instance-ids $1 --output json | jq '.InstanceStatuses[].SystemStatus.Status'| sed -e 's/^"//' -e 's/"$//')
        if [[ $STATE == "ok" ]]
        then
            echo $YELLOW "          EC2 instance created and is now up and runing." $RESET
            break
        else
            echo $YELLOW "          Waiting for EC2 instance to be created..." $RESET
        fi
        sleep 10
    done
}

#=================================================================================

    #====================================================


        ################################################
        ##########                           ###########
        ##########    Start of Main Code     ###########
        ##########                           ###########
        ################################################

    #=====================================================

#############################################################
# Section 4: Echo The Start Of The Script
#############################################################

#Echo Out The Start of The Script & The Used Variables
echo "       "
echo "       "
echo $GREEN "Start provisioning of a sinlge cluster for kubernetes demo" $RESET
echo $GREEN "==========================================================" $RESET
echo "       "
echo "Variables to be used are:" $RESET
echo "       "
echo "Reagion -     " $YELLOW  "$REGION" $RESET
echo "Owner -       " $YELLOW  "$OWNER" $RESET
echo "Prefix -      " $YELLOW  "$PREFIX" $RESET
echo "Tag -         " $YELLOW  "$TAG" $RESET
echo "Folder -      " $YELLOW  "$FOLDER" $RESET
echo "AMI -         " $YELLOW  "$AMI" $RESET
echo "KEY -         " $YELLOW  "$KEYPAIR_NAME" $RESET
echo "Script Dir -  " $YELLOW  "$S_DIR" $RESET
echo "       "
echo $GREEN "=======================================================================" $RESET
echo "       "

#=================================================================================

################################################################################
# Section 5: Create VPC, Subnets, IGW, NAT-GW, Routing-Tables & Security-Groups
###############################################################################

#----------------------------------------------------------------------------------------------
#References: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-subnets-commands-example.html
#----------------------------------------------------------------------------------------------

echo $GREEN "Creating Environment Networking - VPC, Subnet, IGW, etc..." $RESET

#Create VPC in the required region and set the name/owner tags of the VPC
echo $GREEN "   Creating VPC..." $RESET
VPC_ID=$(aws ec2 create-vpc --region $REGION --cidr-block '10.10.0.0/16' --output json | jq '.Vpc.VpcId'| sed -e 's/^"//' -e 's/"$//') #Create VPC
echo $YELLOW "       VPC Created, VPC ID is" $BOLD $BLUE $VPC_ID $RESET
echo $YELLOW "          Adding Tags to VPC..." $RESET
NULL=$(aws ec2 create-tags --resources $VPC_ID --region $REGION --tags Key=Name,Value=$VPC_NAME) #Create a Tage for the VPC Name
NULL=$(aws ec2 create-tags --resources $VPC_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the VPC Owner
NULL=$(aws ec2 create-tags --resources $VPC_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the VPC TAG
echo  "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------
        #-------------------------------------------------------------------------

################## Create Subnets In the VPC ######################################
#----------------------------------------------------------------------------------
echo $GREEN "   Creating Subnets..." $RESET
#Create First Public Subnet In the First AZ within the Region and Add Tages to it
echo $YELLOW "      Creating First Public Subnet in ${AZ1}..." $RESET
SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --region $REGION --cidr-block 10.10.10.0/24 --availability-zone $AZ1 --output json | jq '.Subnet.SubnetId'| sed -e 's/^"//' -e 's/"$//')
echo $YELLOW "          Subnet Created, Subnet ID is" $BOLD $BLUE $SUBNET1_ID $RESET
echo $YELLOW "          Adding Tags to Subnet..." $RESET
NULL=$(aws ec2 create-tags --resources $SUBNET1_ID --region $REGION --tags Key=Name,Value=$SUBNET1_NAME) #Create a Tage for the Subnet Name
NULL=$(aws ec2 create-tags --resources $SUBNET1_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the Subnet Owner
NULL=$(aws ec2 create-tags --resources $SUBNET1_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the Subnet TAG
NULL=$(aws ec2 modify-subnet-attribute --subnet-id $SUBNET1_ID --region $REGION --map-public-ip-on-launch) #Change Subnet to auto Assign Public IP to Instance Launching in this Subnet
        #-------------------------------------------------------------------------
#Create First Private Subnet In the First AZ within the Region and Add Tages to it
echo $YELLOW "      Creating First Private Subnet in ${AZ1}..." $RESET
SUBNET1A_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --region $REGION --cidr-block 10.10.11.0/24 --availability-zone $AZ1 --output json | jq '.Subnet.SubnetId'| sed -e 's/^"//' -e 's/"$//')
echo $YELLOW "          Subnet Created, Subnet ID is" $BOLD $BLUE $SUBNET1A_ID $RESET
echo $YELLOW "          Adding Tags to Subnet..." $RESET
NULL=$(aws ec2 create-tags --resources $SUBNET1A_ID --region $REGION --tags Key=Name,Value=$SUBNET1A_NAME) #Create a Tage for the Subnet Name
NULL=$(aws ec2 create-tags --resources $SUBNET1A_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the Subnet Owner
NULL=$(aws ec2 create-tags --resources $SUBNET1A_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the Subnet TAG
echo "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------

############## Create Internet Gateway and attached it to the VPC #################
#----------------------------------------------------------------------------------
echo $GREEN "   Creating IGW..." $RESET
IGW_ID=$(aws ec2 create-internet-gateway --region $REGION --output json | jq '.InternetGateway.InternetGatewayId' | sed -e 's/^"//' -e 's/"$//') #Create IGW
echo $YELLOW "       IGW Created, IGW ID is" $BOLD $BLUE $IGW_ID $RESET
echo $YELLOW "          Adding Tags to IGW..." $RESET
NULL=$(aws ec2 create-tags --resources $IGW_ID --region $REGION --tags Key=Name,Value=$IGW_NAME) #Create a Tage for the VPC Name
NULL=$(aws ec2 create-tags --resources $IGW_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the VPC Owner
NULL=$(aws ec2 create-tags --resources $IGW_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the VPC TAG
NULL=$(aws ec2 attach-internet-gateway --vpc-id $VPC_ID --region $REGION --internet-gateway-id $IGW_ID) #Attach IGW to VPC
echo "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------
        #-------------------------------------------------------------------------

####### Create NAT Gateways and Elastic IP to be associated to the NAT Gateways ##########
#-----------------------------------------------------------------------------------------
echo $GREEN "   Creating NAT Gateways and its Elastic IP(s)..." $RESET
#Create First NAT Gateway with its elastic IP
echo $YELLOW "      Creating First Elastic IP..." $RESET
EIP1_ID=$(aws ec2 allocate-address --region $REGION --domain vpc --network-border-group $REGION | jq '.AllocationId'| sed -e 's/^"//' -e 's/"$//') #Create Elastic IP for First NATGW
EIP1_IP=$(aws ec2 describe-addresses --region $REGION --allocation-ids $EIP1_ID | jq '.Addresses[].PublicIp' | sed -e 's/^"//' -e 's/"$//') #Get IP Address of the Elastic IP
echo $YELLOW "          Elastic IP Created, Elastic IP ID is" $BOLD $BLUE $EIP1_ID $RESET
echo $YELLOW "          ------------------- Elastic IP IP is" $BOLD $BLUE $EIP1_IP $RESET
echo $YELLOW "          Adding Tags to Elastic IP..." $RESET
NULL=$(aws ec2 create-tags --resources $EIP1_ID --region $REGION --tags Key=Name,Value=$EIP1_NAME) #Create a Tage for the Elastic IP Name
NULL=$(aws ec2 create-tags --resources $EIP1_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the Elastic IP Owner
NULL=$(aws ec2 create-tags --resources $EIP1_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the Elastic IP TAG
echo $YELLOW "      Creating First NAT Gateway..." $RESET
NATGW1_ID=$(aws ec2 create-nat-gateway --subnet-id $SUBNET1_ID --region $REGION --allocation-id $EIP1_ID | jq '.NatGateway.NatGatewayId' | sed -e 's/^"//' -e 's/"$//') #Create NAT Gateway
echo $YELLOW "          NAT Gateway is being created, NAT Gateway ID is" $BOLD $BLUE $NATGW1_ID $RESET
check_nat_gw $NATGW1_ID #Loop untill the NAT Gateway stats becomes available
echo $YELLOW "          Adding Tags to NAT Gateway..." $RESET
NULL=$(aws ec2 create-tags --resources $NATGW1_ID --region $REGION --tags Key=Name,Value=$NATGW1_NAME) #Create a Tage for the NAT Gateway Name
NULL=$(aws ec2 create-tags --resources $NATGW1_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the NAT Gateway Owner
NULL=$(aws ec2 create-tags --resources $NATGW1_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the NAT Gateway TAG
        #-------------------------------------------------------------------------
        #-------------------------------------------------------------------------

########################### Create Routing Tables #################################
#----------------------------------------------------------------------------------
echo $GREEN "   Creating Routing Tables..." $RESET
#Create Public Routing Table and Associate Subnets with it and add routes.
echo $YELLOW "      Creating Public Routing Table..." $RESET
PUBRT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --output json | jq '.RouteTable.RouteTableId'| sed -e 's/^"//' -e 's/"$//') #Create Public Route Table
echo $YELLOW "          Routing Table Created, Routing Table ID is" $BOLD $BLUE $PUBRT_ID $RESET
echo $YELLOW "          Adding Tags to Routing Table..." $RESET
NULL=$(aws ec2 create-tags --resources $PUBRT_ID --region $REGION --tags Key=Name,Value=$PUBRT_NAME) #Create a Tage for the Subnet Name
NULL=$(aws ec2 create-tags --resources $PUBRT_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the Subnet Owner
NULL=$(aws ec2 create-tags --resources $PUBRT_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the Subnet TAG
NULL=$(aws ec2 associate-route-table --subnet-id $SUBNET1_ID --region $REGION --route-table-id $PUBRT_ID) #Associate Subnet To this Routing Table.
NULL=$(aws ec2 create-route --route-table-id $PUBRT_ID --region $REGION --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID)
        #-------------------------------------------------------------------------
#Create First Private Routing Table and Associate Subnets with it and add routes.
echo $YELLOW "      Creating First Private Routing Table..." $RESET
PRIVRT1_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --output json | jq '.RouteTable.RouteTableId' | sed -e 's/^"//' -e 's/"$//') #Create Public Route Table
echo $YELLOW "          Routing Table Created, Routing Table ID is" $BOLD $BLUE $PRIVRT1_ID $RESET
echo $YELLOW "          Adding Tags to Routing Table..." $RESET
NULL=$(aws ec2 create-tags --resources $PRIVRT1_ID --region $REGION --tags Key=Name,Value=$PRIVRT1_NAME) #Create a Tage for the Subnet Name
NULL=$(aws ec2 create-tags --resources $PRIVRT1_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the Subnet Owner
NULL=$(aws ec2 create-tags --resources $PRIVRT1_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the Subnet TAG
NULL=$(aws ec2 associate-route-table --subnet-id $SUBNET1A_ID --region $REGION --route-table-id $PRIVRT1_ID) #Associate Subnet To this Routing Table.
NULL=$(aws ec2 create-route --route-table-id $PRIVRT1_ID --region $REGION --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NATGW1_ID)
        #-------------------------------------------------------------------------
        #-------------------------------------------------------------------------

########################### Create Security Groups #################################
#----------------------------------------------------------------------------------
echo $GREEN "   Creating Security Groups..." $RESET
#Create Public Security Group and add rules to it.
echo $YELLOW "      Creating Public Security Group..." $RESET
PUBSGROUP_ID=$(aws ec2 create-security-group --group-name $PUBSGROUP_NAME --vpc-id $VPC_ID --region $REGION --description "Public Security Group" --output json | jq '.GroupId'| sed -e 's/^"//' -e 's/"$//')
echo $YELLOW "          Security Group Created, Security Group ID is" $BOLD $BLUE $PUBSGROUP_ID $RESET
echo $YELLOW "          Adding Tags to Security Group..." $RESET
NULL=$(aws ec2 create-tags --resources $PUBSGROUP_ID --region $REGION --tags Key=Name,Value=$PUBSGROUP_NAME) #Create a Tage for the Security Group Name
NULL=$(aws ec2 create-tags --resources $PUBSGROUP_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the Security Group Owner
NULL=$(aws ec2 create-tags --resources $PUBSGROUP_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the Security Group TAG
echo $YELLOW "          Adding Rules to Security Group..." $RESET
NULL=$(aws ec2 authorize-security-group-ingress --region $REGION --group-id $PUBSGROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0) #Add Rules to Security Group.
NULL=$(aws ec2 authorize-security-group-ingress --region $REGION --group-id $PUBSGROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0) #Add Rules to Security Group.
NULL=$(aws ec2 authorize-security-group-ingress --region $REGION --group-id $PUBSGROUP_ID --protocol tcp --port 443 --cidr 0.0.0.0/0) #Add Rules to Security Group.
NULL=$(aws ec2 authorize-security-group-ingress --region $REGION --group-id $PUBSGROUP_ID --protocol tcp --port 6443 --cidr 0.0.0.0/0) #Add Rules to Security Group.
NULL=$(aws ec2 authorize-security-group-ingress --region $REGION --group-id $PUBSGROUP_ID --protocol tcp --port 9443 --cidr 0.0.0.0/0) #Add Rules to Security Group.
NULL=$(aws ec2 authorize-security-group-ingress --region $REGION --group-id $PUBSGROUP_ID --protocol all --cidr 10.10.0.0/16) #Add Rules to Security Group.
        #-------------------------------------------------------------------------
#Create Private Security Group and add rules to it.
echo $YELLOW "      Creating Private Security Group..." $RESET
PRIVSGROUP_ID=$(aws ec2 create-security-group --group-name $PRIVSGROUP_NAME --vpc-id $VPC_ID --region $REGION --description "Private Security Group" --output json | jq '.GroupId'| sed -e 's/^"//' -e 's/"$//')
echo $YELLOW "          Security Group Created, Security Group ID is" $BOLD $BLUE $PRIVSGROUP_ID $RESET
echo $YELLOW "          Adding Tags to Security Group..." $RESET
NULL=$(aws ec2 create-tags --resources $PRIVSGROUP_ID --region $REGION --tags Key=Name,Value=$PRIVSGROUP_NAME) #Create a Tage for the Security Group Name
NULL=$(aws ec2 create-tags --resources $PRIVSGROUP_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the Security Group Owner
NULL=$(aws ec2 create-tags --resources $PRIVSGROUP_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the Security Group TAG
echo $YELLOW "          Adding Rules to Security Group..." $RESET
NULL=$(aws ec2 authorize-security-group-ingress --group-id $PRIVSGROUP_ID --region $REGION --protocol all --cidr 0.0.0.0/0) #Add Rules to Security Group.
echo "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------
        #-------------------------------------------------------------------------

######################## Create Network Load Balancer #############################
#----------------------------------------------------------------------------------
echo $GREEN "   Creating Network Load Balancers..." $RESET
#Create Network Load Balancer in AZ1 and leave the configuration for a later stage of the script.
echo $YELLOW "      Creating Network Load Balancer in ${AZ1}..." $RESET
NETLB1A_ARN=$(aws elbv2 create-load-balancer --region $REGION --name $NETLB1A_NAME --type network --subnets $SUBNET1_ID --output json | jq '.LoadBalancers[].LoadBalancerArn'| sed -e 's/^"//' -e 's/"$//')
echo $YELLOW "          Network Load Balancer Created." $RESET
echo $YELLOW "          Adding Tags to Network Load Balancer..." $RESET
NULL=$(aws elbv2 add-tags --resource-arns $NETLB1A_ARN --region $REGION --tags Key=Name,Value=$NETLB1A_NAME) #Create a Tage for the Network Load Balancer Name
NULL=$(aws elbv2 add-tags --resource-arns $NETLB1A_ARN --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the Network Load Balancer Owner
NULL=$(aws elbv2 add-tags --resource-arns $NETLB1A_ARN --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the Network Load Balancer TAG
echo "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------
        #-------------------------------------------------------------------------

echo "       "
echo $GREEN "=======================================================================" $RESET
echo "       "

#=================================================================================

################################################################################
# Section 6: Create Bastion Host and EC2 Instances.
###############################################################################

#--------------------------------------------------------------------------------------------
#References: https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-instances.html
#--------------------------------------------------------------------------------------------

echo $GREEN "Creating SSH Keys, EC2 Instances..." $RESET

#Create SSH Key and add it to the required path
echo $GREEN "   Creating SSH Key..." $RESET
#---------------------------------------------------
#First Check if a Key with the same name exists and if so delete it
echo $YELLOW "       Checking if KeyPair already exists..."
if [[ $(aws ec2 describe-key-pairs --region $REGION --key-names $KEYPAIR_NAME 2>&1 | grep -c 'InvalidKeyPair.NotFound') == 1 ]]; then
        #Create Key
        aws ec2 create-key-pair --region $REGION --key-name $KEYPAIR_NAME --region $REGION --query 'KeyMaterial' --output text > $KEYPAIR_FILE #Create Key Pair
        KEYPAIR_ID=$(aws ec2 describe-key-pairs --region $REGION --key-names $KEYPAIR_NAME --output json | jq '.KeyPairs[].KeyPairId'| sed -e 's/^"//' -e 's/"$//') #Get Key Pair ID
        echo $YELLOW "       Key Pair Created, Key Pair ID is" $BOLD $BLUE $KEYPAIR_ID $RESET
        echo $YELLOW "          Adding Tags to Key Pair..." $RESET
        NULL=$(aws ec2 create-tags --resources $KEYPAIR_ID --region $REGION --tags Key=Name,Value=$KEYPAIR_NAME) #Create a Tage for the VPC Name
        NULL=$(aws ec2 create-tags --resources $KEYPAIR_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the VPC Owner
        NULL=$(aws ec2 create-tags --resources $KEYPAIR_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the VPC TAG 
        echo  "   ----------------------------------" $RESET   
else
        echo $YELLOW "       KeyPair already exists, using existing key."
        KEYPAIR_ID=$(aws ec2 describe-key-pairs --key-names $KEYPAIR_NAME --region $REGION --output json | jq '.KeyPairs[].KeyPairId'| sed -e 's/^"//' -e 's/"$//') #Get Key Pair ID
        echo  "   ----------------------------------" $RESET
fi
        #-------------------------------------------------------------------------
        #-------------------------------------------------------------------------

#Create First Master Node 
echo $GREEN "   Creating First Master Node..." $RESET
MNODE1A_ID=$(aws ec2 run-instances --region $REGION --image-id $AMI --count 1 --instance-type t2.xlarge --key-name $KEYPAIR_NAME --security-group-ids $PRIVSGROUP_ID --subnet-id $SUBNET1A_ID --block-device-mappings $MHOST_DISK_CONFIG --private-ip-address $MNODE1A_IP --user-data file://${MN01_1_CONF} --output json | jq '.Instances[].InstanceId'| sed -e 's/^"//' -e 's/"$//') #Create EC2 Instance
echo $YELLOW "       Master Node Created, Master Node ID is" $BOLD $BLUE $MNODE1A_ID $RESET
echo $YELLOW "          Adding Tags to Master Node..." $RESET
NULL=$(aws ec2 create-tags --resources $MNODE1A_ID --region $REGION --tags Key=Name,Value=$MNODE1A_NAME) #Create a Tage for the EC2 Instance Name
NULL=$(aws ec2 create-tags --resources $MNODE1A_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the EC2 Instance Owner
NULL=$(aws ec2 create-tags --resources $MNODE1A_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the EC2 Instance TAG
echo $YELLOW "          Disabling source destination check..." $RESET
NULL=$(aws ec2 modify-instance-attribute --source-dest-check "{\"Value\": false}" --instance-id $MNODE1A_ID) #Disable Source Destination Check on EC2 Instance
        #-------------------------------------------------------------------------
#Create First Worker Node 
echo $GREEN "   Creating First Worker Node..." $RESET
WNODE1A_ID=$(aws ec2 run-instances --region $REGION --image-id $AMI --count 1 --instance-type t2.xlarge --key-name $KEYPAIR_NAME --security-group-ids $PRIVSGROUP_ID --subnet-id $SUBNET1A_ID --block-device-mappings $WHOST_DISK_CONFIG --private-ip-address $WNODE1A_IP --user-data file://${WN01_1_CONF} --output json | jq '.Instances[].InstanceId'| sed -e 's/^"//' -e 's/"$//') #Create EC2 Instance
echo $YELLOW "       Worker Node Created, Worker Node ID is" $BOLD $BLUE $WNODE1A_ID $RESET
echo $YELLOW "          Adding Tags to Worker Node..." $RESET
NULL=$(aws ec2 create-tags --resources $WNODE1A_ID --region $REGION --tags Key=Name,Value=$WNODE1A_NAME) #Create a Tage for the EC2 Instance Name
NULL=$(aws ec2 create-tags --resources $WNODE1A_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the EC2 Instance Owner
NULL=$(aws ec2 create-tags --resources $WNODE1A_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the EC2 Instance TAG
echo $YELLOW "          Disabling source destination check..." $RESET
NULL=$(aws ec2 modify-instance-attribute --region $REGION --source-dest-check "{\"Value\": false}" --instance-id $WNODE1A_ID) #Disable Source Destination Check on EC2 Instance
        #-------------------------------------------------------------------------
#Create Second Worker Node
echo $GREEN "   Creating Second Worker Node..." $RESET
WNODE1B_ID=$(aws ec2 run-instances --region $REGION --image-id $AMI --count 1 --instance-type t2.xlarge --key-name $KEYPAIR_NAME --security-group-ids $PRIVSGROUP_ID --subnet-id $SUBNET1A_ID --block-device-mappings $WHOST_DISK_CONFIG --private-ip-address $WNODE1B_IP --user-data file://${WN02_1_CONF} --output json | jq '.Instances[].InstanceId'| sed -e 's/^"//' -e 's/"$//') #Create EC2 Instance
echo $YELLOW "       Worker Node Created, Worker Node ID is" $BOLD $BLUE $WNODE1B_ID $RESET
echo $YELLOW "          Adding Tags to Worker Node..." $RESET
NULL=$(aws ec2 create-tags --resources $WNODE1B_ID --region $REGION --tags Key=Name,Value=$WNODE1B_NAME) #Create a Tage for the EC2 Instance Name
NULL=$(aws ec2 create-tags --resources $WNODE1B_ID --region $REGION --tags Key=Owner,Value=$OWNER) #Create a Tage for the EC2 Instance Owner
NULL=$(aws ec2 create-tags --resources $WNODE1B_ID --region $REGION --tags Key=AppDemo,Value=$TAG) #Create a Tage for the EC2 Instance TAG
echo $YELLOW "          Disabling source destination check..." $RESET
NULL=$(aws ec2 modify-instance-attribute --region $REGION --source-dest-check "{\"Value\": false}" --instance-id $WNODE1B_ID) #Disable Source Destination Check on EC2 Instance
        #-------------------------------------------------------------------------

#Check if all EC2 Instance are up and running
echo $GREEN "   Checking EC2 Instances State..." $RESET
echo $YELLOW "       Checking First Master Node state..." $RESET
check_ec2 $MNODE1A_ID #Loop untill the EC2 stats becomes available
echo $YELLOW "       Checking First Worker Node state..." $RESET
check_ec2 $WNODE1A_ID #Loop untill the EC2 stats becomes available
echo $YELLOW "       Checking Second Worker Node state..." $RESET
check_ec2 $WNODE1B_ID #Loop untill the EC2 stats becomes available
echo  "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------
        #-------------------------------------------------------------------------

echo "       "
echo $GREEN "=======================================================================" $RESET
echo "       "

#=================================================================================

################################################################################
# Section 7: Configure Network Load Balancer Targets and Target Groups.
###############################################################################

#--------------------------------------------------------------------------------------------
#References: https://docs.aws.amazon.com/elasticloadbalancing/latest/network/network-load-balancer-cli.html
#--------------------------------------------------------------------------------------------

echo $GREEN "Configuring Network Load Balancer Target and Target Groups..." $RESET

#Create SSH Target Group for Load Balancing of SSH Traffic
echo $GREEN "   Creating Target Gourps for SSH Access..." $RESET
echo $YELLOW "       Creating Target Gourps for LB..."
LB1_SSH_TG_ARN=$(aws elbv2 create-target-group --name $LB1_SSH_TG_NAME --protocol TCP --port 22 --vpc-id $VPC_ID --output json | jq '.TargetGroups[].TargetGroupArn'| sed -e 's/^"//' -e 's/"$//') # Create Target Group for SSH
echo $YELLOW "          Target Gourps Created." $RESET
echo  "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------

# Register Master Node as a Target in the target group
echo $GREEN "   Registering Targets to Target Gourps..." $RESET
echo $YELLOW "       Registering Master Node as a Target for SSH Access..."
NULL=$(aws elbv2 register-targets --target-group-arn $LB1_SSH_TG_ARN --targets Id=$MNODE1A_ID) # Register Master Node as a Target to the Target Group for SSH
echo $YELLOW "          Master Node Registered." $RESET
echo  "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------

# Create listner for the load balancer on port 22 SSH
echo $GREEN "   Creating LB Listener..." $RESET
echo $YELLOW "       Registering Listener for LB for SSH Access..."
LB1_SSH_LISTNER_ARN=$(aws elbv2 create-listener --load-balancer-arn $NETLB1A_ARN --protocol TCP --port 22 --default-actions Type=forward,TargetGroupArn=$LB1_SSH_TG_ARN --output json | jq '.Listeners[].ListenerArn'| sed -e 's/^"//' -e 's/"$//') # Create a LB Listnere for SSH
echo $YELLOW "          Listeners Created." $RESET
echo  "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------

#Create Kubectl Target Group for Load Balancing of Kubectl Traffic
echo $GREEN "   Creating Target Gourps for Kubectl Access..." $RESET
echo $YELLOW "       Creating Target Gourps for LB..."
LB1_kube_TG_ARN=$(aws elbv2 create-target-group --name $LB1_Kubectl_TG_NAME --protocol TCP --port 6443 --vpc-id $VPC_ID --output json | jq '.TargetGroups[].TargetGroupArn'| sed -e 's/^"//' -e 's/"$//') # Create Target Group for SSH
echo $YELLOW "          Target Gourps Created." $RESET
echo  "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------

echo $GREEN "   Registering Targets to Target Gourps..." $RESET
echo $YELLOW "       Registering Master Node as a Target for Kubectl Access..."
NULL=$(aws elbv2 register-targets --target-group-arn $LB1_kube_TG_ARN --targets Id=$MNODE1A_ID) # Register Master Node as a Target to the Target Group for SSH
echo $YELLOW "          Master Node Registered." $RESET
echo  "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------

echo $GREEN "   Creating LB Listeners..." $RESET
echo $YELLOW "       Registering Listeners for LB for Kubectl Access..."
LB1_kube_LISTNER_ARN=$(aws elbv2 create-listener --load-balancer-arn $NETLB1A_ARN --protocol TCP --port 6443 --default-actions Type=forward,TargetGroupArn=$LB1_kube_TG_ARN --output json | jq '.Listeners[].ListenerArn'| sed -e 's/^"//' -e 's/"$//') # Create a LB Listnere for SSH
echo $YELLOW "          Listeners Created." $RESET
echo  "   ----------------------------------" $RESET
        #-------------------------------------------------------------------------

echo "       "
echo $GREEN "=======================================================================" $RESET
echo "       "

#=================================================================================

################################################################################
# Section 8: Retrieve Load Balancer Public IP
###############################################################################

echo $GREEN "Final Step: Retriving LB public IP..." $RESET
LB1_ID=$(echo $NETLB1A_ARN | grep / | cut -d/ -f2-)
LB1_PATH="'ELB "
LB1_PATH+=$LB1_ID
LB1_PATH+="'"
LB1_Pub_IP=$(aws ec2 describe-network-interfaces --filters Name=description,Values=$LB1_PATH --output json | jq '.NetworkInterfaces[].Association.PublicIp')
echo $YELLOW "       LB Public IP Retrived. Public IP is" $LB1_Pub_IP

echo "       "
echo $GREEN "=======================================================================" $RESET
echo "       "

#=================================================================================

################################################################################
# Section 9: Create Output JSON file and dump it
###############################################################################

echo $GREEN "Adding all provisioned reources's ID to a JSON file..." $RESET

#Create a json file which will hold all the ID and ARNs of the resources created by this script.
#The purpose of this JSON file is to be used with another script to clean up the created objects.
echo $GREEN "   Creating JSON file..." $RESET
JSON_OUTPUT_V=$(cat <<EOF
{
        "ProvisionParam" : {
                "Reagion": "$REGION",
                "Owner": "$OWNER",
                "Prefix": "$PREFIX",
                "Tag": "$TAG",
                "Folder": "$FOLDER",
                "AMI": "$AMI",
                "KEY": "$KEYPAIR_NAME",
                "ScriptDir": "$S_DIR"
        },
        "Networking": {
                "VpcId": "$VPC_ID",
                "Subnets": [
                        {
                                "SubnetId": "$SUBNET1_ID",
                                "SubnetName": "$SUBNET1_NAME",
                                "SubnetCider": "10.10.10.0/24",
                                "SubnetAz": "$AZ1"
                        },
                        {
                                "SubnetId": "$SUBNET1A_ID",
                                "SubnetName": "$SUBNET1A_NAME",
                                "SubnetCider": "10.10.11.0/24",
                                "SubnetAz": "$AZ1"
                        }
                ],
                "Igw": "$IGW_ID",
                "ElasticIp": [
                        {"EipId": "$EIP1_ID"}
                ],
                "NatGw": [
                        {
                                "GwName": "$NATGW1_NAME",
                                "GwId" "$NATGW1_ID"
                        }
                ],
                "RoutingTable": [
                        {
                                "RtName": "$PUBRT_NAME",
                                "RtId": "$PUBRT_ID"
                        },
                        {
                                "RtName": "$PRIVRT1_NAME",
                                "RtId": "$PRIVRT1_ID"
                        }      
                ],
                "SecurityGroup": [
                        {
                                "SgName": "$PUBSGROUP_NAME",
                                "SgId": "$PUBSGROUP_ID"
                        },
                        {
                                "SgName": "$PRIVSGROUP_NAME",
                                "SgId": "$PRIVSGROUP_ID"
                        }      
                ],
                "NetworkLB": [
                        {
                                "LbName": "$NETLB1A_NAME",
                                "LbArn": "$NETLB1A_ARN",
                                "LbPubIP": "$LB1_Pub_IP"
                        }      
                ],
                "TargetGroups": [
                        {
                                [
                                        "TgName": "$LB1_SSH_TG_NAME",
                                        "TgArn": "$LB1_SSH_TG_ARN"
                                        ],
                                [
                                        "TgName": "$LB1_Kubectl_TG_NAME",
                                        "TgArn": "$LB1_kube_LISTNER_ARN"
                                ]

                        }
                ]
        },
        "Ec2Instances": [
                {
                        "InstanceName": "$MNODE1A_NAME",
                        "InstanceId": "$MNODE1A_ID",
                        "InstanceAmi": "$AMI",
                        "InstanceType": "t2.xlarge"
                },
                {
                        "InstanceName": "$WNODE1A_NAME",
                        "InstanceId": "$WNODE1A_ID",
                        "InstanceAmi": "$AMI",
                        "InstanceType": "t2.xlarge"
                },
                {
                        "InstanceName": "$WNODE1B_NAME",
                        "InstanceId": "$WNODE1B_ID",
                        "InstanceAmi": "$AMI",
                        "InstanceType": "t2.xlarge"
                }
        ]
}
EOF
)
#Add JSON to a file
echo $JSON_OUTPUT_V > $JSON_FILE

#=================================================================================

################################################################################
# Section 9: Print End of Script.
###############################################################################

        #-------------------------------------------------------------------------


echo "       "
echo "       "
echo $GREEN "All resources have been provisioned and configured as needed. Enjoy...." $RESET
echo $GREEN "=======================================================================" $RESET
echo "       "
echo $GREEN "=======================================================================" $RESET
echo "       "
