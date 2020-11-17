# Simple CAN Chain Testnet

## What is CAN Chain?

CAN Chain is a blockchain-based, decentralized system that enables the development, hosting, and execution of commercial-scale decentralized applications (dApps). Built from the EOS Open Source project with role-based security permissions, industry-leading speeds and secure application processing as its core. 

- More Information: https://canfoundation.io
- Git Repository: https://github.com/canfoundation/CAN


## Requirements

Requirements
- Self-configured Genesis Block Producer node using [CAN Chain Source Code can-v1.0.0 tag](https://github.com/canfoundation/CAN/tree/can-v1.0.0) and provide the hostname/IP address to Terraform variable (named `genesis_bp_hostname`)
- Copy the `genesis.json` file of the above Genesis Block Producer node and replace it here in `./scripts/genesis.json` before running Terraform
- 3 Public & Private key pairs for each Block Producer
- Route 53 Domain Name and Route 53 Hosted Zone ID

## Resources Deployment

This template provides the quickest way to provision a small CAN Chain Testnet which comprises of the following:
- 3 Block Producer Nodes
- 1 API Node
- 1 State History Node
- [1 Light History Node](https://github.com/greymass/eos/tree/hapi-limited)

AWS Services created by this template:
- VPC (No NAT Gateway by default)
- IAM Instance Profile
- S3 Bucket
- EC2 Instances
- ALB 
- Certificate Manager
- Route 53 Records

Required Input Variables (Use `terraform.tfvars` file to specify each of the below):
- Project Variables
  - `project_name` 
  - `project_environment` 
  - `project_region` 
- Route 53 Domain Name and Hosted Zone ID
  - `route_53_domain_name` 
  - `route_53_zone_id` 
- EC2 
  - `ec2_key_name` 
- CAN Chain Nodes Variables
  - `genesis_bp_hostname` 
  - `ec2_bp_1_acc_name` 
  - `ec2_bp_1_pub_key` 
  - `ec2_bp_1_pri_key` 
  - `ec2_bp_2_acc_name` 
  - `ec2_bp_2_pub_key` 
  - `ec2_bp_2_pri_key` 
  - `ec2_bp_3_acc_name` 
  - `ec2_bp_3_pub_key` 
  - `ec2_bp_3_pri_key` 

You can use the `terraform.tfvars.example` I included in this directory. Rename it to `terraform.tfvars`.

```bash
$ mv terraform.tfvars.example terraform.tfvars 
```

## Execution

Initialize the working directory
```bash
$ terraform init
```

Check the deployment and run the stack
```bash
$ terraform plan

$ terraform apply
```

## Remove

When this Testnet is no longer in use. Remove them:
```bash
$ terraform destroy
```