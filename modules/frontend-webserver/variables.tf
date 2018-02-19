variable "aws_vpc" {
  description = "ID of destination VPC"
}

variable "instance_type" {
  description = "Size of Instance in ASG"
}

variable "key_name" {
  description = "SSH Public Key Name for instances"
}

variable "public_key_path" {
  description = "absolute SSH Public Key Path"
}

variable "vpc_zone_identifier" {
  type        = "list"
  description = "List of all subnet ID, where instances should be deployed in ASG"
}

variable "hcl_grace" {
  description = "Autoscaling group health check grace periode"
}

variable "asg_min_size" {}
variable "asg_max_size" {}
variable "asg_cap" {}

variable "elb_healthy_threshold" {}
variable "elb_interval" {}
variable "elb_health_target" {}
variable "elb_timeout" {}
variable "elb_unhealthy_threshold" {}
