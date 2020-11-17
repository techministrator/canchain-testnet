// Uncomment the below if you wish to store state in S3
# terraform {
#   backend "s3" {
#     bucket = "<s3_bucket_name>"  # Should be encrypted
#     key = "<prefix/terraform.tfstate>"
#     region = "<region>"

#     dynamodb_table = "<table_name>"
#     encrypt = true 
#   }
# }

provider "aws" {
  region = var.project_region
}

// TF does not support variable inside variable, so make use of locals here
locals {
  project_tags = {
    project     = var.project_name
    environment = var.project_environment
  }
}

resource "random_uuid" "project_uuid" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs = [
    data.aws_availability_zones.az_list.names[0],
    data.aws_availability_zones.az_list.names[1]
  ]
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = false

  tags = local.project_tags
}

module "sg_allow_all" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.16.0"

  name        = "${var.project_name}-sg-allow-all"
  description = "Default Security Group that Allow All Traffic Inbound and Outbound"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      cidr_blocks = "0.0.0.0/0"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
    }
  ]

  egress_with_cidr_blocks = [
    {
      cidr_blocks = "0.0.0.0/0"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
    }
  ]

  tags = merge({ Name = "${var.project_name}-sg-allow-all" }, local.project_tags)
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "2.11.0"

  domain_name = var.route_53_domain_name
  zone_id     = var.route_53_zone_id

  subject_alternative_names = [
    "${var.project_name}.${var.route_53_domain_name}",
    "*.${var.project_name}.${var.route_53_domain_name}"
  ]

  validate_certificate = true
  wait_for_validation  = true
  tags                 = merge({ Name = "${var.project_name}-https-cert" }, local.project_tags)
}

module "s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "1.16.0"

  bucket = "${var.project_name}-${random_uuid.project_uuid.result}"
  acl    = "private"

  # Allow deletion of non-empty bucket
  force_destroy = true

  tags = merge({ Name = "${var.project_name}-sg-allow-all" }, local.project_tags)
}

resource "aws_s3_bucket_object" "genesis_json" {
  bucket = module.s3.this_s3_bucket_id
  key    = "can-node/genesis.json"
  source = "./scripts/genesis.json"
}

resource "aws_s3_bucket_object" "stop_script" {
  bucket = module.s3.this_s3_bucket_id
  key    = "can-node/stop.sh"
  source = "./scripts/stop.sh"
}

resource "aws_s3_bucket_object" "can_bp_genesis_start_script" {
  bucket = module.s3.this_s3_bucket_id
  key    = "can-node/can_bp_genesis_start.sh"
  source = "./scripts/can_bp_genesis_start.sh"
}

resource "aws_s3_bucket_object" "can_api_genesis_start_script" {
  bucket = module.s3.this_s3_bucket_id
  key    = "can-node/can_api_genesis_start.sh"
  source = "./scripts/can_api_genesis_start.sh"
}

resource "aws_s3_bucket_object" "can_state_genesis_start_script" {
  bucket = module.s3.this_s3_bucket_id
  key    = "can-node/can_state_genesis_start.sh"
  source = "./scripts/can_state_genesis_start.sh"
}

resource "aws_s3_bucket_object" "can_history_genesis_start_script" {
  bucket = module.s3.this_s3_bucket_id
  key    = "can-node/can_history_genesis_start.sh"
  source = "./scripts/can_history_genesis_start.sh"
}

// EC2 Instance Profile 
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge({ Name = "${var.project_name}-ec2-role" }, local.project_tags)
}

resource "aws_iam_policy" "ec2_policy" {
  name = "${var.project_name}-ec2-policy"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

// Block Producer 1
locals {
  ec2_bp_1_user_data = <<EOF
#!/bin/bash
apt update -y  &&  apt install awscli -y
cd ~
wget ${var.can_binaries_package_download_link}
apt install -y ./${var.can_binaries_package_name} && rm ${var.can_binaries_package_name}
mkdir can-bp-node  &&  cd can-bp-node/
export BPACCOUNT=${var.ec2_bp_1_acc_name}
export PUBKEY=${var.ec2_bp_1_pub_key}
export PRIKEY=${var.ec2_bp_1_pri_key}
export GENESIS_PEER=${var.genesis_bp_hostname}
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/can_bp_genesis_start.sh .  &&  chmod 755 ./can_bp_genesis_start.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/stop.sh .  &&  chmod 755 ./stop.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/genesis.json . 
./can_bp_genesis_start.sh
EOF
}

module "ec2_bp_1" {
  source = "../modules/ec2/"

  name                 = "${var.project_name}-bp-1"
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.ec2_bp_instance_type
  key_name             = var.ec2_key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  vpc_security_group_ids = [module.sg_allow_all.this_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 25
    }
  ]

  user_data_base64 = base64encode(local.ec2_bp_1_user_data)

  tags        = merge({ Name = "${var.project_name}-bp-1" }, local.project_tags)
  volume_tags = merge({ Name = "${var.project_name}-bp-1" }, local.project_tags)
}

// Block Producer 2
locals {
  ec2_bp_2_user_data = <<EOF
#!/bin/bash
apt update -y  &&  apt install awscli -y
cd ~
wget ${var.can_binaries_package_download_link}
apt install -y ./${var.can_binaries_package_name} && rm ${var.can_binaries_package_name}
mkdir can-bp-node  &&  cd can-bp-node/
export BPACCOUNT=${var.ec2_bp_2_acc_name}
export PUBKEY=${var.ec2_bp_2_pub_key}
export PRIKEY=${var.ec2_bp_2_pri_key}
export GENESIS_PEER=${var.genesis_bp_hostname}
export PEER1=${module.ec2_bp_1.private_ip[0]}
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/can_bp_genesis_start.sh .  &&  chmod 755 ./can_bp_genesis_start.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/stop.sh .  &&  chmod 755 ./stop.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/genesis.json . 
./can_bp_genesis_start.sh
EOF
}

module "ec2_bp_2" {
  source = "../modules/ec2/"

  name                 = "${var.project_name}-bp-2"
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.ec2_bp_instance_type
  key_name             = var.ec2_key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  vpc_security_group_ids = [module.sg_allow_all.this_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 25
    }
  ]

  user_data_base64 = base64encode(local.ec2_bp_2_user_data)

  tags        = merge({ Name = "${var.project_name}-bp-2" }, local.project_tags)
  volume_tags = merge({ Name = "${var.project_name}-bp-2" }, local.project_tags)
}

# // Block Producer 3
locals {
  ec2_bp_3_user_data = <<EOF
#!/bin/bash
apt update -y  &&  apt install awscli -y
cd ~
wget ${var.can_binaries_package_download_link}
apt install -y ./${var.can_binaries_package_name} && rm ${var.can_binaries_package_name}
mkdir can-bp-node  &&  cd can-bp-node/
export BPACCOUNT=${var.ec2_bp_3_acc_name}
export PUBKEY=${var.ec2_bp_3_pub_key}
export PRIKEY=${var.ec2_bp_3_pri_key}
export GENESIS_PEER=${var.genesis_bp_hostname}
export PEER1=${module.ec2_bp_1.private_ip[0]}
export PEER2=${module.ec2_bp_2.private_ip[0]}
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/can_bp_genesis_start.sh .  &&  chmod 755 ./can_bp_genesis_start.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/stop.sh .  &&  chmod 755 ./stop.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/genesis.json . 
./can_bp_genesis_start.sh
EOF
}

module "ec2_bp_3" {
  source = "../modules/ec2/"

  name                 = "${var.project_name}-bp-3"
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.ec2_bp_instance_type
  key_name             = var.ec2_key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  vpc_security_group_ids = [module.sg_allow_all.this_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 25
    }
  ]

  user_data_base64 = base64encode(local.ec2_bp_3_user_data)

  tags        = merge({ Name = "${var.project_name}-bp-3" }, local.project_tags)
  volume_tags = merge({ Name = "${var.project_name}-bp-3" }, local.project_tags)
}

// API Node 
locals {
  ec2_api_node_user_data = <<EOF
#!/bin/bash
apt update -y  &&  apt install awscli -y
cd ~
wget ${var.can_binaries_package_download_link}
apt install -y ./${var.can_binaries_package_name} && rm ${var.can_binaries_package_name}
mkdir api-node  &&  cd api-node/
export GENESIS_PEER=${var.genesis_bp_hostname}
export PEER1=${module.ec2_bp_1.private_ip[0]}
export PEER2=${module.ec2_bp_2.private_ip[0]}
export PEER3=${module.ec2_bp_3.private_ip[0]}
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/can_api_genesis_start.sh .  &&  chmod 755 ./can_api_genesis_start.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/stop.sh .  &&  chmod 755 ./stop.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/genesis.json . 
./can_api_genesis_start.sh
EOF
}

module "ec2_api_node" {
  source = "../modules/ec2/"

  name                 = "${var.project_name}-api-node"
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.ec2_api_node_instance_type
  key_name             = var.ec2_key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  vpc_security_group_ids = [module.sg_allow_all.this_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 25
    }
  ]

  user_data_base64 = base64encode(local.ec2_api_node_user_data)

  tags        = merge({ Name = "${var.project_name}-api-node" }, local.project_tags)
  volume_tags = merge({ Name = "${var.project_name}-api-node" }, local.project_tags)
}

resource "aws_lb_target_group_attachment" "alb_tg_api_node_attach" {
  target_group_arn = module.alb.target_group_arns[0]
  target_id        = module.ec2_api_node.id[0]
  port             = 8888
}

// State Node 
locals {
  ec2_state_node_user_data = <<EOF
#!/bin/bash
apt update -y  &&  apt install awscli -y
cd ~
wget ${var.can_binaries_package_download_link}
apt install -y ./${var.can_binaries_package_name} && rm ${var.can_binaries_package_name}
mkdir state-node  &&  cd state-node/
export GENESIS_PEER=${var.genesis_bp_hostname}
export PEER1=${module.ec2_bp_1.private_ip[0]}
export PEER2=${module.ec2_bp_2.private_ip[0]}
export PEER3=${module.ec2_bp_3.private_ip[0]}
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/can_state_genesis_start.sh .  &&  chmod 755 ./can_state_genesis_start.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/stop.sh .  &&  chmod 755 ./stop.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/genesis.json . 
./can_state_genesis_start.sh
EOF
}

module "ec2_state_node" {
  source = "../modules/ec2/"

  name                 = "${var.project_name}-state-node"
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.ec2_state_node_instance_type
  key_name             = var.ec2_key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  vpc_security_group_ids = [module.sg_allow_all.this_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 50
    }
  ]

  user_data_base64 = base64encode(local.ec2_state_node_user_data)

  tags        = merge({ Name = "${var.project_name}-state-node" }, local.project_tags)
  volume_tags = merge({ Name = "${var.project_name}-state-node" }, local.project_tags)
}

// History Node 
locals {
  ec2_history_node_user_data = <<EOF
#!/bin/bash
apt update -y  &&  apt install awscli openssl unzip -y
cd ~
mkdir hapi  &&  cd hapi/
wget ${var.light_history_built_zip_download_link}
unzip history-api-build.zip  &&  rm history-api-build.zip
export PATH=$PATH:~/hapi/bin
echo 'export PATH=$PATH:~/hapi/bin' >> ~/.bashrc 

cd ~
mkdir history-node  &&  cd history-node/
export GENESIS_PEER=${var.genesis_bp_hostname}
export PEER1=${module.ec2_bp_1.private_ip[0]}
export PEER2=${module.ec2_bp_2.private_ip[0]}
export PEER3=${module.ec2_bp_3.private_ip[0]}
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/can_history_genesis_start.sh .  &&  chmod 755 ./can_history_genesis_start.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/stop.sh .  &&  chmod 755 ./stop.sh
aws s3 cp s3://${module.s3.this_s3_bucket_id}/can-node/genesis.json . 
./can_history_genesis_start.sh
EOF
}

module "ec2_history_node" {
  source = "../modules/ec2/"

  name                 = "${var.project_name}-history-node"
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.ec2_history_node_instance_type
  key_name             = var.ec2_key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  vpc_security_group_ids = [module.sg_allow_all.this_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 25
    }
  ]

  user_data_base64 = base64encode(local.ec2_history_node_user_data)

  tags        = merge({ Name = "${var.project_name}-history-node" }, local.project_tags)
  volume_tags = merge({ Name = "${var.project_name}-history-node" }, local.project_tags)
}

resource "aws_lb_target_group_attachment" "alb_tg_history_node_attach" {
  target_group_arn = module.alb.target_group_arns[1]
  target_id        = module.ec2_history_node.id[0]
  port             = 8888
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "5.9.0"

  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets[*]
  security_groups    = [module.sg_allow_all.this_security_group_id]

  target_groups = [
    {
      name_prefix      = "api"
      backend_protocol = "HTTP"
      backend_port     = 8888
      target_type      = "instance"
    },
    {
      name_prefix      = "hist"
      backend_protocol = "HTTP"
      backend_port     = 8888
      target_type      = "instance"
    }
  ]

  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.this_acm_certificate_arn
    }
  ]

  https_listener_rules = [
    {
      https_listener_index = 0

      actions = [{
        type               = "forward"
        target_group_index = 0
      }]
      conditions = [{
        host_headers = ["api.${var.project_name}.${var.route_53_domain_name}"]
      }]
    },
    {
      https_listener_index = 0

      actions = [
        {
          type               = "forward"
          target_group_index = 1
        }
      ]
      conditions = [{
        host_headers = ["history.${var.project_name}.${var.route_53_domain_name}"]
      }]
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  tags = merge({ Name = "${var.project_name}-alb" }, local.project_tags)
}

// Route 53 Records
resource "aws_route53_record" "alb_api_node_record" {
  zone_id = var.route_53_zone_id
  name    = "api.${var.project_name}.${var.route_53_domain_name}"
  type    = "A"

  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alb_history_node_record" {
  zone_id = var.route_53_zone_id
  name    = "history.${var.project_name}.${var.route_53_domain_name}"
  type    = "A"

  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ec2_state_node_record" {
  zone_id = var.route_53_zone_id
  name    = "state.${var.project_name}.${var.route_53_domain_name}"
  type    = "A"
  ttl     = "300"
  records = [module.ec2_state_node.public_ip[0]]
}