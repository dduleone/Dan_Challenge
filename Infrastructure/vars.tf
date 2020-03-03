variable "domain_name" {
    default = "dule1.com"
}

variable "app_name" {
    default = "dule1"
}

variable "alltags" {
    default = {
        "Application" = "dule1.com"
        "ManagedBy" = "terraform"
    }
}

variable "userdata_script" {
    default = "userdata.sh"
}

variable "update_nameservers_script" {
    default = "./update_nameservers.sh"
}

variable "ssh_key" {
    default = "DuLeoneAWSKey"
}

variable "ec2_ami" {
    # [us-east-1]: Amazon Linux 2 AMI
    default = "ami-0a887e401f7654935"
}

variable "instance_type" {
    default = "t2.micro"
}

variable "cidr_vpc" {
    default = "10.0.0.0/16"
}

variable "cidr_primary" {
    default = "10.0.0.0/24"
}

variable "cidr_secondary" {
    default = "10.0.1.0/24"
}

variable "s3_log_bucket" {
    default = "dule1.com-logs"
}

variable "cf_geo_restriction_locations" {
    default = ["US"]
}
variable "cf_log_prefix" {
    default = "cf/"
}

variable "lb_log_prefix" {
    default = "lb"
}
