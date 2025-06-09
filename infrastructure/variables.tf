variable "aws_region" {
  type = string
}

variable "public_key_path" {
  type = string
}

variable "server_type" {
  type = string
}

variable "client_type" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "use_placement_group" {
  type    = bool
  default = true
}

variable "placement_group_strategy" {
  type    = string
  default = "cluster"
}
