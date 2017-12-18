# Terraform Example
## Description
Simple scripts to provision test infrastruture in AWS

## Usage
+ Clone the repo. 
+ Modify the example variables file stored in jenkins/terraform.tfvars.template and jump-host/terraform.tfvars.template as needed and rename them to 'terraform.tfvars'
+ Navigate to whatever type of infrastructure you would like to provision (jump-host or jenkins currently)
 + `terraform init`
 + `terraform plan -out <choose a file name>`
 + Verify the plan will change what you expect
 + `terraform apply <your above filename>`

