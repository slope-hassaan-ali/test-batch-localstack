#!/usr/bin/env bash

awslocal ecr create-repository --repository-name "test-function"
docker push localhost:4510/test-function

awslocal iam create-role \
  --role-name "test-batch-role" \
  --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "batch.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
awslocal iam attach-role-policy --role-name "test-batch-role" --policy-arn "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"

awslocal iam create-role \
  --role-name "test-batch-instance-role" \
  --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "ec2.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
awslocal iam attach-role-policy --role-name "test-batch-instance-role" --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"

awslocal iam create-instance-profile --instance-profile-name "ecsInstanceRole"
awslocal iam add-role-to-instance-profile --instance-profile-name "ecsInstanceRole" --role-name "test-batch-instance-role"

subnets=$(awslocal ec2 describe-subnets --query "Subnets[*].SubnetId" --output text | awk '{$1=$1}1' OFS=",")
security_groups=$(awslocal ec2 describe-security-groups --query "SecurityGroups[*].GroupId" --output text | awk '{$1=$1}1' OFS=",")
awslocal batch create-compute-environment \
  --compute-environment-name "test-compute-env" \
  --type "MANAGED" \
  --service-role "arn:aws:iam::000000000000:role/test-batch-role" \
  --compute-resources "type=EC2,allocationStrategy=BEST_FIT,minvCpus=4,maxvCpus=16,subnets=$subnets,instanceTypes=c3.xlarge,securityGroupIds=$security_groups,instanceRole=arn:aws:iam::000000000000:instance-profile/ecsInstanceRole"
awslocal batch create-job-queue \
  --job-queue-name "test-function-job-queue" \
  --priority 1 \
  --state "ENABLED" \
  --compute-environment-order "order=1,computeEnvironment=arn:aws:batch:us-east-1:000000000000:compute-environment/test-compute-env"
awslocal batch register-job-definition \
  --job-definition-name "test-function" \
  --type "container" \
  --container-properties 'image=localhost:4510/test-function,memory=2048, vcpus=4'

awslocal iam create-role \
  --role-name "test-state-machine-role" \
  --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "states.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
awslocal iam attach-role-policy --role-name "test-state-machine-role" --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

state_machine_json_string="$(python -c 'import json, sys;print(json.dumps(json.load(sys.stdin)))' < state-machine.json)"
awslocal stepfunctions create-state-machine \
  --name "test-state-machine" \
  --role-arn "arn:aws:iam::000000000000:role/test-state-machine-role" \
  --definition "$state_machine_json_string"
  