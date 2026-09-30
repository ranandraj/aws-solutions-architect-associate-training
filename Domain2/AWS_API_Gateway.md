# Amazon API Gateway - AWS SAA-C03 Professional Documentation

## 1. Overview

Amazon API Gateway is a managed service for creating, publishing, securing, monitoring, and managing APIs. It can expose Lambda functions, HTTP endpoints, and supported AWS services through API endpoints. API Gateway supports REST APIs, HTTP APIs, and WebSocket APIs. AWS documentation describes REST APIs as collections of resources and methods, HTTP APIs as collections of routes and methods, and WebSocket APIs as route-based persistent client connections. [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)

For SAA-C03, API Gateway is especially relevant to serverless architectures, scalable API front ends, loose coupling, authentication and authorization, throttling, private APIs, integration with Lambda, and API lifecycle management.

---

## 2. SAA-C03 Relevance

API Gateway commonly appears in architecture questions involving:

- Lambda-based serverless applications
- Public REST APIs
- HTTP APIs with Lambda or HTTP backends
- Mobile/web application backends
- Authentication and authorization
- API throttling and quotas
- CORS
- Private APIs inside a VPC
- Integration with ALB or other HTTP services
- Decoupled architectures
- CloudWatch monitoring and logging
- AWS WAF protection
- Multi-stage deployments

AWS's SAA-C03 exam guide includes API Gateway among services used to design scalable and loosely coupled architectures. See the [AWS SAA-C03 Exam Guide](https://aws.amazon.com/certification/certified-solutions-architect-associate/).

---

# 3. API Gateway Architecture

A common serverless architecture is:

```text
Client
  |
  | HTTPS
  v
API Gateway
  |
  | Integration
  v
AWS Lambda
  |
  v
DynamoDB / S3 / RDS / Other AWS Services
```

For an HTTP backend:

```text
Client
  |
  v
API Gateway
  |
  | HTTP/HTTPS integration
  v
ALB / EC2 / ECS / External HTTP endpoint
```

For a private API:

```text
Client inside VPC
        |
        v
Interface VPC Endpoint
        |
        v
Private API Gateway REST API
        |
        v
Backend integration
```

AWS documents private REST APIs as APIs that can be invoked only from a VPC through an API Gateway VPC endpoint. [Create a private API](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-private-api-create.html)

---

# 4. API Gateway API Types

| Feature | REST API | HTTP API | WebSocket API |
|---|---|---|---|
| Main model | Request/response | Request/response | Persistent connection |
| Typical use | Feature-rich APIs | Lower-cost/simple APIs | Real-time applications |
| Lambda integration | Yes | Yes | Yes |
| HTTP backend | Yes | Yes | Yes, through WebSocket integration |
| Authentication | IAM, Lambda authorizer, Cognito and other REST features | JWT/OIDC and Lambda authorizers | IAM, Lambda authorizers |
| Usage plans/API keys | Yes | More limited than REST API | Supported API concepts differ |
| API caching | REST API feature | Not the same REST caching model | Not REST caching |
| Request/response mapping | Extensive | Simplified | Message/route based |
| Private API | REST private APIs | Private integrations have different architecture | WebSocket architecture differs |
| Automatic deployment | No, deployment is explicit | Supported | Stage/deployment model applies |
| Cost/features | More features, generally higher cost | Designed for lower cost and lower latency | Designed for persistent connections |
| SAA-C03 focus | High | High | Moderate |

AWS states that REST APIs provide more features than HTTP APIs, while HTTP APIs are designed with a smaller feature set and lower price. [HTTP APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)

---

# 5. Core REST API Concepts

## 5.1 Resource

A resource represents a path in the API.

Example:

```text
/users
/orders
/products
```

## 5.2 Method

A method defines the HTTP operation exposed on a resource.

Examples:

```text
GET /users
POST /users
GET /users/{id}
DELETE /users/{id}
```

AWS describes a REST API as a collection of resources, with methods attached to resources and integrations connecting methods to backend endpoints. [Develop REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/rest-api-develop.html)

## 5.3 Integration

The integration defines where API Gateway sends the request.

Common integration targets include:

- Lambda
- HTTP/HTTPS endpoint
- AWS services
- Mock integration
- Private integration through VPC connectivity

## 5.4 Deployment

A deployment is a point-in-time snapshot of the API configuration.

## 5.5 Stage

A stage is a named lifecycle environment such as:

```text
dev
qa
prod
```

A REST API must be deployed to a stage before clients can invoke it. API Gateway's URL includes the stage for REST APIs. [Deploy REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-deploy-api.html)

---

# 6. Request Flow

For a Lambda proxy integration:

```text
1. Client sends HTTPS request
          |
          v
2. API Gateway receives request
          |
          v
3. Authentication/authorization
          |
          v
4. Throttling / request processing
          |
          v
5. API Gateway invokes Lambda
          |
          v
6. Lambda processes request
          |
          v
7. Lambda returns response
          |
          v
8. API Gateway returns HTTP response
          |
          v
9. Client receives response
```

In Lambda proxy integration, API Gateway passes request information such as headers, query parameters, path variables, and body to Lambda. [Lambda integrations](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-integrations.html)

---

# 7. Lambda Proxy vs Non-Proxy Integration

| Feature | Lambda Proxy | Lambda Non-Proxy |
|---|---|---|
| Setup | Simple | More configuration |
| Request mapping | Lambda receives request structure | API Gateway mapping templates can transform input |
| Response mapping | Lambda controls response | API Gateway can transform response |
| Flexibility | High for application code | High for API transformation |
| Recommended for simple serverless APIs | Yes | When transformation is required |
| API Gateway mapping templates | Usually unnecessary | Commonly used |

AWS describes Lambda proxy integration as lightweight and flexible. Non-proxy integration requires explicit mapping of request and response data. [Lambda integration tutorial](https://docs.aws.amazon.com/apigateway/latest/developerguide/getting-started-with-lambda-integration.html)

---

# 8. Endpoint Types for REST APIs

REST APIs support:

| Endpoint type | Description | Typical use |
|---|---|---|
| Regional | Endpoint in the selected AWS Region | Regional clients and custom CloudFront architectures |
| Edge-optimized | Uses CloudFront-managed edge infrastructure | Global client access |
| Private | Accessible from VPCs through interface VPC endpoints | Internal/private APIs |

For SAA-C03, remember:

```text
Public API + regional clients      -> Regional
Global public API                 -> Edge-optimized or CloudFront architecture
Internal API inside VPC           -> Private API
```

---

# 9. Authentication and Authorization

API Gateway provides multiple access-control mechanisms depending on API type.

## REST API options

- IAM authorization
- Lambda authorizers
- Amazon Cognito user pools
- API Gateway resource policies
- API keys and usage plans for metering/throttling, not primary authentication

AWS explicitly recommends not using API keys as the authentication or authorization mechanism. API keys are intended to identify clients for usage plans, quotas, and throttling. [Usage plans and API keys](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-usage-plans.html)

## Lambda Authorizer

```text
Client
  |
  | Bearer token / request data
  v
API Gateway
  |
  v
Lambda Authorizer
  |
  | Allow/Deny policy
  v
Backend integration
```

[AWS Lambda authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html)

---

# 10. API Gateway Resource Policies

Resource policies are resource-based policies attached to an API.

They can restrict access based on:

- AWS accounts
- Source IP ranges
- VPCs
- VPC endpoints

AWS documents resource policies separately from IAM identity policies. [API Gateway resource policies](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-resource-policies.html)

---

# 11. Throttling

API Gateway uses throttling to control request rates.

The token-bucket model uses:

- Rate
- Burst

When requests exceed configured limits, API Gateway can return:

```text
HTTP 429 Too Many Requests
```

Throttling is applied on a best-effort basis and should not be treated as an exact hard request ceiling. [API Gateway throttling](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-request-throttling.html)

Example:

```text
Rate  = 100 requests/second
Burst = 200 requests
```

This does not mean that exactly 100 requests per second will always be accepted.

---

# 12. API Keys and Usage Plans

A usage plan can associate:

```text
API Key
   |
   v
Usage Plan
   |
   +-- API
   +-- Stage
   +-- Throttle
   +-- Quota
```

Use API keys primarily for:

- Client identification
- Usage metering
- Throttling
- Quotas

Do not use API keys as the primary authentication mechanism. [AWS usage plans](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-usage-plans.html)

---

# 13. CORS

CORS is required when a browser-based application hosted on one origin calls an API hosted on another origin.

Example:

```text
Frontend:
https://www.example.com

API:
https://api.example.com
```

API Gateway can configure CORS responses for supported API types. Configure only the required origins, methods, and headers.

---

# 14. API Gateway and Lambda Architecture

Recommended serverless architecture:

```text
                    Internet
                       |
                       v
                API Gateway
                       |
                       v
                    Lambda
                       |
              +--------+--------+
              |                 |
              v                 v
          DynamoDB             S3
```

Advantages:

- No server management for API tier
- Automatic scaling of managed components
- Fine-grained authorization
- Throttling
- Integration with monitoring and logging
- Strong fit for event-driven/serverless architectures

---

# 15. Management Console Lab

The following lab creates:

```text
Client
  |
  | HTTPS
  v
API Gateway REST API
  |
  | Lambda proxy integration
  v
Lambda
  |
  v
JSON response
```

We will create:

```text
API name: SAA-APIGateway-Demo
Resource: /hello
Method: GET
Integration: Lambda Proxy
Stage: dev
```

---

# 16. Console Step 1 - Create Lambda Function

Open the AWS Lambda console.

Choose:

```text
Create function
```

Select:

```text
Author from scratch
```

Function name:

```text
saa-api-gateway-demo
```

Runtime:

```text
Python 3.x
```

Create the function.

Use a simple function:

```python
import json


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": "Hello from API Gateway",
            "service": "AWS Lambda"
        })
    }
```

Deploy the function.

AWS's official API Gateway tutorial uses the same basic Lambda proxy architecture. [Create a REST API with Lambda proxy integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-create-api-as-simple-proxy-for-lambda.html)

---

# 17. Console Step 2 - Create REST API

Open:

**API Gateway → APIs → Create API**

Under REST API choose:

```text
Build
```

Enter:

```text
API name:
SAA-APIGateway-Demo

Endpoint type:
Regional
```

Choose:

```text
Create API
```

---

# 18. Console Step 3 - Create Resource

Inside the API:

Choose:

```text
Resources → Create resource
```

Enter:

```text
Resource name:
hello

Resource path:
/hello
```

Create the resource.

---

# 19. Console Step 4 - Create GET Method

Select `/hello`.

Choose:

```text
Create method
```

Select:

```text
GET
```

Integration type:

```text
Lambda Function
```

Enable:

```text
Lambda proxy integration
```

Select:

```text
saa-api-gateway-demo
```

Save the method.

API Gateway may ask for permission to invoke Lambda. Allow it.

---

# 20. Console Step 5 - Test the Method

Select:

```text
GET /hello
```

Choose:

```text
Test
```

Execute the request.

Expected result:

```json
{
  "message": "Hello from API Gateway",
  "service": "AWS Lambda"
}
```

---

# 21. Console Step 6 - Deploy API

Choose:

```text
Actions / Deploy API
```

Create a new stage:

```text
Stage name:
dev
```

Deploy.

API Gateway requires deployment to a stage before clients can invoke the REST API. [Deploy REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-deploy-api.html)

---

# 22. Console Step 7 - Invoke API

Copy the Invoke URL.

It will resemble:

```text
https://API-ID.execute-api.ap-south-1.amazonaws.com/dev/hello
```

Test:

```bash
curl https://API-ID.execute-api.ap-south-1.amazonaws.com/dev/hello
```

Expected:

```json
{
  "message": "Hello from API Gateway",
  "service": "AWS Lambda"
}
```

---

# 23. Console Step 8 - Enable Logging

API Gateway can send execution/access logs to CloudWatch Logs.

For REST APIs, configure the stage settings and CloudWatch logging according to the API Gateway documentation.

Recommended production logging:

- Access logs
- Execution logs where appropriate
- CloudWatch metrics
- AWS CloudTrail for management operations

Avoid logging secrets, tokens, passwords, and sensitive request bodies.

---

# 24. AWS CLI Implementation

The CLI example below creates a REST API with:

```text
/hello
GET
Lambda proxy integration
```

Set the Region:

```bash
export AWS_REGION=ap-south-1
```

---

## 24.1 Create REST API

```bash
aws apigateway create-rest-api \
  --name SAA-APIGateway-CLI \
  --endpoint-configuration types=REGIONAL \
  --region $AWS_REGION
```

AWS CLI reference: [create-rest-api](https://docs.aws.amazon.com/cli/latest/reference/apigateway/create-rest-api.html)

Save the returned `id`:

```text
API_ID
```

---

## 24.2 Get Root Resource

```bash
aws apigateway get-resources \
  --rest-api-id $API_ID \
  --region $AWS_REGION
```

Find the root resource ID and set:

```bash
export ROOT_ID=xxxxxxxx
```

---

## 24.3 Create `/hello`

```bash
aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part hello \
  --region $AWS_REGION
```

Save:

```text
RESOURCE_ID
```

---

## 24.4 Create GET Method

```bash
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method GET \
  --authorization-type NONE \
  --region $AWS_REGION
```

AWS provides CLI examples for `put-method` in the API Gateway CLI documentation. [API Gateway CLI examples](https://docs.aws.amazon.com/cli/latest/userguide/cli_api-gateway_code_examples.html)

---

## 24.5 Get Lambda ARN

```bash
aws lambda get-function \
  --function-name saa-api-gateway-demo \
  --query 'Configuration.FunctionArn' \
  --output text \
  --region $AWS_REGION
```

Set:

```bash
export LAMBDA_ARN=arn:aws:lambda:ap-south-1:123456789012:function:saa-api-gateway-demo
```

---

## 24.6 Create Lambda Integration

The Lambda integration URI uses the Lambda invocation API.

```bash
export INTEGRATION_URI="arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations"
```

Create the integration:

```bash
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "$INTEGRATION_URI" \
  --region $AWS_REGION
```

Important: for a Lambda integration, the integration HTTP method is `POST` because API Gateway invokes the Lambda service API.

---

## 24.7 Allow API Gateway to Invoke Lambda

```bash
aws lambda add-permission \
  --function-name saa-api-gateway-demo \
  --statement-id apigateway-invoke-demo \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:${AWS_REGION}:ACCOUNT_ID:${API_ID}/*/GET/hello" \
  --region $AWS_REGION
```

Replace:

```text
ACCOUNT_ID
API_ID
```

with your values.

---

## 24.8 Deploy API

```bash
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name dev \
  --region $AWS_REGION
```

Then invoke:

```bash
curl "https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/dev/hello"
```

---

# 25. Terraform Implementation

Terraform REST API resources are provided through API Gateway REST API resources such as:

- `aws_api_gateway_rest_api`
- `aws_api_gateway_resource`
- `aws_api_gateway_method`
- `aws_api_gateway_integration`
- `aws_api_gateway_deployment`
- `aws_api_gateway_stage`

Terraform uses API Gateway Version 1 resources for REST APIs and Version 2 resources for HTTP and WebSocket APIs. [Terraform API Gateway REST API](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api)

---

# 26. Terraform Provider

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}
```

Pin the provider version according to your organization's current approved version rather than copying an old version blindly.

---

# 27. Terraform Lambda Function

```hcl
resource "aws_lambda_function" "api" {
  function_name = "saa-api-gateway-demo"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
}
```

The IAM role is required for Lambda execution.

---

# 28. Terraform REST API

```hcl
resource "aws_api_gateway_rest_api" "api" {
  name        = "SAA-APIGateway-Terraform"
  description = "SAA-C03 API Gateway demonstration"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
```

---

# 29. Terraform Resource

```hcl
resource "aws_api_gateway_resource" "hello" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "hello"
}
```

---

# 30. Terraform GET Method

```hcl
resource "aws_api_gateway_method" "get_hello" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "GET"
  authorization = "NONE"
}
```

Terraform's `aws_api_gateway_method` resource creates an HTTP method for an API Gateway resource. [Terraform aws_api_gateway_method](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method)

---

# 31. Terraform Lambda Integration

```hcl
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.hello.id
  http_method = aws_api_gateway_method.get_hello.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api.invoke_arn
}
```

---

# 32. Lambda Permission

```hcl
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/GET/hello"
}
```

---

# 33. Terraform Deployment

```hcl
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_integration.lambda
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.hello.id,
      aws_api_gateway_method.get_hello.id,
      aws_api_gateway_integration.lambda.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

---

# 34. Terraform Stage

```hcl
resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "dev"
}
```

Output the URL:

```hcl
output "api_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.ap-south-1.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}/hello"
}
```

Run:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Then:

```bash
terraform output api_url
```

Test:

```bash
curl "$(terraform output -raw api_url)"
```

---

# 35. API Gateway + ALB / ECS / EC2

API Gateway can integrate with HTTP endpoints and private integrations.

A common architecture is:

```text
Internet
   |
   v
API Gateway
   |
   v
VPC Link / private integration
   |
   v
ALB
   |
   v
ECS / EC2
```

This allows API Gateway to provide the public API layer while the backend remains inside a VPC.

For HTTP APIs, API Gateway supports integrations with routable HTTP endpoints, including private integrations. [HTTP APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)

---

# 36. Private REST API

A private REST API is accessible from VPCs using an API Gateway interface VPC endpoint.

Architecture:

```text
EC2
 |
 | private network
 v
VPC Interface Endpoint
 |
 v
Private API Gateway
 |
 v
Backend
```

Basic implementation:

1. Create a VPC.
2. Create an interface VPC endpoint for API Gateway.
3. Enable private DNS as appropriate.
4. Create a private REST API.
5. Attach a resource policy.
6. Create resources and methods.
7. Deploy the API.
8. Test from an EC2 instance inside the VPC.

AWS requires a VPC endpoint before creating a private API and recommends appropriate VPC DNS configuration. [Create a private API](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-private-api-create.html)

---

# 37. API Gateway Security

A secure API architecture may use:

```text
Client
  |
  v
CloudFront / API Gateway
  |
  +--> AWS WAF
  |
  +--> Authentication / Authorization
  |
  +--> Throttling
  |
  v
Backend
```

Security controls include:

- HTTPS
- IAM authorization
- Cognito
- Lambda authorizers
- JWT authorization for HTTP APIs
- Resource policies
- Private APIs
- VPC endpoints
- AWS WAF
- Throttling
- CloudWatch monitoring

---

# 38. API Gateway vs ALB

| Requirement | API Gateway | ALB |
|---|---|---|
| API management | Strong | Limited |
| Lambda integration | Native | Supported through Lambda target, but different model |
| REST/HTTP API endpoints | Yes | HTTP routing |
| WebSocket | Yes | No equivalent API Gateway WebSocket model |
| Authentication/authorization | Extensive API features | Usually implemented at application/other layers |
| API keys/usage plans | Yes for REST APIs | No equivalent native usage-plan model |
| Request throttling | Native | Different load-balancing controls |
| Path-based routing | Yes | Yes |
| Serverless API | Excellent fit | Possible |
| Load balancing EC2/ECS | Not primary purpose | Excellent fit |
| Private VPC backend | Supported through private integrations | Native |

---

# 39. API Gateway vs Lambda Function URL

| Requirement | API Gateway | Lambda Function URL |
|---|---|---|
| Full API management | Yes | No |
| Usage plans | REST API | No |
| API keys | REST API | No |
| Rich authorization options | Yes | Simpler |
| Throttling | Yes | Different controls |
| Simple Lambda HTTPS endpoint | Yes | Excellent simple option |
| Request transformation | Extensive REST features | Limited |

For SAA-C03 questions requiring API management, authorization, throttling, stages, or multiple backend integrations, API Gateway is usually the relevant service.

---

# 40. API Gateway vs Application Load Balancer

Choose API Gateway when the requirement emphasizes:

- Managed API front door
- Lambda integration
- API lifecycle
- API keys and usage plans
- API-specific throttling
- API authorization
- REST/HTTP/WebSocket API features

Choose ALB when the requirement emphasizes:

- Load balancing EC2
- ECS services
- Container workloads
- Path/host-based routing
- High-volume HTTP application traffic

---

# 41. API Gateway vs CloudFront

CloudFront is a CDN and edge caching/distribution service.

API Gateway is an API management and API execution front door.

They can be used together:

```text
Client
 |
 v
CloudFront
 |
 v
API Gateway
 |
 v
Lambda / Backend
```

---

# 42. API Gateway Monitoring

Monitor API Gateway using:

- Amazon CloudWatch metrics
- CloudWatch Logs
- CloudTrail
- X-Ray where supported/configured
- API Gateway access logs

Useful metrics include request count, latency, integration latency, 4XX errors, and 5XX errors.

---

# 43. Common HTTP Status Codes

| Code | Meaning | Typical API issue |
|---|---|---|
| 200 | Success | Request processed |
| 201 | Created | Resource created |
| 400 | Bad Request | Invalid client input |
| 401 | Unauthorized | Authentication problem |
| 403 | Forbidden | Authorization/policy problem |
| 404 | Not Found | Invalid route/resource |
| 429 | Too Many Requests | Throttling |
| 500 | Internal Server Error | Backend/API failure |
| 502 | Bad Gateway | Integration/backend problem |
| 503 | Service Unavailable | Service unavailable |
| 504 | Gateway Timeout | Backend timeout |

---

# 44. Common Troubleshooting

## 44.1 403 Forbidden

Check:

- IAM authorization
- Lambda authorizer
- Cognito/JWT configuration
- Resource policy
- API key requirements
- VPC endpoint policy for private APIs

## 44.2 404 Not Found

Check:

- Resource path
- HTTP method
- Stage
- Deployment
- Invoke URL

## 44.3 500 Error

Check Lambda logs and API Gateway execution/access logs.

## 44.4 502 Bad Gateway

Check:

- Lambda response format
- Integration configuration
- Backend endpoint
- Lambda permissions

## 44.5 429 Too Many Requests

Check throttling settings and usage-plan limits. API Gateway documents throttling as best-effort. [Throttling](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-request-throttling.html)

---

# 45. Deployment Model

For REST APIs:

```text
API configuration
      |
      v
Deployment
      |
      v
Stage
      |
      v
Client invocation
```

If you change a resource, method, integration, authorizer, or resource policy, redeploy the API for the change to be reflected in the deployed stage. [Deploy REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-deploy-api.html)

---

# 46. Stage Strategy

A typical architecture is:

```text
API
 |
 +-- dev
 |
 +-- test
 |
 +-- staging
 |
 +-- prod
```

Each stage can represent a deployed version/lifecycle state.

Use separate AWS accounts for stronger environment isolation when required:

```text
Development Account
        |
        v
Test Account
        |
        v
Production Account
```

---

# 47. SAA-C03 Architecture Decision Table

| Scenario | Appropriate architecture |
|---|---|
| Lambda-based public API | API Gateway + Lambda |
| Simple low-cost API | HTTP API |
| Feature-rich REST API | REST API |
| Real-time bidirectional communication | WebSocket API |
| API only accessible inside VPC | Private REST API / appropriate private integration |
| API authentication using AWS IAM | API Gateway IAM authorization |
| User authentication using Cognito | API Gateway + Cognito/JWT where supported |
| Custom token validation | Lambda authorizer |
| Client usage metering | API key + usage plan |
| Protect API from excessive requests | API Gateway throttling + WAF where appropriate |
| Container backend behind load balancer | API Gateway + private integration or ALB directly depending on requirements |
| Static website | S3 + CloudFront, not API Gateway |
| Load balance EC2 instances | ALB |
| Cache API responses | REST API caching where applicable or CloudFront depending on architecture |

---

# 48. SAA-C03 Exam Points

## Point 1

API Gateway is an API front door, not a general-purpose load balancer.

## Point 2

Lambda + API Gateway is a standard serverless architecture.

## Point 3

REST API has more features than HTTP API.

## Point 4

HTTP APIs are designed with a smaller feature set and lower price.

## Point 5

A REST API deployment must be associated with a stage before invocation.

## Point 6

API keys are primarily for usage plans, quotas, and throttling. Do not treat them as the main authentication mechanism.

## Point 7

A private REST API is accessed through an API Gateway VPC endpoint.

## Point 8

API Gateway throttling can return HTTP 429.

## Point 9

Lambda proxy integration is simpler because API Gateway passes request information to Lambda and Lambda produces the response.

## Point 10

For global API architectures, CloudFront and API Gateway can be combined when the requirements call for edge distribution/caching plus API management.

---

# 49. Practical Architecture Example

```text
                         Users
                           |
                           | HTTPS
                           v
                     CloudFront
                           |
                           v
                     API Gateway
                           |
                +----------+----------+
                |                     |
          Authorization           Throttling
                |                     |
                +----------+----------+
                           |
                           v
                        Lambda
                           |
             +-------------+-------------+
             |                           |
             v                           v
         DynamoDB                       S3
```

This architecture is suitable for a serverless application where API Gateway provides the managed API front door, Lambda provides compute, DynamoDB provides NoSQL storage, and S3 provides object storage.

---

# 50. Console vs CLI vs Terraform

| Area | Management Console | AWS CLI | Terraform |
|---|---|---|---|
| Initial learning | Easiest | Moderate | Moderate/high |
| Repeatability | Low | High | Very high |
| Version control | No | Scripts | Yes |
| CI/CD | Limited | Excellent | Excellent |
| Infrastructure drift control | Low | Low unless scripted | Stronger IaC workflow |
| Interactive troubleshooting | Excellent | Excellent | Limited |
| Production infrastructure | Possible | Common | Excellent |
| API lifecycle automation | Moderate | Strong | Strong |

---

# 51. Cleanup - Console

Delete resources in reverse order:

1. API Gateway deployment/stage if necessary.
2. API Gateway API.
3. Lambda function.
4. CloudWatch log groups if created specifically for the lab.
5. Any IAM role created only for the lab.

---

# 52. Cleanup - CLI

Delete the API:

```bash
aws apigateway delete-rest-api \
  --rest-api-id $API_ID \
  --region $AWS_REGION
```

Delete the Lambda function:

```bash
aws lambda delete-function \
  --function-name saa-api-gateway-demo \
  --region $AWS_REGION
```

---

# 53. Cleanup - Terraform

```bash
terraform destroy
```

Review the plan carefully before confirming.

---

# 54. Official AWS Documentation

## Amazon API Gateway

https://docs.aws.amazon.com/apigateway/

## API Gateway Concepts

https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-basic-concept.html

## REST APIs

https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-rest-api.html

## Develop REST APIs

https://docs.aws.amazon.com/apigateway/latest/developerguide/rest-api-develop.html

## HTTP APIs

https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html

## Lambda Proxy Integration

https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-create-api-as-simple-proxy-for-lambda.html

## Lambda Integrations

https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-integrations.html

## Deploy REST APIs

https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-deploy-api.html

## API Gateway Throttling

https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-request-throttling.html

## Usage Plans and API Keys

https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-usage-plans.html

## Resource Policies

https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-resource-policies.html

## Lambda Authorizers

https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html

## Private APIs

https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-private-api-create.html

## API Gateway Tutorials

https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-tutorials.html

## AWS CLI API Gateway Reference

https://docs.aws.amazon.com/cli/latest/reference/apigateway/

## AWS CLI API Gateway Examples

https://docs.aws.amazon.com/cli/latest/userguide/cli_api-gateway_code_examples.html

---

# 55. Terraform Documentation

## REST API

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api

## Resource

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource

## Method

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method

## Integration

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration

## Deployment

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment

## Stage

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage

---

# 56. Final SAA-C03 Mental Model

Remember API Gateway as:

```text
                   API Gateway
                       |
        +--------------+--------------+
        |              |              |
     Security      Throttling     API Lifecycle
        |              |              |
        +--------------+--------------+
                       |
                Backend Integration
                       |
          +------------+------------+
          |            |            |
       Lambda         HTTP       AWS Service
```

For exam questions, identify the requirement first:

```text
Serverless API              -> API Gateway + Lambda
Simple/low-cost API        -> HTTP API
Feature-rich REST API      -> REST API
Real-time bidirectional    -> WebSocket API
Private internal API      -> Private API / private integration
Client quotas             -> Usage plan + API key
Authentication            -> IAM / Cognito / JWT / Lambda authorizer
Excessive requests        -> Throttling + WAF where appropriate
Container load balancing  -> ALB
Global API distribution   -> CloudFront + API Gateway where appropriate
```

The central SAA-C03 concept is that **API Gateway provides a managed API front door and integrates clients with backend services while providing API-specific security, lifecycle, monitoring, and traffic-management capabilities.**
