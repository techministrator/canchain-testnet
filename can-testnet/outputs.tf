output "testnet_api_endpoint" {
  value = "https://${aws_route53_record.alb_api_node_record.name}"
  description = "Testnet API Endpoint"
}

output "testnet_history_endpoint" {
  value = "https://${aws_route53_record.alb_history_node_record.name}"
  description = "Testnet History Endpoint"
}

output "testnet_history_explorer" {
  value = "https://local.bloks.io/?nodeUrl=https://${aws_route53_record.alb_history_node_record.name}&coreSymbol=CAT&systemDomain=eosio"
  description = "Testnet History Explorer Endpoint"
}

output "testnet_state_endpoint" {
  value = "${aws_route53_record.ec2_state_node_record.name}:8080"
  description = "Testnet State Endpoint"
}

# output "testnet_api_node_ssh_command" {
#   value = "ssh ubuntu@${aws_instance.ec2_api_node.public_ip}"
#   description = "Testnet API Node SSH Command"
# }

# output "testnet_history_node_ssh_command" {
#   value = "ssh ubuntu@${aws_instance.ec2_history_node.public_ip}"
#   description = "Testnet History Node SSH Command"
# }

# output "testnet_state_node_ssh_command" {
#   value = "ssh ubuntu@${aws_instance.ec2_state_node.public_ip}"
#   description = "Testnet State Node SSH Command"
# }

# output "testnet_bp_1_ssh_command" {
#   value = "ssh ubuntu@${aws_instance.ec2_bp_1.public_ip}"
#   description = "Testnet BP Node 1 SSH Command"
# }

# output "testnet_bp_2_ssh_command" {
#   value = "ssh ubuntu@${aws_instance.ec2_bp_2.public_ip}"
#   description = "Testnet BP Node 2 SSH Command"
# }

# output "testnet_bp_3_ssh_command" {
#   value = "ssh ubuntu@${aws_instance.ec2_bp_3.public_ip}"
#   description = "Testnet BP Node 3 SSH Command"
# }