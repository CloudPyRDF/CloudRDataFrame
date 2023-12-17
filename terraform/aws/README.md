# Installation

Table of contents
 * [Requirements](#reqirements)
 * [Installation](#installation)

public docker image: https://gallery.ecr.aws/u1r6s2k6/root_lambda

## Requirements

The following tools are necessary for seting up infrastructure:
* terraform
* Docker ([as non-root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user))
* Docker based aws-cli version 2.8.7 from Docker Hub ([docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-docker.html))

Before proceeding to the next section, ensure that all necessary tools are installed.

Requirements can be verified by running:
```bash
docker run --rm -it  amazon/aws-cli:2.8.7 --version

terraform --version
```

## Installation

Put aws credentials to `$HOME/.aws/credentials` file as default credentials.

Some options can be configured in [tf/variables.tfvars](tf/variables.tfvars) file. Especially lambda parameters and aws region. Also there is an option to create lambda based on existing role by providing arn: `lambda_role_arn = "arn:aws:iam::..."`.

```bash
# Clone this repository ... (checkout on this branch)

# Go to tf directory
cd tf

terraform init

# This can take some time
terraform apply -var-file="variables.tfvars"

```
