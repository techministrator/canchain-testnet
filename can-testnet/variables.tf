//// PROJECT VARIABLES
variable "project_name" {
  description = "Project name acts as a prefix for all resources names. Make sure it does not match other current project!"
  type        = string
}

variable "project_environment" {
  description = "Project environment (dev, test, qa...)"
  type        = string
  default     = "test"
}

variable "project_region" {
  description = "AWS Region to run this project"
  type        = string
  default     = "ap-northeast-2"
}

//// VPC Variables
data "aws_availability_zones" "az_list" {
  state = "available"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_private_subnets" {
  description = "Private Subnets for VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public Subnets for VPC"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

//// ACM Variables
variable "route_53_domain_name" {
  description = "Root Domain Name for this Testnet"
  type        = string
  default     = "canfoundation.io"
}

variable "route_53_zone_id" {
  description = "Route 53 Zone ID. Use canfoundation.io by default"
  type        = string
  default     = "ZPNAIXMOU915O" // "canfoundation.io" Hosted Zone ID
}

/// EC2 Variables
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical AWS Account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

variable "ec2_bp_instance_type" {
  description = "CAN Block Producer Instance Type"
  type        = string
  default     = "t3.small"
}

variable "ec2_api_node_instance_type" {
  description = "CAN API Node Instance Type"
  type        = string
  default     = "t3.medium"
}

variable "ec2_state_node_instance_type" {
  description = "CAN State Node Instance Type"
  type        = string
  default     = "t3.medium"
}

variable "ec2_history_node_instance_type" {
  description = "CAN History Node Instance Type"
  type        = string
  default     = "t3.medium"
}

variable "ec2_key_name" {
  description = "EC2 Instance SSH Key Name"
  type        = string
}

// CAN Chain Variables
variable "genesis_bp_hostname" {
  description = "Genesis BP Hostname or IP Address"
  type        = string
}

variable "can_binaries_package_download_link" {
  description = "The .deb CAN Binaries Download Link that include cleos, nodeos, keosd CLI"
  type        = string
  default     = "https://github.com/canfoundation/CAN/releases/download/can-v1.0.0/cannet_1.0.0-ubuntu-18.04_amd64.deb"
}

variable "can_binaries_package_name" {
  description = "The FILE name of the CAN Binaries package"
  type        = string 
  default     = "cannet_1.0.0-ubuntu-18.04_amd64.deb"
}

// Block Producer 1 Variables
variable "ec2_bp_1_acc_name" {
  description = "Block Producer 1 CAN Account Name"
  type        = string
  default     = "test1.bp"
}

variable "ec2_bp_1_pub_key" {
  description = "Block Producer 1 Public Key"
  type        = string
}

variable "ec2_bp_1_pri_key" {
  description = "Block Producer 1 Private Key"
  type        = string
}

// Block Producer 2 Variables
variable "ec2_bp_2_acc_name" {
  description = "Block Producer 2 CAN Account Name"
  type        = string
  default     = "test2.bp"
}

variable "ec2_bp_2_pub_key" {
  description = "Block Producer 2 Public Key"
  type        = string
}

variable "ec2_bp_2_pri_key" {
  description = "Block Producer 2 Private Key"
  type        = string
}

// Block Producer 3 Variables
variable "ec2_bp_3_acc_name" {
  description = "Block Producer 3 CAN Account Name"
  type        = string
  default     = "test3.bp"
}

variable "ec2_bp_3_pub_key" {
  description = "Block Producer 3 Public Key"
  type        = string
}

variable "ec2_bp_3_pri_key" {
  description = "Block Producer 3 Private Key"
  type        = string
}

// History Node Variables
variable "light_history_built_zip_download_link" {
  description = "Light History Node Built Files Download Link"
  type        = string
  default     = "https://canchain-testnet.s3-ap-southeast-1.amazonaws.com/containers-build/history-api-build.zip"
}