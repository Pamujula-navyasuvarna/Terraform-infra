variable "aws_region" {
type = string
default = "ap-south-1"
}


variable "vpc_cidr" {
type = string
default = "10.0.0.0/16"
}


variable "public_subnets" {
type = list(string)
default = ["10.0.10.0/24", "10.0.20.0/24"]
}


variable "private_subnets" {
type = list(string)
default = ["10.0.101.0/24", "10.0.102.0/24"]
}


variable "azs" {
type = list(string)
default = ["${var.aws_region}a", "${var.aws_region}b"]
}


variable "cluster_name" {
type = string
default = "example.k8s.local"
}
