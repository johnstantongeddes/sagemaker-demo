#!/bin/bash

#####################
# set some parameters
#####################

algorithm_name=sgmkr-demo

# need AWS CLI and IAM role properly configured
aws_account=$(aws sts get-caller-identity --query Account --output text)

# get the region defined in the current configuration
aws_region=$(aws configure get region)

# name for Docker
fullname="${aws_account}.dkr.ecr.${aws_region}.amazonaws.com/${algorithm_name}:latest"

# ECR repo path
ecr_repo="${aws_account}.dkr.ecr.${aws_region}.amazonaws.com/${algorithm_name}"

# IAM role for Sagemaker, needs to be created in advance using IAM
sagemaker_arn="arn:aws:iam::${aws_account}:role/acct-managed/sagemaker-full-access"


########################
# build Docker image 
# and push to ECR
#######################

# create repository in ECR
aws ecr create-repository --region "${aws_region}" --repository-name "${algorithm_name}"

# Get the login command from ECR and execute it directly
$(aws ecr get-login --region ${aws_region} --no-include-email)

# Build the docker image locally with the image name and then push it to ECR
# with the full name.
docker build -t ${algorithm_name} .
docker tag ${algorithm_name} ${fullname}

docker push ${fullname}

########################
# create sagemaker model, endpoint config
# and endpoint
#######################

# create sagemaker model
aws sagemaker create-model --model-name $algorithm_name  --primary-container Image=$ecr_repo --execution-role-arn $sagemaker_arn

# create sagemaker endpoint config
config_name="${algorithm_name}-config"

aws sagemaker create-endpoint-config --endpoint-config-name $config_name --production-variants VariantName=variant-1,ModelName=${algorithm_name},InitialInstanceCount=1,InstanceType=ml.m4.xlarge,InitialVariantWeight=1

# create sagemaker HTTPS endpoint
endpoint_name="${algorithm_name}-endpoint"

aws sagemaker create-endpoint --endpoint-name $endpoint_name --endpoint-config-name $config_name


########################
# invoke endpoint!
#######################

#aws runtime.sagemaker invoke-endpoint --endpoint-name $endpoint_name --body "{\"hmtime\": \"1:30:00\", \"gender\": \"M\"}" response.txt
aws runtime.sagemaker invoke-endpoint --endpoint-name $endpoint_name --body '{"debt": 100000}' response.txt
