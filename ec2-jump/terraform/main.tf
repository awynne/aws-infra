# Configure the AWS provider with the desired region
provider "aws" {
  region = "us-east-1"
}

# Create a VPC with DNS support and hostnames enabled
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc" # Tag for identifying the VPC
  }
}

# Create a public subnet within the VPC
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Automatically assign public IPs to instances
  availability_zone       = "us-east-1a"
  tags = {
    Name = "main-subnet" # Tag for identifying the subnet
  }
}

# Create an Internet Gateway to allow access to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw" # Tag for identifying the Internet Gateway
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-rt" # Tag for identifying the route table
  }
}

# Add a route to the internet via the Internet Gateway
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

# Create a security group to allow SSH access
resource "aws_security_group" "ssh" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  # Inbound rule to allow SSH (port 22) from any IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule to allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh" # Tag for identifying the security group
  }
}

# Generate a key pair for the EC2 instance
resource "tls_private_key" "jump_host_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create AWS key pair using the generated TLS key
resource "aws_key_pair" "jump_host_key_pair" {
  key_name   = "jump-host-key-005"
  public_key = tls_private_key.jump_host_key.public_key_openssh
  
  # Ignore errors if the key already exists
  lifecycle {
    ignore_changes = [public_key]
  }
}

# Create IAM role for the jump host with DevOps capabilities
resource "aws_iam_role" "jump_host_role" {
  name_prefix = "jump-host-devops-"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  # Add managed policies for comprehensive DevOps access
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]
  
  tags = {
    Name = "jump-host-devops-role"
  }
}

# Create an instance profile using the IAM role
resource "aws_iam_instance_profile" "jump_host_profile" {
  name = "jump-host-profile"
  role = aws_iam_role.jump_host_role.name
}

# Launch an EC2 instance to act as a jump host
resource "aws_instance" "jump_host" {
  ami                    = "ami-0655cec52acf2717b" # Ubuntu 22.04 LTS AMI (Free Tier eligible)
  instance_type          = "t2.micro" # Instance type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.ssh.id] # Attach the SSH security group
  key_name               = aws_key_pair.jump_host_key_pair.key_name # Use the generated key pair
  iam_instance_profile   = aws_iam_instance_profile.jump_host_profile.name # Attach the IAM instance profile

  tags = {
    Name        = "jump-host" # Tag for identifying the instance
    Provisioned = "ansible"   # Tag to indicate provisioning method
    OS          = "ubuntu"    # Tag to indicate operating system
  }

  # Simple provisioner to indicate instance is being created
  provisioner "local-exec" {
    command = "echo 'EC2 instance ${self.id} created with IP ${self.public_ip}'"
  }

  # Generate Ansible inventory file (but don't run Ansible)
  provisioner "local-exec" {
    command = "echo '${templatefile("${path.module}/../ansible/inventory.tpl", {
      jump_host_ip = self.public_ip,
      secret_name = aws_secretsmanager_secret.jump_host_key.id
    })}' > ${path.module}/../ansible/inventory"
  }
}

# Private key is now stored only in AWS Secrets Manager
# No need to save locally

# Store the private key in AWS Secrets Manager
resource "aws_secretsmanager_secret" "jump_host_key" {
  name_prefix = "jump-host-key-"
  description = "SSH private key for the Jump Host"
  
  tags = {
    Environment = "Development"
    Purpose     = "SSH Access"
  }
  
  recovery_window_in_days = 0  # Set to 0 for immediate deletion
}

# Store the private key value in the secret
resource "aws_secretsmanager_secret_version" "jump_host_key_value" {
  secret_id     = aws_secretsmanager_secret.jump_host_key.id
  secret_string = tls_private_key.jump_host_key.private_key_pem
}
