variable "aws_region" {
  description = "AWS region for the TravelMemory deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  default = "travelmemory"
}

variable "my_ip" {
  description = "Your public IPv4 address with /32"
  type        = string
}

variable "key_name" {
  default = "travelmemory-key"
}

variable "public_key_path" {
  description = "Path to an existing SSH public key; the matching private key is used by Ansible"
  type        = string
  default     = "~/.ssh/travelmemory.pub"
}

variable "web_instance_type" {
  default = "t3.small"
}

variable "db_instance_type" {
  default = "t3.micro"
}