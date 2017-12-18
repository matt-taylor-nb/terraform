# Terraform Example
## Description
Simple scripts to provision test infrastruture in AWS.
#### Jump Host
This will stand up a simple jump host in AWS and look after creating all of the networks to isolate it from the rest of your environment.
#### Jenkins
This will stand up a Jenkins Master in its own isolated network. It will provision a vanilla AMI (it just needs python installed) then an Ansible playbook will install Jenkins.

## Pre-Reqs
In order to use the Jenkins plan you will need to have the private key you intend to connect to the server with on the machine running the terraform script so it can execute an Ansible playbook once the system is online.

## Usage
+ Clone the repo. 
+ Modify the example variables file stored in jenkins/terraform.tfvars.template and jump-host/terraform.tfvars.template as needed and rename them to 'terraform.tfvars'
+ Navigate to whatever type of infrastructure you would like to provision (jump-host or jenkins currently)
 + `terraform init`
 + `terraform plan -out <choose a file name>`
 + Verify the plan will change what you expect
 + `terraform apply <your above filename>`

