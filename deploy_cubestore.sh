#!/bin/bash

set -e

AWS_REGION="us-east-1"
ECR_REPOSITORY="prod-sync-cubestore-ecr"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || date +%s)

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY

docker build --platform linux/amd64 -t $REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG -f docker/cubestore/Dockerfile .
docker push $REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

echo "New cubestore image pushed to ECR: $REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG. Please update terraform cubestore services task definitions accordingly."