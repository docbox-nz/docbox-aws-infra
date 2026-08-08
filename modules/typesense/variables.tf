
variable "instance_type" {
  type    = string
  default = "t4g.small"
}

variable "instance_ami" {
  type = string

  # Canonical, Ubuntu, 24.04, arm64 noble image
  default = "ami-099eeb58169040255"
}

variable "proxy_host" {
  type = string
}

variable "proxy_port" {
  type = number
}

variable "instance_name" {
  type = string
}

variable "instance_role_name" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "security_group_name" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}


variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks that are allowed to use the typesense server"
}

variable "full_access_security_groups" {
  type        = list(string)
  description = "List of security group IDs to allow full ingress access. Used for providing VPN access"
  default     = []
}


variable "subnet_id" {
  type        = string
  description = "ID of the subnet to store the instance within, should be a private subnet"
}
