# SED Challenge

There are two parts to the challenge:

- Infrastructure
- Coding

## Infrastructure: Prerequisites

- Tested on `Mac OSX 10.14.2` - `Terraform v0.12.21`
- Assumes AWS CLI is already installed and configured with credentials

## Infrastructure: How To Use

1. Check out the repository
2. `cd` to the Infrastructure folder
3. Register new domain name
4. Configure vars.tf
5. Run: `terraform apply`
6. After successful deployment, run: `./validate.sh` for automated tests

## Infrastructure: Demo
[http://dule1.com](http://dule1.com)
[https://dule1.com](https://dule1.com)
[http://www.dule1.com](http://www.dule1.com)
[https://www.dule1.com](https://www.dule1.com)

## Infrastructure: Notes

The instructions for this challenge explicitly talk about "a running instance of a web server". So I supplied a traditional server-based implementation. However, if possible, when architecting "a scalable and secure static web application in AWS" I would suggest a serverless application - serving content driectly from S3, for its security, scalability and affordability. This would allow us to simplify the Security Groups and eliminate the Launch Template, Autoscaling Group, Target Group, and Load Balancer. It also eliminates the EC2 compute attack vector, and scales for traffic without the need to wait for EC2 provisioning.

## Coding: Prerequisites

- Tested on `Mac OSX 10.14.2` - `go version go1.14 darwin/amd64`

## Coding: How To Use

1. Check out the repository
2. `cd` to the Code folder
3. Run: `go run validate`
