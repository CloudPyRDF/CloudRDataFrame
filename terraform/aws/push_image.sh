#!/bin/bash

set -ex
set -o pipefail

ecr_name=$1
root_image_uri=$2
region=$3
root_image_prefix=$4

IFS=':' read -ra parts <<< "$root_image_uri"
root_image_tag="${parts[1]}"
local_image_name=${root_image_prefix}_root_${root_image_tag}:latest

aws="docker run --rm -i -v ${HOME}/.aws:/root/.aws:ro amazon/aws-cli:2.8.7"
aws_account_id=`${aws} sts get-caller-identity | grep "Account" | sed 's/[^0-9]//g'`

docker logout public.ecr.aws

${aws} ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${region}.amazonaws.com

if ! docker image inspect "${local_image_name}" &> /dev/null; then
  docker pull ${root_image_uri}
  docker tag ${root_image_uri} ${local_image_name}
fi

docker tag ${local_image_name} ${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${ecr_name}

docker push ${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${ecr_name}
