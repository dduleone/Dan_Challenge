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

## Coding: Prerequisites

- Tested on `Mac OSX 10.14.2` - `go version go1.14 darwin/amd64`

## Coding: How To Use

1. Check out the repository
2. `cd` to the Code folder
3. Run: `go run validate`
