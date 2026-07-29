variable "instance_ami" {
  type = string
  # Amazon Linux 2023 AMI 2023.7.20250527.1 arm64 HVM kernel-6.1
  default     = "ami-0a06008c37dfe916b"
  description = "AMI to use for the created instance, must be Amazon Linux 2023 or a similar distro with yum and squid available in the package registry"
}

variable "instance_type" {
  type        = string
  default     = "t4g.nano"
  description = "Instance type, a small ARM instance is recommended as the service is not very resource intensive and only proxies short lived HTTP requests"
}

variable "public_subnet_id" {
  type        = string
  description = "ID of the public subnet to store the instance within, must be a public subnet with internet access"
}

variable "cpu_credits" {
  type        = string
  description = "Credit option for CPU usage, prefer standard as we don't need boosting for this type of server"
  default     = "standard"

  validation {
    condition     = contains(["standard", "unlimited"], var.cpu_credits)
    error_message = "cpu_credits must be either 'standard' or 'unlimited'"
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "instance_name" {
  type        = string
  description = "Name for the proxy EC2 instance"
}

variable "instance_profile_name" {
  type        = string
  description = "Name for the proxy EC2 instance profile"
}

variable "iam_role_name" {
  type        = string
  description = "Name for the proxy EC2 instance role"
}

variable "security_group_name" {
  type        = string
  description = "Name for the proxy security group"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks that are allowed to use the HTTP proxy"
}

variable "full_access_security_groups" {
  type        = list(string)
  description = "List of security group IDs to allow full ingress access. Used for providing VPN access"
  default     = []
}
