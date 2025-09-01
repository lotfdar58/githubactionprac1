Local GitHub Actions + Docker + Terraform + Lambda Simulation
This guide will help you simulate a GitHub Actions workflow locally, build a Docker image, push it to a local Docker registry, deploy a Lambda with Terraform using LocalStack, and verify the Lambda function.
You do not need a GitHub or AWS account.

Prerequisites
Install the necessary tools:

# Docker
brew install docker

# Terraform
brew install terraform

# GitHub Actions local runner
brew install act           # run GitHub Actions locally

# LocalStack (AWS services simulator)
brew install localstack    # or: pip install localstack

# Optional: awslocal helper for easier CLI commands
pip install awscli-local

Step 1: Build and Run Your App
Create a simple app (example in Python):

# app.py
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello from Docker Lambda!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)


Create a Dockerfile:

FROM python:3.10-slim
WORKDIR /app
COPY app.py .
RUN pip install flask
CMD ["python", "app.py"]


Build and run locally:
docker build -t my-app .
docker run -p 8080:8080 my-app


Visit http://localhost:8080 → you should see:
Hello from Docker Lambda!


Step 2: Local Docker Registry (Simulate ECR)
Start a local registry:

docker run -d -p 5000:5000 --name registry registry:2


Tag and push your image:
docker tag my-app localhost:5000/my-app:latest
docker push localhost:5000/my-app:latest


Step 3: Start LocalStack
localstack start -d


This simulates AWS services (Lambda, ECR, etc.) on your local machine.

Step 4: Terraform to Deploy Lambda
Create a Terraform folder infra/ with:
provider.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    lambda = "http://localhost:4566"
    ecr    = "http://localhost:4566"
  }
}


lambda.tf
resource "aws_lambda_function" "my_lambda" {
  function_name = "my-local-lambda"
  package_type  = "Image"
  image_uri     = "localhost:5000/my-app:latest"
  role          = "arn:aws:iam::000000000000:role/lambda-role"
}


Apply Terraform:
cd infra
terraform init
terraform apply -auto-approve


Step 5: GitHub Actions Workflow (Run Locally with act)
Create .github/workflows/deploy.yml:

name: Deploy to LocalStack

on:
  push:
    branches: [ "main" ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build Docker image
        run: docker build -t my-app .

      - name: Push to local registry
        run: |
          docker tag my-app localhost:5000/my-app:latest
          docker push localhost:5000/my-app:latest

      - name: Run Terraform
        run: |
          cd infra
          terraform init
          terraform apply -auto-approve


Run it locally:
act -j build-and-deploy


Step 6: Verify Lambda in LocalStack
Make sure LocalStack is running:
localstack start -d


List Lambda functions:
awslocal lambda list-functions

awslocal lambda list-functions
awslocal lambda invoke --function-name my-local-lambda --payload '{}' response.json
cat response.json
