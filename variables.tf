
variable "aws_region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_profile" {
  description = "The AWS cli profile to use"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the existing VPC"
  type        = string
}

variable "igw_id" {
  description = "Internet Gateway ID for the public subnet to use"
  type        = string
}

variable "ssh_public_key_path" {
  description = "File path to the SSH public key to use for SSH"
  type        = string
}

variable "ssh_private_key_path" {
  description = "File path to the SSH private key to use for SSH"
  type        = string
}

variable "api_instance_type" {
  description = "AWS instance class for the API EC2 server"
  type        = string
}

variable "converter_instance_type" {
  description = "AWS instance class for the office converter EC2 server"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to allocate resources within"
  type        = string
}

variable "vpn_security_group_id" {
  description = "ID of the security group the VPN is within to allow VPN access"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}
