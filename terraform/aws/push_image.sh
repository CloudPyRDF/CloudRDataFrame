#!/bin/bash

set -e
set -o pipefail

ecr_name=$1
root_image_uri=$2
region=$3
aws="docker run --rm -i -v ${HOME}/.aws:/root/.aws:ro amazon/aws-cli:2.8.7"
aws_account_id=`${aws} sts get-caller-identity | grep "Account" | sed 's/[^0-9]//g'`

docker login --username AWS --password $(${aws} ecr get-login-password --region ${region}) ${aws_account_id}.dkr.ecr.${region}.amazonaws.com

docker pull ${root_image_uri}

docker tag ${root_image_uri} ${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${ecr_name}

docker push ${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${ecr_name}
