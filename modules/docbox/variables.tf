variable "instance_name" {
  type    = string
  default = "docbox-api"
}

variable "instance_profile_name" {
  type    = string
  default = "docbox-api-instance-profile"
}

variable "iam_role_name" {
  type    = string
  default = "docbox-api-role"
}

variable "security_group_name" {
  type    = string
  default = "docbox-api-sg"
}

variable "s3_access_policy_name" {
  type    = string
  default = "docbox_s3_access_policy"
}

variable "secrets_access_policy_name" {
  type    = string
  default = "docbox_secrets_access_policy"
}

variable "env_secret_name" {
  type    = string
  default = "docbox-env-file"
}

variable "instance_type" {
  type    = string
  default = "t4g.small"
}

variable "instance_ami" {
  type = string

  # Amazon Linux 2023 AMI 2023.10.20260105.0 arm64 HVM kernel-6.1
  default = "ami-0727d44a1158304d8"
}

variable "additional_policy_arns" {
  type        = map(string)
  default     = {}
  description = "Extra IAM policy ARNs to attach to this Lambda's role (e.g., SQS execution)"
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

variable "volume_size" {
  type    = number
  default = 8
}

variable "proxy_host" {
  type = string
}

variable "proxy_port" {
  type = number
}

variable "ssh_key_name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to store the instance within, should be a private subnet"
}
