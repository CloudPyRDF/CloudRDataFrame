#!/bin/bash

set -ex
set -o pipefail

ecr_name=$1
region=$2
aws="docker run --rm -i -v ${HOME}/.aws:/root/.aws:ro amazon/aws-cli:2.8.7"

$aws ecr delete-repository --region ${region} --repository-name ${ecr_name} --force
