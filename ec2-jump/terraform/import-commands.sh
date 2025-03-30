#!/bin/bash
# Import commands for Terraform resources

# VPC
terraform import aws_vpc.main vpc-00af673bedbcd4f68

# Subnet
terraform import aws_subnet.main subnet-0557f2389b5a9f6ec

# Internet Gateway
terraform import aws_internet_gateway.main igw-0034eade83f385382

# Route Table
terraform import aws_route_table.public rtb-00ac4b652869bf1ab

# Route (Internet Access)
terraform import aws_route.internet_access rtb-00ac4b652869bf1ab_0.0.0.0/0

# Route Table Association
terraform import aws_route_table_association.public rtbassoc-0f047cc6e06c6ab9a

# Security Group
terraform import aws_security_group.ssh sg-040375050ad6ae246

# Key Pair
terraform import aws_key_pair.jump_host_key_pair jump-host-key-004

# IAM Role (you may need to confirm which one is correct)
terraform import aws_iam_role.jump_host_role jump-host-devops-20250330013857318500000001

# IAM Instance Profile
terraform import aws_iam_instance_profile.jump_host_profile jump-host-profile

# EC2 Instance
terraform import aws_instance.jump_host i-03fab0fcc3e2a9665

# Secrets Manager Secret
terraform import aws_secretsmanager_secret.jump_host_key "arn:aws:secretsmanager:us-east-1:376129875476:secret:jump-host-key-20250330013734269800000001-K56noC"

# Note: For the TLS private key and Secrets Manager secret version, you may need to recreate those
# rather than importing them, as they contain sensitive information