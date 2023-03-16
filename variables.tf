variable "AWS_ACCESS_KEY" {
  default=""
}

variable "AWS_SECRET_KEY" {
  default=""
}
variable "aws_region" {
  default = "ap-south-1"
}

variable "env" {
  type = string
  default = ""
}

variable "image_id" {
  type = string
  default = ""
}

variable "instance_type" {
  type = string
  default = ""
}

variable "key_name" {
    default = ""
}

variable "vpc_id" {
  type = string
  default = ""
}

variable "lt_subnet_id" {
  type = string
  default = ""
}

variable "lt_security_groups" {
  type = list(string)
  default = ["sg-1", "sg-2"]
}

variable "lb_security_groups" {
  type = list(string)
  default = ["sg-1"]
}

variable "alb_subnets" {
  type = list(string)
  default = ["pub-subnet-id-1", "pub-subnet-id-2"]
}

variable "nlb_subnets" {
  type = list(string)
  default = ["pri-subnet-id-1", "pri-subnet-id-2"]
}