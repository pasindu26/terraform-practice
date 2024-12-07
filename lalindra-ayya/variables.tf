
#---provider-----
variable "provider_region" {
  default = "us-east-1"
}

#---VPC---
variable "vpc_cidr_block" {
  default = "192.168.0.0/16"
}

#---subnet----
variable "public_subnet_cird_block" {
  default = [
    "192.168.1.0/24",
  "192.168.2.0/24"]
}
variable "private_subnet_cird_block" {
  default = [
    "192.168.3.0/24",
  "192.168.4.0/24"]
}


#---tags----

variable "EC2_Name" {
  default = "test"
}

variable "project_name" {
  default = "ESIS"
}
variable "project_env" {
  default = "TEST"
}
variable "project_reg" {
  type = map(string)

  default = {
    us-east-1      = "nv"
    ap-south-1     = "mumbai"
    ap-southeast-1 = "sing"
  }
}