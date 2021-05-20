# LocalStack AWS Batch bug reproduction steps

## Prerequisites

---

All the commands below are run from the root of this git repository.

The *awslocal* CLI tool is required.

## Step 1 - Build the test container

---

Build the container to use for AWS Batch:

```
docker build -t localhost:4510/test-function .
```

## Step 2 - Start LocalStack and setup the infrastructure

---

Startup LocalStack and then run the command within the file: *setup-stack.sh*

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

### Bug 1 - Environment variables (and possibly other container settings) not being applied to batch job container when job is submited directly

Submit a batch job:

```
awslocal batch submit-job --job-name test-1 --job-queue test-function-job-queue --job-definition test-function --container-overrides='environment=[{name=test-variable,value=test-value}]'
```

Then using the returned *jobId* look at the job details:

```
awslocal batch describe-jobs --jobs <Job ID>
```

**Notice that the environment variables are not present in the returned JSON information.**

---

### Bug 2 - Environment variables (and possibly other container settings) not being applied to batch job container when job is submited via Step Functions

Start a step function execution:

```
awslocal stepfunctions start-execution --state-machine-arn "arn:aws:states:us-east-1:000000000000:stateMachine:test-state-machine" --cli-binary-format raw-in-base64-out --input '{ }'
```

Find out the *JobId* of the job that was submited as part of the step function state machine. If *DEBUG* is set to enabled (*DEBUG=1*) in the LocalStack container environment variables, then the *JobId* should be availble in the debug logs.

Then using the returned *jobId* look at the job details:

```
awslocal batch describe-jobs --jobs <Job ID>
```

**Similar to *Bug 1* the environment variables are not present in the returned JSON information.**
