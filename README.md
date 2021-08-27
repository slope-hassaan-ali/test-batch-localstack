# LocalStack AWS Batch bug reproduction steps

## Prerequisites

---

All the commands below are run from the root of this git repository.

The *awslocal* CLI tool is required.

A docker compose YAML file (called *docker-compose.yml*) is included for running LocalStack.

## Step 1 - Build the test container

---

Build the container to use for AWS Batch:

```
docker build -t localhost:4510/test-function .
```

## Step 2 - Start LocalStack and setup the infrastructure

---

Startup LocalStack and then run the commands within the file: *setup-stack.sh*

Alternatively you can run the script directly by first making it an executable via:

```
chmod +x ./setup-stack.sh 
```

Then do:

```
./setup-stack.sh
```

## Step 3 - Start a batch job

---

### Bug 1 - Batch jobs run from a Step Function result in a 500 error when it tries to run it

**Note: The JSON for the step function used here is located in** ***second-state-machine.json***

**Note: DEBUG=1 is required to see the error.**

Start a step function execution:

```
awslocal stepfunctions start-execution --state-machine-arn "arn:aws:states:us-east-1:000000000000:stateMachine:test-second-state-machine" --cli-binary-format raw-in-base64-out --input '{ "Environment": [ { "Name": "EnvironmentName", "Value": "test" }, { "Name": "TId", "Value": "1" }, { "Name": "CacheKey", "Value": "59442434-b604-46ca-80a2-d57e9cc57879" }, { "Name": "Id", "Value": "247294" }, { "Name": "UserId", "Value": "5029" }, { "Name": "RecordLimit", "Value": null } ] }'
```

Within a few seconds LocalStack will try to run the batch job within the step function but will fail and produce an error that looks similar to this:

```
127.0.0.1 - - [27/Aug/2021 13:46:51] "POST /v1/describejobs HTTP/1.1" 500 -
Error on request:
```
