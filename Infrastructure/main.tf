provider "aws" {
    region                  = "us-east-1"
    shared_credentials_file = "/Users/dduleone/.aws/credentials"
    profile                 = "dduleone"
}

# We need:
#   1 x VPC
#   2 x Subnet
#   1 x Internet Gateway
#   1 x SSH Key Pair

#   2 x Security Group
#   2 x Security Group Egress Rules
#   3 x Security Group Ingress Rules

#   1 x ACM (SSL) Certificate
#   1 x Route53 Zone
#   3 x Route53 Record
#   1 x ACM (SSL) Certificate Validation

#   1 x Launch Template
#   1 x Autoscaling Group
#   1 x Target Group

#   1 x S3 Bucket

#   1 x Load Balancer
#   1 x Load Balancer Route

#   1 x CloudFront Distribution

#   1 x Route Table Route
#   2 x Route Table Association

## Could Add
#   CloudWatch Alarms
#   SNS Topic for Alerts
#   Healthchecks
#   WAF

# Notes:
#   1. In a production environment, the EC2 instances don't need ingress rules for 0.0.0.0/0:22
#   2. Terraform 1.12 does not like interpolation-only expressions wrapped in "${}". 
#       However, my VSCode extension doesn't like expressions without them, so I've been ignoring the warning.

data "aws_availability_zones" "useast1" {}

data "aws_elb_service_account" "elb-svc" {}

data "aws_iam_policy_document" "s3_lb_write" {
    policy_id = "s3_lb_write"

    statement {
        actions = ["s3:PutObject"]
        resources = ["arn:aws:s3:::${var.s3_log_bucket}/*"]

        principals {
            identifiers = ["${data.aws_elb_service_account.elb-svc.arn}"]
            type = "AWS"
        }
    }
}

data "aws_route_table" "rttble-primary" {
    vpc_id = "${aws_vpc.cloud.id}"
}


# 1 x VPC should suffice.
resource "aws_vpc" "cloud" {
    cidr_block           = "${var.cidr_vpc}"
    enable_dns_hostnames = true

    tags = "${var.alltags}"
}

# 2 x Subnets for multizones
resource "aws_subnet" "primary" {
    vpc_id                  = "${aws_vpc.cloud.id}"
    cidr_block              = "${var.cidr_primary}"
    availability_zone       = "${data.aws_availability_zones.useast1.names[0]}"
    map_public_ip_on_launch = true
    
    tags = "${var.alltags}"
}
resource "aws_subnet" "secondary" {
    vpc_id                  = "${aws_vpc.cloud.id}"
    cidr_block              = "${var.cidr_secondary}"
    availability_zone       = "${data.aws_availability_zones.useast1.names[1]}"
    map_public_ip_on_launch = true
    
    tags = "${var.alltags}"
}

# 1 x Internet Gateway so public traffic can get in
resource "aws_internet_gateway" "ig" {
    vpc_id = "${aws_vpc.cloud.id}"

    tags = "${var.alltags}"
}


# 1 x SSH Key Pair so we can get to our EC2s
resource "aws_key_pair" "ssh-key" {
    key_name   = "${var.ssh_key}"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCGKaDKSORFMf/QVM9Dx1D700Di+AAxUTGx4YL05MT4mb9TVqXxAt4hrh9Pg5kkX/RMVdXGxDARt3my3P0cPj2WwhmQM+b8X1Lp2kne9qL0flpkrTtqTrhh0qWS+PE90I8HKFVoRLfMqH2L+2T3ARSx3NyWRMCxCXpQnlawujjF3gcGWWugoN6KHEnlDH6yzDv0wUxVgCw5r6LXFbD0gbmmaoHeaDRkWfCcDmcqZR6uJvDagfyGdFwWdcU8OlW2T2hQnH/6fl1PM8ZqSB6fHkTXEaVK3H4cYzY71aGAdvF4S5yXSvYaWfFVZwfEx/ugM2dXd0QRGu1PNaMrR9rwNwSj"
}


# 2 x Security Groups, one for our EC2s (ssh, http, egress) and one for our Load Balancer (http)
resource "aws_security_group" "sg-ec2" {
    name        = "${var.app_name}-ec2"
    description = "[${var.app_name}] Security Group for EC2 Instances in the ASG"
    vpc_id      = "${aws_vpc.cloud.id}"

    lifecycle {
        create_before_destroy = true
    }
    
    tags = "${var.alltags}"
}
    resource "aws_security_group_rule" "ec2-ingress-ssh" {
        description       = "Provide SSH ingress access to the EC2s."
        type              = "ingress"
        from_port         = 22
        to_port           = 22
        protocol          = "tcp"
        cidr_blocks       = ["0.0.0.0/0"]
        security_group_id = "${aws_security_group.sg-ec2.id}"
    }
    resource "aws_security_group_rule" "ec2-ingress-http" {
        description       = "Provide HTTP ingress access to the EC2s."
        type              = "ingress"
        from_port         = 80
        to_port           = 80
        protocol          = "tcp"
        cidr_blocks       = ["0.0.0.0/0"]
        security_group_id = "${aws_security_group.sg-ec2.id}"
    }
    resource "aws_security_group_rule" "ec2-egress" {
        description       = "Provide world egress access to the EC2s."
        type              = "egress"
        from_port         = 0
        to_port           = 65535
        protocol          = -1
        cidr_blocks       = ["0.0.0.0/0"]
        security_group_id = "${aws_security_group.sg-ec2.id}"
    }


resource "aws_security_group" "sg-lb" {
    name        = "${var.app_name}-lb"
    description = "[${var.app_name}] Security Group for LB"
    vpc_id      = "${aws_vpc.cloud.id}"

    lifecycle {
        create_before_destroy = true
    }

    tags = "${var.alltags}"
}
    resource "aws_security_group_rule" "lb-ingress-http" {
        description       = "Provide HTTP ingress access to the LB."
        type              = "ingress"
        from_port         = 80
        to_port           = 80
        protocol          = "tcp"
        cidr_blocks       = ["0.0.0.0/0"]
        security_group_id = "${aws_security_group.sg-lb.id}"
    }
    resource "aws_security_group_rule" "lb-egress" {
        description       = "Provide world egress access to the LB."
        type              = "egress"
        from_port         = 0
        to_port           = 65535
        protocol          = -1
        cidr_blocks       = ["0.0.0.0/0"]
        security_group_id = "${aws_security_group.sg-lb.id}"
    }


# 1 x SSL Certificate
resource "aws_acm_certificate" "cert-dule1" {
    domain_name       = "*.${var.domain_name}"
    subject_alternative_names = ["${var.domain_name}"]
    validation_method = "DNS"

    lifecycle {
        create_before_destroy = true
    }

    tags = "${var.alltags}"
}

# 1 x Route53 Zone
resource "aws_route53_zone" "r53z-dule1" {
    name    = "${var.domain_name}"
    comment = "${var.domain_name} Hosted Zone"

    tags = "${var.alltags}"


    # This updates the nameservers associated with the domain name.
    provisioner "local-exec" {
        environment = {
            NS1 = "${aws_route53_zone.r53z-dule1.name_servers[0]}"
            NS2 = "${aws_route53_zone.r53z-dule1.name_servers[1]}"
            NS3 = "${aws_route53_zone.r53z-dule1.name_servers[2]}"
            NS4 = "${aws_route53_zone.r53z-dule1.name_servers[3]}"
            DOMAIN_NAME= "${var.domain_name}"
        }
        command = "${var.update_nameservers_script}"
    }
}

# 3 x Route53 Records
resource "aws_route53_record" "www" {
    zone_id = "${aws_route53_zone.r53z-dule1.zone_id}"
    name    = "www.${var.domain_name}"
    type    = "A"
    alias {
        name    = "${aws_cloudfront_distribution.cfd-dule1.domain_name}"
        zone_id = "${aws_cloudfront_distribution.cfd-dule1.hosted_zone_id}"
        evaluate_target_health = true
    }
}
resource "aws_route53_record" "root" {
    zone_id = "${aws_route53_zone.r53z-dule1.zone_id}"
    name    = "${var.domain_name}"
    type    = "A"
    alias {
        name    = "${aws_cloudfront_distribution.cfd-dule1.domain_name}"
        zone_id = "${aws_cloudfront_distribution.cfd-dule1.hosted_zone_id}"
        evaluate_target_health = true
    }
}
resource "aws_route53_record" "r53r-cert-validation" {
    name    = "${aws_acm_certificate.cert-dule1.domain_validation_options.0.resource_record_name}"
    type    = "${aws_acm_certificate.cert-dule1.domain_validation_options.0.resource_record_type}"
    zone_id = "${aws_route53_zone.r53z-dule1.id}"
    records = ["${aws_acm_certificate.cert-dule1.domain_validation_options.0.resource_record_value}"]
    ttl     = 60
}

# 1 x ACM (SSL) Certificate
resource "aws_acm_certificate_validation" "cert-validation" {
    certificate_arn         = "${aws_acm_certificate.cert-dule1.arn}"
    validation_record_fqdns = ["${aws_route53_record.r53r-cert-validation.fqdn}"]
}

# 1 x Launch Template
resource "aws_launch_template" "dule1-ec2" {
    name          = "${var.app_name}-ec2"
    image_id      = "${var.ec2_ami}"
    instance_type = "${var.instance_type}" 
    key_name      = "${aws_key_pair.ssh-key.key_name}"
    instance_initiated_shutdown_behavior = "terminate"
    
    monitoring {
        enabled = true
    }

    network_interfaces {
        associate_public_ip_address = true
        security_groups             = ["${aws_security_group.sg-ec2.id}"]
    }
  
    tag_specifications {
        resource_type = "instance"
        tags = "${var.alltags}"
    }

    user_data = "${filebase64(var.userdata_script)}"
}

# 1 x Autoscaling Group
resource "aws_autoscaling_group" "asg-dule1" {
    name             = "asg-${var.app_name}"
    desired_capacity = 2
    max_size         = 3
    min_size         = 1

    launch_template {
        id      = "${aws_launch_template.dule1-ec2.id}"
        version = "$Latest"
    }

    vpc_zone_identifier = ["${aws_subnet.primary.id}", "${aws_subnet.secondary.id}"]

    tags = [{
        key   = "Application"
        value = "${var.alltags.Application}"
        propagate_at_launch = true
    }, {
        key   = "ManagedBy"
        value = "${var.alltags.ManagedBy}"
        propagate_at_launch = true
    }]

    target_group_arns = ["${aws_lb_target_group.lb-tg-dule1.arn}"]
}

# 1 x Load Balancer Target Group
resource "aws_lb_target_group" "lb-tg-dule1" {
    name     = "lb-tg-dule1"
    port     = 80
    protocol = "HTTP"
    vpc_id   = "${aws_vpc.cloud.id}"
}

# 1 x S3 Bucket for logs
resource "aws_s3_bucket" "s3-logs" {
  bucket = "${var.s3_log_bucket}"
  acl    = "log-delivery-write"
  policy = "${data.aws_iam_policy_document.s3_lb_write.json}"
}

# 1 x Load Balancer
resource "aws_lb" "lb-dule1" {
    name            = "lb-${var.app_name}"
    internal        = false
    security_groups = ["${aws_security_group.sg-lb.id}"]
    subnets         = ["${aws_subnet.primary.id}", "${aws_subnet.secondary.id}"]

    access_logs {
        bucket  = "${aws_s3_bucket.s3-logs.bucket}"
        prefix  = "${var.lb_log_prefix}"
        enabled = true
    }

    tags = "${var.alltags}"
}

# 1 x Load Balancer Routing
resource "aws_lb_listener" "lb-listener" {
    load_balancer_arn = "${aws_lb.lb-dule1.arn}"
    port              = "80"
    protocol          = "HTTP"
    default_action {
        type             = "forward"
        target_group_arn = "${aws_lb_target_group.lb-tg-dule1.arn}"
    }
}

# 1 x CloudFront Distribution
resource "aws_cloudfront_distribution" "cfd-dule1" {
    origin {
        domain_name = "${aws_lb.lb-dule1.dns_name}"
        origin_id   = "web-traffic"

        custom_origin_config {
            http_port = 80
            https_port = 443
            origin_protocol_policy = "http-only"
            origin_ssl_protocols = ["TLSv1.2"]
        }
    }

    enabled             = true
    comment             = "${var.domain_name}"
    default_root_object = "index.html"

    logging_config {
        include_cookies = false
        bucket  = "${aws_s3_bucket.s3-logs.bucket_domain_name}"
        prefix  = "${var.cf_log_prefix}"
    }

    aliases = ["${var.domain_name}", "www.${var.domain_name}"]

    default_cache_behavior {
        allowed_methods  = ["GET", "HEAD"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "web-traffic"

        forwarded_values {
            query_string = true
            cookies {
                forward = "all"
            }
        }
        compress               = true
        viewer_protocol_policy = "redirect-to-https"
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400
    }

    restrictions {
        geo_restriction {
            restriction_type = "whitelist"
            locations        = "${var.cf_geo_restriction_locations}"
        }
    }

    #Error: error creating CloudFront Distribution: InvalidViewerCertificate: The specified SSL certificate doesn't exist, isn't in us-east-1 region, isn't valid, or doesn't include a valid certificate chain.
    viewer_certificate {
        acm_certificate_arn            = "${aws_acm_certificate.cert-dule1.arn}"
        minimum_protocol_version       = "TLSv1.2_2018"
        ssl_support_method             = "sni-only"
    }

    tags = "${var.alltags}"
}




resource "aws_route" "internet-route" {
    route_table_id              = "${data.aws_route_table.rttble-primary.id}"
    destination_cidr_block    = "0.0.0.0/0"
    gateway_id      = "${aws_internet_gateway.ig.id}"
}
resource "aws_route_table_association" "primarysubnet-route-table" {
  subnet_id     = "${aws_subnet.primary.id}"
  route_table_id = "${data.aws_route_table.rttble-primary.id}"
}
resource "aws_route_table_association" "secondarysubnet-route-table" {
  subnet_id     = "${aws_subnet.secondary.id}"
  route_table_id = "${data.aws_route_table.rttble-primary.id}"
}
