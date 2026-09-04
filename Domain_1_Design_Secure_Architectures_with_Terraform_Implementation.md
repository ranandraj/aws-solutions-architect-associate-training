# AWS Certified Solutions Architect -- Associate (SAA-C03)

# Domain 1: Design Secure Architectures

## Complete Student Training Material: Console + AWS CLI + Terraform

**Version:** September 2026\
**Audience:** Students preparing for AWS Certified Solutions Architect
-- Associate (SAA-C03)\
**Approach:** Learn the concept, implement it manually, verify it,
implement it again with Terraform, test the result, and clean up.

------------------------------------------------------------------------

# 1. Domain 1 Overview

AWS SAA-C03 Domain 1 is **Design Secure Architectures**.

The current AWS exam guide divides Domain 1 into three tasks:

1.  **Task 1.1: Design secure access to AWS resources**
2.  **Task 1.2: Design secure workloads and applications**
3.  **Task 1.3: Determine appropriate data security controls**

Domain 1 represents **30% of the scored exam content**.

Official exam guide:

https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03/solutions-architect-associate-03-domain1.html

The goal is not to memorize service names. You should be able to read a
scenario and select an architecture that provides the required security
with the correct AWS service.

------------------------------------------------------------------------

# 2. Learning Objectives

After completing this material, you should be able to:

-   Explain the AWS shared responsibility model.
-   Secure the AWS root user.
-   Create IAM users, groups, roles, and policies.
-   Apply least-privilege permissions.
-   Explain policy evaluation.
-   Use MFA.
-   Explain IAM Identity Center and federation.
-   Explain AWS Organizations and Service Control Policies.
-   Design cross-account access.
-   Use IAM Access Analyzer.
-   Distinguish identity policies from resource policies.
-   Explain AWS STS and temporary credentials.
-   Design VPC security using security groups and network ACLs.
-   Explain public and private subnets.
-   Use route tables correctly.
-   Explain Internet Gateway and NAT Gateway.
-   Use VPC endpoints.
-   Secure applications with Secrets Manager and Parameter Store.
-   Use Amazon Cognito for application identities.
-   Explain AWS WAF and AWS Shield.
-   Explain GuardDuty and Security Hub.
-   Enable CloudTrail and understand audit logging.
-   Use CloudWatch for monitoring and alarms.
-   Encrypt data with AWS KMS.
-   Understand customer-managed, AWS-managed, and AWS-owned keys.
-   Use TLS and AWS Certificate Manager.
-   Apply S3 public-access protection, encryption, versioning, and
    lifecycle rules.
-   Understand backup, replication, retention, and data classification.
-   Implement the same security architecture manually and with
    Terraform.
-   Verify and destroy Terraform-managed infrastructure safely.

------------------------------------------------------------------------

# 3. Prerequisites

## 3.1 AWS account

Use a dedicated learning account or sandbox account if available.

Do not use the AWS root user for routine administration.

You should have:

-   An AWS account
-   Permission to create IAM, VPC, S3, KMS, CloudTrail, CloudWatch,
    GuardDuty and related resources
-   A billing alert or budget
-   MFA enabled on the root user
-   AWS CLI
-   Terraform
-   Git
-   VS Code or another code editor

Some labs can create billable resources.

Potentially billable resources include:

-   NAT Gateway
-   Application Load Balancer
-   EC2 instances
-   RDS
-   CloudTrail data events
-   KMS customer-managed keys
-   WAF
-   Shield Advanced
-   GuardDuty/Security Hub usage depending on features and volume

Always clean up after a lab.

------------------------------------------------------------------------

# 4. AWS Region

Choose one region for the lab.

Example:

``` bash
aws configure get region
```

If no region is configured:

``` bash
aws configure
```

Example:

``` text
AWS Access Key ID [None]: <your-access-key>
AWS Secret Access Key [None]: <your-secret-key>
Default region name [None]: ap-south-1
Default output format [None]: json
```

For real environments, prefer IAM Identity Center or another federation
mechanism rather than long-lived IAM user access keys.

Verify the identity:

``` bash
aws sts get-caller-identity
```

Expected output:

``` json
{
    "UserId": "AIDAXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/lab-user"
}
```

Your values will be different.

------------------------------------------------------------------------

# 5. Terraform Installation and Basic Workflow

Verify Terraform:

``` bash
terraform version
```

Expected output:

``` text
Terraform v1.x.x
on windows_amd64
```

The exact version will vary.

Official Terraform documentation:

https://developer.hashicorp.com/terraform/docs

AWS provider:

https://registry.terraform.io/providers/hashicorp/aws/latest/docs

## 5.1 Standard Terraform workflow

For every lab, understand this sequence:

``` bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform state list
terraform destroy
```

### `terraform init`

Downloads providers and initializes the working directory.

### `terraform fmt`

Formats Terraform files.

### `terraform validate`

Checks Terraform syntax and configuration consistency.

### `terraform plan`

Shows what Terraform intends to create, modify, or destroy.

### `terraform apply`

Creates or changes infrastructure.

### `terraform state list`

Shows resources currently tracked by Terraform.

### `terraform destroy`

Removes resources managed by the configuration.

------------------------------------------------------------------------

# 6. Recommended Terraform Directory

Create:

``` text
aws-saa-domain1/
├── 01-iam/
├── 02-organizations/
├── 03-access-analyzer/
├── 04-kms/
├── 05-secrets/
├── 06-parameter-store/
├── 07-s3-security/
├── 08-vpc-security/
├── 09-vpc-endpoint/
├── 10-cognito/
├── 11-guardduty/
├── 12-securityhub/
├── 13-waf/
├── 14-cloudtrail/
├── 15-cloudwatch/
├── 16-certificate-manager/
└── 17-capstone/
```

Keep separate labs separate. This makes cleanup safer.

------------------------------------------------------------------------

# PART I -- TASK 1.1

# DESIGN SECURE ACCESS TO AWS RESOURCES

------------------------------------------------------------------------

# 7. AWS Shared Responsibility Model

## 7.1 Concept

AWS security is divided between AWS and the customer.

AWS is responsible for security **of** the cloud.

This includes the underlying infrastructure such as:

-   Physical facilities
-   Hardware
-   Networking infrastructure
-   AWS-managed virtualization infrastructure
-   Physical security

The customer is responsible for security **in** the cloud.

Depending on the service, this can include:

-   IAM configuration
-   Data
-   Operating-system configuration
-   Application code
-   Security groups
-   Network ACLs
-   Encryption choices
-   Resource policies
-   Access permissions
-   Patch management for customer-managed operating systems

The exact responsibility changes depending on the service.

For example:

### EC2

You are responsible for:

-   Guest operating system
-   Patches
-   Installed software
-   Application
-   Security group configuration
-   IAM role configuration
-   Data

AWS manages:

-   Physical host
-   Physical network
-   Hypervisor infrastructure

### S3

AWS manages the underlying infrastructure.

You are responsible for:

-   Bucket policies
-   IAM permissions
-   Object permissions
-   Encryption configuration
-   Data classification
-   Public-access settings
-   Lifecycle policies

## 7.2 Manual exercise

Open the AWS Shared Responsibility Model documentation:

https://aws.amazon.com/compliance/shared-responsibility-model/

Create a table:

``` text
Component                 Customer or AWS
------------------------------------------------
Physical data center      AWS
EC2 guest OS              Customer
IAM policies              Customer
S3 bucket policy          Customer
Physical servers          AWS
Application code          Customer
S3 infrastructure        AWS
```

## 7.3 Exam point

If a question says an application is running on EC2 and a vulnerability
exists in the operating system, the customer is generally responsible
for patching it.

If the question concerns physical AWS infrastructure, AWS is
responsible.

------------------------------------------------------------------------

# 8. AWS Root User Security

## 8.1 Root user

The root user has extensive privileges for an AWS account.

Use it only for tasks that specifically require root-user credentials.

Do not create daily administration workflows around root credentials.

## 8.2 Manual setup

1.  Sign in to the AWS Management Console as the root user.
2.  Open account/security credentials.
3.  Locate MFA.
4.  Enable MFA.
5.  Prefer phishing-resistant MFA such as passkeys/security keys where
    practical.
6.  Store recovery information securely.
7.  Sign out.
8.  Use an administrative identity for normal work.

AWS MFA documentation:

https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html

## 8.3 Verification

Sign out and sign in again.

Confirm that MFA is requested.

## 8.4 Important distinction

Root-user MFA cannot be replaced with an IAM policy.

Root-user security is an account-level security control.

Terraform should not be used as a substitute for root credential
management.

------------------------------------------------------------------------

# 9. IAM Users

## 9.1 Concept

An IAM user represents a long-lived AWS identity inside an account.

A user can have:

-   Password for console access
-   Access keys for API/CLI access
-   Permissions through policies

For human workforce access, AWS recommends modern federation and IAM
Identity Center for many environments instead of creating large numbers
of IAM users.

## 9.2 Manual Console Lab

Create a test user.

1.  Open IAM.
2.  Select Users.
3.  Select Create user.
4.  Enter:

``` text
Username: saa-lab-user
```

5.  Choose the required credential option for your lab.
6.  Do not give unnecessary administrator permissions.
7.  Complete the user creation.

## 9.3 CLI

Create user:

``` bash
aws iam create-user --user-name saa-lab-user
```

Expected output:

``` json
{
    "User": {
        "Path": "/",
        "UserName": "saa-lab-user",
        "UserId": "AIDA...",
        "Arn": "arn:aws:iam::123456789012:user/saa-lab-user",
        "CreateDate": "2026-09-03T..."
    }
}
```

Verify:

``` bash
aws iam get-user --user-name saa-lab-user
```

## 9.4 Terraform

`main.tf`:

``` hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

resource "aws_iam_user" "lab" {
  name = "saa-lab-user"

  tags = {
    Purpose = "SAA-Domain1-Lab"
  }
}
```

Run:

``` bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Expected result:

``` text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Check:

``` bash
terraform state list
```

Expected:

``` text
aws_iam_user.lab
```

Destroy:

``` bash
terraform destroy
```

## 9.5 Exam point

Do not select IAM users when a scenario is clearly asking for temporary
application access.

For EC2 applications, prefer an IAM role attached to the instance.

------------------------------------------------------------------------

# 10. IAM Groups

## 10.1 Concept

An IAM group is a collection of IAM users.

Groups make permission management easier.

Example:

``` text
Developers
    ├── Alice
    ├── Bob
    └── Charlie
```

Attach a common policy to the group instead of repeating it for every
user.

## 10.2 Manual

1.  IAM → User groups.
2.  Create group:

``` text
saa-developers
```

3.  Add a test user.
4.  Attach a deliberately limited policy.

## 10.3 CLI

``` bash
aws iam create-group --group-name saa-developers
```

Expected:

``` json
{
    "Group": {
        "Path": "/",
        "GroupName": "saa-developers",
        "GroupId": "AGPA...",
        "Arn": "arn:aws:iam::123456789012:group/saa-developers",
        "CreateDate": "2026-09-03T..."
    }
}
```

Add user:

``` bash
aws iam add-user-to-group \
  --group-name saa-developers \
  --user-name saa-lab-user
```

## 10.4 Terraform

``` hcl
resource "aws_iam_group" "developers" {
  name = "saa-developers"
}

resource "aws_iam_user_group_membership" "membership" {
  user = aws_iam_user.lab.name

  groups = [
    aws_iam_group.developers.name
  ]
}
```

Verify:

``` bash
terraform plan
terraform apply
terraform state list
```

## 10.5 Exam point

Groups are for users.

Applications should normally use roles rather than IAM users.

------------------------------------------------------------------------

# 11. IAM Policies

## 11.1 Policy structure

An IAM policy is JSON.

Example:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::example-bucket/*"
    }
  ]
}
```

Important fields:

-   `Version`
-   `Statement`
-   `Effect`
-   `Action`
-   `Resource`
-   `Condition`
-   `Principal` in resource/trust policies where applicable

## 11.2 Least privilege

Least privilege means granting only the permissions required to perform
the task.

Bad:

``` text
Action: "*"
Resource: "*"
```

Better:

``` text
Action:
  s3:GetObject

Resource:
  arn:aws:s3:::training-bucket/reports/*
```

## 11.3 Manual exercise

Create a customer-managed IAM policy allowing only:

``` text
s3:ListBucket
```

on one test bucket.

Then attach it to the test group.

## 11.4 CLI

Create policy document:

``` bash
aws iam create-policy \
  --policy-name SAAListBucketPolicy \
  --policy-document file://policy.json
```

Expected:

``` json
{
  "Policy": {
    "PolicyName": "SAAListBucketPolicy",
    "PolicyArn": "arn:aws:iam::123456789012:policy/SAAListBucketPolicy"
  }
}
```

## 11.5 Terraform

``` hcl
resource "aws_iam_policy" "list_bucket" {
  name = "SAAListBucketPolicy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::example-training-bucket"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "developers" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.list_bucket.arn
}
```

## 11.6 Policy evaluation

A simplified model:

1.  Start with implicit deny.
2.  Evaluate applicable policies.
3.  An explicit deny overrides an allow.
4.  An allow grants access if no applicable explicit deny blocks it.

This is one of the most important IAM concepts for SAA questions.

------------------------------------------------------------------------

# 12. IAM Roles

## 12.1 Concept

An IAM role is an identity that can be assumed.

Roles provide temporary credentials.

Common uses:

-   EC2 accessing S3
-   Lambda accessing DynamoDB
-   ECS tasks accessing AWS services
-   Cross-account access
-   Federated workforce access

## 12.2 Trust policy

A role has a trust policy.

Example:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

The trust policy answers:

> Who is allowed to assume this role?

The permissions policy answers:

> What can the role do after it is assumed?

Do not confuse these two.

## 12.3 Manual

1.  IAM → Roles.
2.  Create role.
3.  Select AWS service.
4.  Select EC2.
5.  Add a limited S3 policy.
6.  Name:

``` text
SAA-EC2-S3-Role
```

## 12.4 CLI

Create trust policy:

``` bash
aws iam create-role \
  --role-name SAA-EC2-S3-Role \
  --assume-role-policy-document file://trust-policy.json
```

Expected:

``` json
{
  "Role": {
    "RoleName": "SAA-EC2-S3-Role",
    "Arn": "arn:aws:iam::123456789012:role/SAA-EC2-S3-Role"
  }
}
```

## 12.5 Terraform

``` hcl
resource "aws_iam_role" "ec2_s3" {
  name = "SAA-EC2-S3-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_read" {
  role = aws_iam_role.ec2_s3.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::example-training-bucket/*"
      }
    ]
  })
}
```

## 12.6 Exam point

When an EC2 instance needs to access S3:

**Correct design:** IAM role attached to the EC2 instance.

**Poor design:** Store IAM access keys inside application code.

------------------------------------------------------------------------

# 13. IAM Instance Profiles

For EC2, a role is made available to the instance through an instance
profile.

Terraform:

``` hcl
resource "aws_iam_instance_profile" "ec2" {
  name = "SAA-EC2-S3-Profile"
  role = aws_iam_role.ec2_s3.name
}
```

When launching EC2, associate the instance profile.

The application can obtain temporary credentials through the EC2
metadata service.

------------------------------------------------------------------------

# 14. MFA

## 14.1 Concept

MFA requires more than one authentication factor.

AWS supports multiple MFA approaches.

AWS recommends phishing-resistant methods such as passkeys/security keys
where practical.

## 14.2 Manual IAM-user exercise

1.  IAM → Users.
2.  Select the lab user.
3.  Security credentials.
4.  Assign MFA device.
5.  Use an authenticator or supported security key.
6.  Complete enrollment.
7.  Test sign-in.

## 14.3 CLI check

``` bash
aws iam list-mfa-devices --user-name saa-lab-user
```

Expected:

``` json
{
  "MFADevices": [
    {
      "UserName": "saa-lab-user",
      "SerialNumber": "arn:aws:iam::123456789012:mfa/saa-lab-user"
    }
  ]
}
```

## 14.4 Important Terraform limitation

Terraform can manage many IAM resources, but MFA enrollment involves
authentication-device secrets and interactive registration. Do not treat
Terraform as the normal tool for registering a human's physical/passkey
MFA device.

------------------------------------------------------------------------

# 15. IAM Identity Center

## 15.1 Concept

IAM Identity Center provides centralized workforce access to AWS
accounts and applications.

It is particularly useful for:

-   Multiple AWS accounts
-   Workforce users
-   Permission sets
-   Centralized sign-in
-   Federation with external identity providers

Typical architecture:

``` text
User
  |
  v
IAM Identity Center
  |
  +---- AWS Account A
  |
  +---- AWS Account B
  |
  +---- AWS Account C
```

## 15.2 Manual setup

1.  Open IAM Identity Center.
2.  Enable the service.
3.  Use the organization-integrated setup when appropriate.
4.  Create or connect an identity source.
5.  Create a test user.
6.  Create a permission set.
7.  Assign the user/group to an AWS account.
8.  Sign in through the AWS access portal.
9.  Verify the account and permission set.

AWS documentation:

https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html

## 15.3 Permission set

A permission set is a reusable definition of permissions assigned to
users/groups in AWS accounts.

Examples:

``` text
ReadOnly
Developer
Operations
SecurityAudit
Administrator
```

Use the least privilege appropriate for the job.

## 15.4 Terraform

Identity Center infrastructure can be managed with Terraform, but setup
depends on the existing IAM Identity Center identity store and AWS
Organization.

Typical resources include:

``` hcl
resource "aws_ssoadmin_permission_set" "readonly" {
  name         = "SAAReadOnly"
  instance_arn = var.sso_instance_arn
}
```

Account assignment examples use:

-   `aws_ssoadmin_account_assignment`
-   `aws_ssoadmin_permission_set`
-   IAM Identity Store resources

Do not hard-code identity-store IDs without first discovering the values
in your environment.

## 15.5 Exam point

For centralized workforce access across multiple AWS accounts, IAM
Identity Center is generally a stronger design than creating separate
IAM users in every account.

------------------------------------------------------------------------

# 16. AWS Organizations

## 16.1 Concept

AWS Organizations allows centralized management of multiple AWS
accounts.

Example:

``` text
Organization
|
+-- Security Account
+-- Log Archive Account
+-- Production Account
+-- Development Account
+-- Testing Account
```

Use Organizational Units (OUs) to group accounts.

Example:

``` text
Root
|
+-- Production OU
|    +-- Prod Account
|
+-- NonProduction OU
     +-- Dev Account
     +-- Test Account
```

## 16.2 Manual

1.  Open AWS Organizations.
2.  Create an organization.
3.  Add or create accounts.
4.  Create OUs.
5.  Move member accounts into appropriate OUs.
6.  Review account structure.

Do not experiment with production organizations without understanding
account and billing implications.

AWS Organizations:

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html

------------------------------------------------------------------------

# 17. Service Control Policies (SCPs)

## 17.1 Concept

An SCP sets the maximum available permissions for accounts in an AWS
Organization.

Important:

**SCPs do not grant permissions.**

They define permission boundaries at the organization/account/OU level.

Example:

``` text
IAM policy:
  Allows action

SCP:
  Does not deny action

Result:
  Action can be allowed
```

If SCP explicitly denies the action:

``` text
IAM policy:
  Allows action

SCP:
  Denies action

Result:
  Action is denied
```

## 17.2 Manual exercise

Create a test SCP that denies a carefully selected action in a test
account.

Example concept:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "ec2:TerminateInstances",
      "Resource": "*"
    }
  ]
}
```

Do not attach this to an account where it could interfere with real
operations.

## 17.3 Terraform

``` hcl
resource "aws_organizations_policy" "deny_terminate" {
  name        = "DenyEC2Terminate"
  description = "Lab SCP preventing EC2 termination"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect   = "Deny"
        Action   = "ec2:TerminateInstances"
        Resource = "*"
      }
    ]
  })
}
```

Attachment:

``` hcl
resource "aws_organizations_policy_attachment" "lab" {
  policy_id = aws_organizations_policy.deny_terminate.id
  target_id = var.target_account_id
}
```

## 17.4 Exam point

SCP = maximum permissions.

IAM policy = grants permissions.

Permission boundary = maximum permissions for an IAM principal.

Explicit deny overrides allow.

------------------------------------------------------------------------

# 18. AWS STS and Temporary Credentials

## 18.1 Concept

AWS Security Token Service provides temporary security credentials.

Temporary credentials contain:

-   Access key ID
-   Secret access key
-   Session token
-   Expiration

Use cases:

-   IAM roles
-   Cross-account access
-   Federation
-   Temporary elevated access

## 18.2 CLI

Get current identity:

``` bash
aws sts get-caller-identity
```

Expected:

``` json
{
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/example"
}
```

Assuming a role:

``` bash
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/SAA-CrossAccountRole \
  --role-session-name saa-lab-session
```

Expected structure:

``` json
{
  "Credentials": {
    "AccessKeyId": "ASIA...",
    "SecretAccessKey": "...",
    "SessionToken": "...",
    "Expiration": "2026-09-03T..."
  },
  "AssumedRoleUser": {
    "AssumedRoleId": "...",
    "Arn": "arn:aws:sts::123456789012:assumed-role/SAA-CrossAccountRole/saa-lab-session"
  }
}
```

Never paste temporary credentials into source code or Git repositories.

------------------------------------------------------------------------

# 19. Cross-Account Access

## 19.1 Concept

Account A can allow a principal from Account B to assume a role.

Architecture:

``` text
Account B user
     |
     | sts:AssumeRole
     v
Account A role
     |
     v
AWS resources in Account A
```

The role trust policy controls who can assume it.

The role permissions policy controls what the role can do.

## 19.2 Exam pattern

If a company has many AWS accounts and wants centralized access:

-   Use AWS Organizations.
-   Use IAM Identity Center.
-   Use permission sets.

If an application in Account A must access a resource in Account B:

-   Consider a cross-account IAM role.
-   Use temporary credentials.
-   Avoid long-lived access keys.

------------------------------------------------------------------------

# 20. IAM Resource Policies

Some AWS resources support resource-based policies.

Examples:

-   S3 bucket policies
-   SQS queue policies
-   SNS topic policies
-   KMS key policies
-   Secrets Manager resource policies

Resource policy example:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/ExampleRole"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::example-bucket/*"
    }
  ]
}
```

Exam questions often ask whether permissions belong in an identity
policy or resource policy.

------------------------------------------------------------------------

# 21. IAM Access Analyzer

## 21.1 Concept

IAM Access Analyzer helps identify resources that are accessible from
outside a trusted zone.

It can help identify unintended external access.

It can also validate IAM policies and assist with policy generation from
CloudTrail activity.

## 21.2 Manual

1.  Open IAM.
2.  Open Access Analyzer.
3.  Create an analyzer.
4.  Choose the appropriate zone of trust.
5.  Review findings.
6.  Investigate public or cross-account access.

AWS documentation:

https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html

## 21.3 CLI

List analyzers:

``` bash
aws accessanalyzer list-analyzers
```

Expected:

``` json
{
  "analyzers": [
    {
      "arn": "arn:aws:access-analyzer:ap-south-1:123456789012:analyzer/example",
      "name": "example",
      "status": "ACTIVE",
      "type": "ACCOUNT"
    }
  ]
}
```

## 21.4 Terraform

``` hcl
resource "aws_accessanalyzer_analyzer" "account" {
  analyzer_name = "saa-account-analyzer"
  type          = "ACCOUNT"
}
```

Run:

``` bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Verify:

``` bash
aws accessanalyzer list-analyzers
```

Destroy:

``` bash
terraform destroy
```

## 21.5 Exam point

Access Analyzer is useful for discovering unintended external access.

------------------------------------------------------------------------

# PART II -- TASK 1.2

# DESIGN SECURE WORKLOADS AND APPLICATIONS

------------------------------------------------------------------------

# 22. VPC Security Fundamentals

A VPC provides an isolated networking environment.

Important components:

``` text
VPC
|
+-- Subnets
|    |
|    +-- Public subnet
|    +-- Private subnet
|
+-- Route tables
|
+-- Internet Gateway
|
+-- NAT Gateway
|
+-- Security Groups
|
+-- Network ACLs
|
+-- VPC Endpoints
```

AWS VPC security documentation:

https://docs.aws.amazon.com/vpc/latest/userguide/security.html

------------------------------------------------------------------------

# 23. CIDR and Subnets

Example VPC:

``` text
10.0.0.0/16
```

Subnets:

``` text
10.0.1.0/24   Public subnet
10.0.2.0/24   Public subnet
10.0.11.0/24  Private application subnet
10.0.12.0/24  Private application subnet
10.0.21.0/24  Private database subnet
10.0.22.0/24  Private database subnet
```

A smaller CIDR prefix number means a larger address range.

------------------------------------------------------------------------

# 24. Public and Private Subnets

A subnet is considered public when its route table has a route to an
Internet Gateway and resources have the required public addressing.

Typical public subnet:

``` text
0.0.0.0/0 -> Internet Gateway
```

Typical private application subnet:

``` text
0.0.0.0/0 -> NAT Gateway
```

Typical private database subnet:

``` text
No direct Internet route
```

Do not decide whether a subnet is public based only on its name.

The routing configuration matters.

------------------------------------------------------------------------

# 25. Internet Gateway

An Internet Gateway provides a path between a VPC and the internet.

Architecture:

``` text
Internet
   |
Internet Gateway
   |
VPC Route Table
   |
Public Subnet
```

An Internet Gateway does not automatically make every subnet public.

The subnet route table must contain an appropriate route.

------------------------------------------------------------------------

# 26. NAT Gateway

NAT Gateway allows resources in a private subnet to initiate outbound
connections to the internet without allowing unsolicited inbound
internet connections to those private resources.

Example:

``` text
Private EC2
    |
Private subnet route table
    |
NAT Gateway
    |
Internet Gateway
    |
Internet
```

NAT Gateway is not the same as an Internet Gateway.

Important cost note: NAT Gateway can incur hourly and data-processing
charges.

For inexpensive labs, destroy it immediately after testing.

------------------------------------------------------------------------

# 27. Security Groups

## 27.1 Characteristics

Security groups:

-   Operate at the resource/instance network interface level.
-   Are stateful.
-   Support allow rules.
-   Do not use explicit deny rules.

Example web security group:

``` text
Inbound:
TCP 443 from 0.0.0.0/0
```

Application security group:

``` text
Inbound:
TCP 8080 from WebSecurityGroup
```

Database security group:

``` text
Inbound:
TCP 5432 from AppSecurityGroup
```

This is more secure than:

``` text
TCP 5432 from 0.0.0.0/0
```

## 27.2 Manual

1.  VPC console.
2.  Security Groups.
3.  Create:

``` text
web-sg
app-sg
db-sg
```

Configure:

``` text
web-sg:
  443 from Internet

app-sg:
  8080 from web-sg

db-sg:
  5432 from app-sg
```

## 27.3 CLI

Create a group:

``` bash
aws ec2 create-security-group \
  --group-name saa-web-sg \
  --description "SAA web security group" \
  --vpc-id vpc-xxxxxxxx
```

Expected:

``` json
{
  "GroupId": "sg-xxxxxxxx"
}
```

Add HTTPS:

``` bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxx \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```

## 27.4 Terraform

``` hcl
resource "aws_security_group" "web" {
  name        = "saa-web-sg"
  description = "Web tier security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "saa-web-sg"
  }
}
```

## 27.5 Exam point

Security groups are **stateful**.

If inbound traffic is allowed, the return traffic is automatically
allowed.

------------------------------------------------------------------------

# 28. Network ACLs

## 28.1 Characteristics

Network ACLs:

-   Operate at subnet level.
-   Are stateless.
-   Support allow and deny.
-   Evaluate rules in ascending rule-number order.

AWS documentation:

https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html

Example:

``` text
Rule 100: ALLOW TCP 443
Rule 200: DENY TCP 443
```

Rule 100 matches first.

## 28.2 Manual

1.  VPC → Network ACLs.
2.  Create a custom ACL.
3.  Add inbound rules.
4.  Add outbound rules.
5.  Associate with a subnet.
6.  Test carefully.

Custom NACLs begin with restrictive rules, so make sure required return
traffic and ephemeral ports are accounted for.

## 28.3 CLI

Create:

``` bash
aws ec2 create-network-acl \
  --vpc-id vpc-xxxxxxxx
```

Expected:

``` json
{
  "NetworkAcl": {
    "NetworkAclId": "acl-xxxxxxxx",
    "VpcId": "vpc-xxxxxxxx"
  }
}
```

## 28.4 Terraform

``` hcl
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "saa-private-nacl"
  }
}

resource "aws_network_acl_rule" "https_in" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 443
  to_port        = 443
}
```

## 28.5 Security Group vs NACL

  Feature          Security Group       NACL
  ---------------- -------------------- --------------------------
  Level            Resource/interface   Subnet
  Stateful         Yes                  No
  Allow            Yes                  Yes
  Deny             No                   Yes
  Rule order       Not first-match      Lowest rule number first
  Return traffic   Automatic            Must be allowed

------------------------------------------------------------------------

# 29. Route Tables

A route table determines where network traffic is sent.

Example:

``` text
Destination       Target
0.0.0.0/0         igw-xxxx
10.0.0.0/16       local
```

Private route:

``` text
Destination       Target
0.0.0.0/0         nat-xxxx
10.0.0.0/16       local
```

Database subnet:

``` text
10.0.0.0/16       local
```

The database should not normally have a default route directly to the
internet.

------------------------------------------------------------------------

# 30. Complete VPC Terraform Lab

This lab creates:

-   VPC
-   Two public subnets
-   Two private subnets
-   Internet Gateway
-   Public route table
-   Private route table
-   NAT Gateway
-   Elastic IP
-   Security group

## 30.1 Terraform

``` hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "saa-secure-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "saa-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "saa-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "saa-public-b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "saa-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "saa-private-b"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "saa-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "saa-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "saa-nat"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "saa-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
```

Run:

``` bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Expected:

``` text
Apply complete! Resources: multiple added, 0 changed, 0 destroyed.
```

List resources:

``` bash
terraform state list
```

Destroy after the exercise:

``` bash
terraform destroy
```

Confirm:

``` text
Destroy complete! Resources: multiple destroyed.
```

------------------------------------------------------------------------

# 31. VPC Endpoints

## 31.1 Concept

VPC endpoints allow private connectivity from a VPC to supported AWS
services without requiring internet access through a NAT Gateway for
that traffic.

Two important patterns:

### Gateway endpoints

Commonly used for:

-   S3
-   DynamoDB

### Interface endpoints

Use AWS PrivateLink and provide private network interfaces.

Common examples:

-   Systems Manager
-   Secrets Manager
-   CloudWatch
-   ECR
-   STS

## 31.2 S3 gateway endpoint

Architecture:

``` text
Private EC2
    |
VPC route table
    |
S3 Gateway Endpoint
    |
Amazon S3
```

## 31.3 CLI

``` bash
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxxxxxxx \
  --service-name com.amazonaws.ap-south-1.s3 \
  --vpc-endpoint-type Gateway \
  --route-table-ids rtb-xxxxxxxx
```

Expected:

``` json
{
  "VpcEndpoint": {
    "VpcEndpointId": "vpce-xxxxxxxx",
    "VpcEndpointType": "Gateway",
    "VpcId": "vpc-xxxxxxxx"
  }
}
```

## 31.4 Terraform

``` hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-south-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "saa-s3-endpoint"
  }
}
```

## 31.5 Exam point

If a private EC2 instance needs S3 access and the requirement is to
avoid internet/NAT traffic, consider an S3 gateway endpoint.

------------------------------------------------------------------------

# 32. Application Credentials

Never place secrets directly in:

``` text
Source code
Git repository
AMI
Docker image
EC2 user-data
Plain-text configuration
```

Use:

-   AWS Secrets Manager
-   Systems Manager Parameter Store
-   IAM roles
-   KMS
-   Environment-specific configuration mechanisms

------------------------------------------------------------------------

# 33. AWS Secrets Manager

## 33.1 Concept

Secrets Manager stores sensitive information such as:

-   Database passwords
-   API keys
-   Tokens
-   Application credentials

It supports secret rotation for supported patterns.

AWS documentation:

https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html

## 33.2 Manual

1.  Open Secrets Manager.
2.  Store a new secret.
3.  Choose a secret type.
4.  Enter a test credential.
5.  Name:

``` text
saa/lab/database
```

6.  Save.
7.  Retrieve it from the console.
8.  Delete it after the lab.

## 33.3 CLI

Create:

``` bash
aws secretsmanager create-secret \
  --name saa/lab/database \
  --secret-string '{"username":"labuser","password":"LabOnlyPassword123!"}'
```

Expected:

``` json
{
  "ARN": "arn:aws:secretsmanager:ap-south-1:123456789012:secret:saa/lab/database-...",
  "Name": "saa/lab/database",
  "VersionId": "..."
}
```

Retrieve:

``` bash
aws secretsmanager get-secret-value \
  --secret-id saa/lab/database
```

Do not paste real production secrets into terminal history.

## 33.4 Terraform

``` hcl
resource "aws_secretsmanager_secret" "db" {
  name = "saa/lab/database"

  tags = {
    Purpose = "SAA-Domain1-Lab"
  }
}
```

For a lab-only secret value:

``` hcl
resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = "labuser"
    password = "LabOnlyPassword123!"
  })
}
```

Important:

Terraform state can contain secret values. Do not use literal production
credentials in Terraform source.

For production, use an appropriate secret-generation/injection workflow
and secure Terraform state.

## 33.5 Exam point

Secrets Manager is the stronger choice when you need:

-   Secrets storage
-   Fine-grained access
-   Secret rotation
-   Integration with applications

------------------------------------------------------------------------

# 34. Systems Manager Parameter Store

## 34.1 Concept

Parameter Store stores configuration values.

Examples:

``` text
/app/dev/url
/app/prod/url
/app/prod/database-host
/app/prod/feature-enabled
```

Parameters can be:

-   String
-   StringList
-   SecureString

## 34.2 Manual

1.  Systems Manager → Parameter Store.
2.  Create parameter.
3.  Name:

``` text
/saa/lab/app-url
```

4.  Type:

``` text
String
```

5.  Value:

``` text
https://example.internal
```

For sensitive configuration, use `SecureString`.

## 34.3 CLI

``` bash
aws ssm put-parameter \
  --name /saa/lab/app-url \
  --type String \
  --value "https://example.internal"
```

Expected:

``` json
{
  "Version": 1,
  "Tier": "Standard"
}
```

Read:

``` bash
aws ssm get-parameter \
  --name /saa/lab/app-url
```

## 34.4 Terraform

``` hcl
resource "aws_ssm_parameter" "app_url" {
  name  = "/saa/lab/app-url"
  type  = "String"
  value = "https://example.internal"

  tags = {
    Purpose = "SAA-Domain1-Lab"
  }
}
```

For a secure parameter:

``` hcl
resource "aws_ssm_parameter" "api_key" {
  name   = "/saa/lab/api-key"
  type   = "SecureString"
  value  = "lab-only-secret-value"
}
```

Again, Terraform state can contain sensitive values.

## 34.5 Secrets Manager vs Parameter Store

  Requirement                           Preferred
  ------------------------------------- ------------------------------
  Simple configuration                  Parameter Store
  Secure configuration                  Parameter Store SecureString
  Secret lifecycle/rotation             Secrets Manager
  Database credential management        Secrets Manager
  Application configuration hierarchy   Parameter Store

------------------------------------------------------------------------

# 35. Amazon Cognito

## 35.1 Concept

Amazon Cognito provides identity capabilities for applications.

Important concepts:

### User pool

Handles application user registration and authentication.

### Identity pool

Can provide temporary AWS credentials to authenticated/guest application
users for authorized AWS resources.

Architecture:

``` text
Application
    |
Cognito User Pool
    |
Authentication
    |
Optional Identity Pool
    |
Temporary AWS credentials
```

AWS documentation:

https://docs.aws.amazon.com/cognito/latest/developerguide/what-is-amazon-cognito.html

## 35.2 Manual User Pool Lab

1.  Open Amazon Cognito.
2.  Create User Pool.
3.  Configure sign-in option.
4.  Configure password policy.
5.  Configure MFA according to the lab.
6.  Create the pool.
7.  Create an application client.
8.  Register a test user.
9.  Test authentication.

## 35.3 Terraform

``` hcl
resource "aws_cognito_user_pool" "users" {
  name = "saa-lab-users"

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }

  tags = {
    Purpose = "SAA-Domain1-Lab"
  }
}

resource "aws_cognito_user_pool_client" "app" {
  name         = "saa-lab-client"
  user_pool_id = aws_cognito_user_pool.users.id

  generate_secret = false
}
```

Run:

``` bash
terraform init
terraform validate
terraform plan
terraform apply
```

Verify:

``` bash
terraform state list
```

Destroy:

``` bash
terraform destroy
```

## 35.4 Exam point

Use Cognito when the requirement is application-user authentication
rather than AWS workforce administration.

------------------------------------------------------------------------

# 36. AWS WAF

## 36.1 Concept

AWS WAF helps protect web applications from common web attacks.

It can filter HTTP/HTTPS requests.

Common threats:

-   SQL injection
-   Cross-site scripting
-   IP-based abuse
-   Bot-related patterns
-   Application-layer request patterns

WAF works with supported AWS resources such as:

-   Application Load Balancer
-   Amazon CloudFront
-   API Gateway
-   Cognito user pools and other supported integrations depending on
    current service support

AWS WAF:

https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html

## 36.2 Manual lab

Create a Web ACL.

1.  Open AWS WAF.
2.  Create Web ACL.
3.  Select regional scope for an ALB-based lab.
4.  Add an AWS managed rule group.
5.  Configure default action.
6.  Associate the Web ACL with the target resource.
7.  Review sampled requests and metrics.

## 36.3 Terraform

Basic regional Web ACL:

``` hcl
resource "aws_wafv2_web_acl" "web" {
  name  = "saa-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedCommonRules"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "saaCommonRules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "saaWebACL"
    sampled_requests_enabled   = true
  }
}
```

For an ALB:

``` hcl
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.app.arn
  web_acl_arn  = aws_wafv2_web_acl.web.arn
}
```

The ALB must exist before this association can be created.

## 36.4 Exam point

For SQL injection or malicious HTTP requests, WAF is usually more
appropriate than a security group.

Security groups control network traffic.

WAF understands web request patterns.

------------------------------------------------------------------------

# 37. AWS Shield

## 37.1 Concept

AWS Shield provides DDoS protection.

### Shield Standard

Provides automatic DDoS protection for supported AWS services.

### Shield Advanced

Provides enhanced DDoS protection and additional capabilities.

Shield Advanced is a paid service and should not be enabled casually in
a student account.

AWS Shield:

https://docs.aws.amazon.com/waf/latest/developerguide/ddos-overview.html

## 37.2 Exam comparison

``` text
DDoS protection
    |
    +-- Shield Standard
    +-- Shield Advanced
```

For a requirement specifically mentioning advanced DDoS protection,
consider Shield Advanced.

For HTTP request filtering such as SQL injection:

**WAF**

For DDoS:

**Shield**

------------------------------------------------------------------------

# 38. AWS GuardDuty

## 38.1 Concept

GuardDuty is a threat detection service.

It analyzes supported data sources and produces findings indicating
suspicious activity.

Examples include:

-   Compromised credentials
-   Suspicious API activity
-   Malicious IP communication
-   Some malware-related activity
-   Unusual behavior

AWS documentation:

https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html

## 38.2 Manual

1.  Open GuardDuty.
2.  Enable GuardDuty in the selected region.
3.  Review findings.
4.  Study finding severity and type.
5.  Do not generate malicious activity intentionally outside a
    controlled AWS lab.

## 38.3 CLI

Create detector:

``` bash
aws guardduty create-detector --enable
```

Expected:

``` json
{
  "detectorId": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
```

List:

``` bash
aws guardduty list-detectors
```

## 38.4 Terraform

``` hcl
resource "aws_guardduty_detector" "main" {
  enable = true

  tags = {
    Purpose = "SAA-Domain1-Lab"
  }
}
```

Run:

``` bash
terraform init
terraform validate
terraform plan
terraform apply
```

Expected:

``` text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Destroy:

``` bash
terraform destroy
```

## 38.5 Exam point

GuardDuty detects threats.

It is not a firewall.

It is not an IAM permission service.

It is not a WAF replacement.

------------------------------------------------------------------------

# 39. Amazon Security Hub

## 39.1 Concept

Security Hub provides a centralized security view and can aggregate
security findings from AWS security services and supported integrations.

Think in terms of:

``` text
GuardDuty
Macie
Inspector
Other security findings
       |
       v
Security Hub
       |
       v
Central security view
```

AWS documentation:

https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html

## 39.2 Manual

1.  Open Security Hub.
2.  Enable the service.
3.  Review security standards.
4.  Review findings.
5.  Investigate severity and control status.

## 39.3 Terraform

Security Hub resource names and available standards can change with
provider versions. Use the current AWS provider documentation for the
exact standards subscription required by your environment.

Basic account activation:

``` hcl
resource "aws_securityhub_account" "main" {}
```

Then validate:

``` bash
terraform init
terraform validate
terraform plan
```

Apply:

``` bash
terraform apply
```

## 39.4 Exam point

GuardDuty = threat detection.

Security Hub = centralized security posture/findings view.

------------------------------------------------------------------------

# 40. CloudTrail

## 40.1 Concept

AWS CloudTrail records API activity.

Examples:

``` text
Who made the request?
What API action occurred?
When did it occur?
From which source?
Which AWS resource was involved?
```

CloudTrail is critical for auditing and investigation.

AWS documentation:

https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html

## 40.2 Manual

1.  Open CloudTrail.
2.  Create a trail.
3.  Choose a secure S3 destination.
4.  Configure logging.
5.  Enable management events.
6.  Consider data events only when needed because volume can increase.
7.  Create the trail.
8.  Perform a harmless AWS API action.
9.  Search Event history.

## 40.3 CLI

Create an S3 bucket first, then:

``` bash
aws cloudtrail create-trail \
  --name saa-audit-trail \
  --s3-bucket-name saa-audit-log-bucket
```

Expected:

``` json
{
  "Name": "saa-audit-trail",
  "S3BucketName": "saa-audit-log-bucket",
  "IncludeGlobalServiceEvents": true,
  "IsMultiRegionTrail": false,
  "LogFileValidationEnabled": false
}
```

Start logging:

``` bash
aws cloudtrail start-logging \
  --name saa-audit-trail
```

Check:

``` bash
aws cloudtrail get-trail-status \
  --name saa-audit-trail
```

Expected:

``` json
{
  "IsLogging": true
}
```

## 40.4 Terraform

A secure CloudTrail design needs an S3 bucket plus the appropriate
bucket policy.

Example:

``` hcl
resource "aws_s3_bucket" "trail" {
  bucket_prefix = "saa-cloudtrail-"
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket = aws_s3_bucket.trail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudtrail" "main" {
  name                          = "saa-audit-trail"
  s3_bucket_name                = aws_s3_bucket.trail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
}
```

In a complete production implementation, add the required CloudTrail S3
bucket policy and encryption configuration according to current AWS
documentation.

## 40.5 Exam point

CloudTrail answers:

> Who did what, when, and through which AWS API?

CloudWatch is primarily for metrics, logs, dashboards, and alarms.

------------------------------------------------------------------------

# 41. CloudWatch

## 41.1 Concept

CloudWatch provides:

-   Metrics
-   Logs
-   Alarms
-   Dashboards
-   Events and monitoring integrations

AWS documentation:

https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html

Examples:

``` text
EC2 CPUUtilization
ALB request count
Lambda errors
RDS connections
Application logs
```

## 41.2 Manual

1.  Open CloudWatch.
2.  Open Metrics.
3.  Select a service.
4.  Select a metric.
5.  Create an alarm.
6.  Configure threshold.
7.  Select notification action if required.
8.  Review alarm state.

## 41.3 CLI

List metrics:

``` bash
aws cloudwatch list-metrics --namespace AWS/EC2
```

Expected structure:

``` json
{
  "Metrics": [
    {
      "Namespace": "AWS/EC2",
      "MetricName": "CPUUtilization",
      "Dimensions": [
        {
          "Name": "InstanceId",
          "Value": "i-xxxxxxxx"
        }
      ]
    }
  ]
}
```

## 41.4 Terraform

``` hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "saa-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = var.instance_id
  }

  alarm_description = "Alarm when CPU is above 80 percent"
}
```

## 41.5 Exam point

CloudWatch monitors.

CloudTrail audits API activity.

GuardDuty detects threats.

Security Hub centralizes security findings.

------------------------------------------------------------------------

# 42. VPC Flow Logs

VPC Flow Logs capture information about network traffic.

They can help troubleshoot:

-   Security group issues
-   NACL issues
-   Unexpected network connections
-   Connectivity problems

They do not replace security groups or NACLs.

Example concept:

``` text
Traffic
   |
VPC Flow Logs
   |
CloudWatch Logs / S3
```

Manual:

1.  Open VPC.
2.  Select VPC.
3.  Create flow log.
4.  Select destination.
5.  Configure IAM role if required.
6.  Enable.
7.  Generate traffic.
8.  Review records.

Terraform:

``` hcl
resource "aws_flow_log" "vpc" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  log_destination = aws_cloudwatch_log_group.vpc_flow.arn
  iam_role_arn    = aws_iam_role.flow_logs.arn
}
```

Supporting IAM role and CloudWatch log group must also be created.

------------------------------------------------------------------------

# PART III -- TASK 1.3

# DETERMINE APPROPRIATE DATA SECURITY CONTROLS

------------------------------------------------------------------------

# 43. Data Classification

Before selecting a security control, classify the data.

Example:

``` text
Public
Internal
Confidential
Highly Confidential
Regulated
```

Examples:

  Data                             Possible classification
  -------------------------------- ----------------------------
  Public website content           Public
  Internal architecture document   Internal
  Customer records                 Confidential
  Passwords                        Highly sensitive
  Payment information              Regulated/highly sensitive

Security controls should reflect sensitivity.

------------------------------------------------------------------------

# 44. Encryption at Rest

Encryption at rest protects stored data.

Common AWS services support encryption using AWS KMS.

Examples:

-   S3
-   EBS
-   RDS
-   Secrets Manager
-   SQS
-   SNS
-   DynamoDB
-   EFS

Encryption at rest is different from encryption in transit.

------------------------------------------------------------------------

# 45. AWS KMS

## 45.1 Concept

AWS Key Management Service manages cryptographic keys.

Important key categories:

-   AWS owned keys
-   AWS managed keys
-   Customer managed keys

Customer-managed keys provide more control over:

-   Key policies
-   Grants
-   Rotation configuration
-   Disable/enable operations
-   Deletion scheduling
-   Auditability

AWS KMS:

https://docs.aws.amazon.com/kms/latest/developerguide/overview.html

## 45.2 Manual

1.  Open KMS.
2.  Create key.
3.  Select symmetric encryption.
4.  Add an alias:

``` text
alias/saa-lab
```

5.  Configure administrators.
6.  Configure key users.
7.  Review.
8.  Create.
9.  Inspect key policy.

## 45.3 CLI

Create:

``` bash
aws kms create-key \
  --description "SAA Domain 1 lab key"
```

Expected:

``` json
{
  "KeyMetadata": {
    "KeyId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "Arn": "arn:aws:kms:ap-south-1:123456789012:key/xxxxxxxx-...",
    "KeyState": "Enabled",
    "KeyUsage": "ENCRYPT_DECRYPT",
    "KeySpec": "SYMMETRIC_DEFAULT"
  }
}
```

Create alias:

``` bash
aws kms create-alias \
  --alias-name alias/saa-lab \
  --target-key-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## 45.4 Terraform

``` hcl
resource "aws_kms_key" "lab" {
  description         = "SAA Domain 1 lab encryption key"
  enable_key_rotation = true

  tags = {
    Purpose = "SAA-Domain1-Lab"
  }
}

resource "aws_kms_alias" "lab" {
  name          = "alias/saa-lab"
  target_key_id = aws_kms_key.lab.key_id
}
```

Run:

``` bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Verify:

``` bash
aws kms describe-key \
  --key-id alias/saa-lab
```

Destroy:

``` bash
terraform destroy
```

KMS customer-managed keys have deletion scheduling behavior. Understand
the deletion window before deleting a key used by real data.

------------------------------------------------------------------------

# 46. KMS Key Policies

KMS uses key policies as a central part of authorization.

Example:

``` text
IAM principal
     |
IAM policy
     |
KMS key policy
     |
KMS key
```

A principal may need both appropriate IAM permissions and permission
through the KMS key policy depending on the configuration.

Important KMS exam concepts:

-   Key policy
-   IAM policy
-   Grants
-   Key administrators
-   Key users
-   Rotation
-   Encryption context

------------------------------------------------------------------------

# 47. Encrypting S3 Data

## 47.1 Manual

Create an S3 bucket.

Enable:

-   Block Public Access
-   Versioning
-   Server-side encryption
-   Lifecycle policy if required

Do not make the bucket public for this lab.

## 47.2 CLI

Create:

``` bash
aws s3api create-bucket \
  --bucket saa-domain1-lab-example \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
```

Enable versioning:

``` bash
aws s3api put-bucket-versioning \
  --bucket saa-domain1-lab-example \
  --versioning-configuration Status=Enabled
```

Block public access:

``` bash
aws s3api put-public-access-block \
  --bucket saa-domain1-lab-example \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

## 47.3 Terraform

``` hcl
resource "aws_s3_bucket" "secure" {
  bucket_prefix = "saa-secure-"
}

resource "aws_s3_bucket_public_access_block" "secure" {
  bucket = aws_s3_bucket.secure.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "secure" {
  bucket = aws_s3_bucket.secure.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure" {
  bucket = aws_s3_bucket.secure.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

For KMS encryption:

``` hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "kms" {
  bucket = aws_s3_bucket.secure.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.lab.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}
```

## 47.4 Exam point

S3 security questions often combine:

-   Block Public Access
-   Bucket policy
-   IAM policy
-   Encryption
-   Versioning
-   Lifecycle
-   Object ownership
-   Access logging or CloudTrail where appropriate

------------------------------------------------------------------------

# 48. S3 Versioning

Versioning maintains multiple versions of objects.

Example:

``` text
report.pdf
   |
   +-- Version 1
   +-- Version 2
   +-- Version 3
```

If a user accidentally overwrites an object, an older version can remain
available.

Versioning is not a replacement for backup.

------------------------------------------------------------------------

# 49. S3 Lifecycle Policies

Lifecycle rules automate object transitions or expiration.

Example:

``` text
Day 0:
S3 Standard

Day 30:
S3 Standard-IA

Day 90:
Glacier class

Day 365:
Expire
```

The actual transition should match access patterns and retention
requirements.

Terraform:

``` hcl
resource "aws_s3_bucket_lifecycle_configuration" "secure" {
  bucket = aws_s3_bucket.secure.id

  rule {
    id     = "archive-old-objects"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
```

------------------------------------------------------------------------

# 50. TLS and Data in Transit

Encryption in transit protects network communication.

Common example:

``` text
Client
   |
HTTPS/TLS
   |
Load Balancer
   |
Application
```

Use TLS for sensitive application traffic.

Do not send passwords or sensitive data over plain HTTP when the
application requires secure communication.

------------------------------------------------------------------------

# 51. AWS Certificate Manager (ACM)

ACM provides and manages TLS certificates.

Common use cases:

-   Application Load Balancer
-   CloudFront
-   API Gateway
-   Other supported AWS integrations

AWS documentation:

https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html

## 51.1 Manual

1.  Open Certificate Manager.
2.  Select Request certificate.
3.  Choose public certificate for an internet-facing domain.
4.  Enter a domain you control.
5.  Choose DNS validation.
6.  Add the validation DNS record.
7.  Wait for validation.
8.  Attach the certificate to the appropriate service.

## 51.2 Terraform

``` hcl
resource "aws_acm_certificate" "site" {
  domain_name       = "example.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
```

DNS validation records depend on your DNS provider.

## 51.3 Exam point

If a scenario asks for HTTPS/TLS certificate management integrated with
AWS services, consider ACM.

For CloudFront certificates, remember the special regional requirement:
certificates used with CloudFront are requested/imported in
**us-east-1**.

------------------------------------------------------------------------

# 52. Data Backups and Recovery

Security includes data recovery.

Consider:

-   Backup frequency
-   Retention
-   Recovery Point Objective (RPO)
-   Recovery Time Objective (RTO)
-   Replication
-   Versioning
-   Snapshots
-   Cross-region replication
-   Cross-account backup copies

Examples:

``` text
RPO = maximum acceptable data loss
RTO = maximum acceptable recovery time
```

Example requirement:

``` text
RPO: 15 minutes
RTO: 1 hour
```

The architecture must support those targets.

------------------------------------------------------------------------

# 53. AWS Backup

AWS Backup provides centralized backup management for supported AWS
resources.

Typical workflow:

``` text
Resource
   |
Backup plan
   |
Backup vault
   |
Retention
   |
Optional cross-account/cross-region copy
```

Manual:

1.  Open AWS Backup.
2.  Create backup vault.
3.  Create backup plan.
4.  Configure schedule.
5.  Configure retention.
6.  Assign resources.
7.  Run or wait for backup.
8.  Review recovery points.

Terraform resource names can include:

``` hcl
resource "aws_backup_vault" "lab" {
  name = "saa-lab-vault"
}

resource "aws_backup_plan" "lab" {
  name = "saa-lab-plan"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.lab.name
    schedule          = "cron(0 18 * * ? *)"
  }
}
```

Use the current AWS provider documentation for service-specific backup
resource configuration.

------------------------------------------------------------------------

# 54. Data Replication

Replication improves availability and recovery options.

Examples:

-   S3 Cross-Region Replication
-   RDS Multi-AZ
-   DynamoDB Global Tables
-   ECR replication
-   Backup copies across accounts/regions

Replication is not automatically the same as backup.

For example, deleting data can sometimes propagate through a replication
system.

A separate backup strategy may still be required.

------------------------------------------------------------------------

# 55. Data Retention

Retention means how long data must be preserved.

Example:

``` text
Application logs:
30 days

Security audit logs:
1 year

Financial records:
7 years
```

Retention must match:

-   Business requirements
-   Legal requirements
-   Compliance requirements
-   Cost constraints

Use lifecycle policies and centralized log storage where appropriate.

------------------------------------------------------------------------

# 56. Data Access Controls

Use:

-   IAM
-   Resource policies
-   KMS key policies
-   S3 bucket policies
-   VPC controls
-   Application authentication
-   Network segmentation
-   Secrets management

Example:

``` text
User
 |
IAM Identity Center
 |
Permission Set
 |
AWS Account
 |
IAM role
 |
S3 bucket policy
 |
KMS key policy
 |
Encrypted object
```

Security is normally layered rather than based on one control.

------------------------------------------------------------------------

# PART IV -- INTEGRATED SECURITY DESIGN

# 57. Secure Three-Tier Architecture

A common secure application architecture:

``` text
                     Internet
                        |
                     Route 53
                        |
                    CloudFront
                        |
                       WAF
                        |
                  Application Load
                     Balancer
                        |
              +---------+---------+
              |                   |
          Public subnet       Public subnet
              |                   |
          ALB nodes            ALB nodes
              |
              v
        Private App Tier
       +----------------+
       | EC2 / ECS      |
       | Application    |
       +----------------+
              |
              v
        Private DB Tier
       +----------------+
       | RDS            |
       | PostgreSQL     |
       +----------------+

Supporting services:
- IAM roles
- Secrets Manager
- KMS
- CloudTrail
- CloudWatch
- GuardDuty
- Security Hub
- VPC Flow Logs
```

Security rules:

``` text
Internet
  -> ALB: 443

ALB
  -> App: application port

App
  -> DB: 5432

Internet
  -X-> DB

Internet
  -X-> private app instances
```

------------------------------------------------------------------------

# 58. Capstone Manual Implementation

## Step 1: Create VPC

Create:

``` text
VPC: 10.0.0.0/16

Public:
10.0.1.0/24
10.0.2.0/24

Private application:
10.0.11.0/24
10.0.12.0/24

Private database:
10.0.21.0/24
10.0.22.0/24
```

## Step 2: Create Internet Gateway

Attach it to the VPC.

## Step 3: Create public route table

Route:

``` text
0.0.0.0/0 -> Internet Gateway
```

Associate public subnets.

## Step 4: Create NAT Gateway

Place it in one public subnet.

Create an Elastic IP.

## Step 5: Create private route table

Route:

``` text
0.0.0.0/0 -> NAT Gateway
```

Associate application subnets.

## Step 6: Database subnets

Use database subnets without a direct Internet Gateway route.

## Step 7: Security groups

Create:

``` text
ALB-SG
APP-SG
DB-SG
```

Rules:

``` text
ALB-SG:
443 from Internet

APP-SG:
8080 from ALB-SG

DB-SG:
5432 from DB clients/app security group
```

## Step 8: IAM role

Create:

``` text
AppEC2Role
```

Allow only required AWS APIs.

## Step 9: Secrets Manager

Create:

``` text
prod/app/database
```

Store database credentials.

## Step 10: KMS

Create a customer-managed key if required.

Enable key rotation.

## Step 11: RDS

Create the database in private subnets.

Do not expose the database publicly.

## Step 12: WAF

Attach a Web ACL to the ALB.

Add AWS managed rules.

## Step 13: ACM

Create a certificate for the domain.

Attach to ALB HTTPS listener.

## Step 14: CloudTrail

Enable multi-region management-event logging.

Store logs securely.

## Step 15: CloudWatch

Create:

-   Application logs
-   ALB metrics
-   EC2 metrics
-   RDS metrics
-   Alarms

## Step 16: GuardDuty

Enable GuardDuty.

## Step 17: Security Hub

Enable Security Hub.

## Step 18: VPC Flow Logs

Enable traffic logging.

## Step 19: Test

Verify:

``` text
Internet -> HTTPS -> ALB
ALB -> App
App -> DB
Internet -X-> DB
Internet -X-> private App
```

------------------------------------------------------------------------

# 59. Capstone Terraform Structure

``` text
capstone/
├── versions.tf
├── provider.tf
├── variables.tf
├── outputs.tf
├── network.tf
├── security_groups.tf
├── iam.tf
├── kms.tf
├── secrets.tf
├── database.tf
├── load_balancer.tf
├── waf.tf
├── cloudtrail.tf
├── monitoring.tf
├── guardduty.tf
└── securityhub.tf
```

------------------------------------------------------------------------

# 60. Terraform Capstone Base Provider

`versions.tf`:

``` hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}
```

`provider.tf`:

``` hcl
provider "aws" {
  region = var.aws_region
}
```

`variables.tf`:

``` hcl
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "saa-domain1"
}
```

------------------------------------------------------------------------

# 61. Terraform Capstone Network

``` hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.aws_region}a"
}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "${var.aws_region}b"
}

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "${var.aws_region}a"
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "${var.aws_region}b"
}
```

------------------------------------------------------------------------

# 62. Terraform Security Groups

``` hcl
resource "aws_security_group" "alb" {
  name   = "${var.project}-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app" {
  name   = "${var.project}-app-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  name   = "${var.project}-db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

------------------------------------------------------------------------

# 63. Terraform KMS

``` hcl
resource "aws_kms_key" "app" {
  description         = "Application encryption key"
  enable_key_rotation = true

  tags = {
    Name = "${var.project}-kms"
  }
}

resource "aws_kms_alias" "app" {
  name          = "alias/${var.project}"
  target_key_id = aws_kms_key.app.key_id
}
```

------------------------------------------------------------------------

# 64. Terraform Secrets Manager

``` hcl
resource "aws_secretsmanager_secret" "database" {
  name = "${var.project}/database"

  kms_key_id = aws_kms_key.app.arn
}
```

For production, do not put real passwords directly in the `.tf` file.

------------------------------------------------------------------------

# 65. Terraform GuardDuty

``` hcl
resource "aws_guardduty_detector" "main" {
  enable = true
}
```

------------------------------------------------------------------------

# 66. Terraform CloudWatch

Example:

``` hcl
resource "aws_cloudwatch_log_group" "app" {
  name              = "/saa-domain1/application"
  retention_in_days = 30
}
```

The retention value should match your organization's requirements.

------------------------------------------------------------------------

# 67. Terraform Validation Workflow

From the capstone directory:

``` bash
terraform init
```

Expected:

``` text
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

Format:

``` bash
terraform fmt -recursive
```

Validate:

``` bash
terraform validate
```

Expected:

``` text
Success! The configuration is valid.
```

Plan:

``` bash
terraform plan
```

Review:

``` text
Plan: XX to add, 0 to change, 0 to destroy.
```

Apply:

``` bash
terraform apply
```

Terraform asks:

``` text
Do you want to perform these actions?
  Enter a value:
```

Enter:

``` text
yes
```

Expected:

``` text
Apply complete! Resources: XX added, 0 changed, 0 destroyed.
```

List:

``` bash
terraform state list
```

Inspect one:

``` bash
terraform state show aws_vpc.main
```

Destroy:

``` bash
terraform destroy
```

Expected:

``` text
Destroy complete! Resources: XX destroyed.
```

------------------------------------------------------------------------

# 68. Verification Checklist

After implementation, verify:

## Identity

``` bash
aws sts get-caller-identity
```

## IAM

``` bash
aws iam list-users
aws iam list-roles
aws iam list-groups
```

## VPC

``` bash
aws ec2 describe-vpcs
aws ec2 describe-subnets
aws ec2 describe-route-tables
aws ec2 describe-security-groups
```

## VPC endpoints

``` bash
aws ec2 describe-vpc-endpoints
```

## KMS

``` bash
aws kms list-keys
aws kms list-aliases
```

## Secrets

``` bash
aws secretsmanager list-secrets
```

## Parameters

``` bash
aws ssm describe-parameters
```

## GuardDuty

``` bash
aws guardduty list-detectors
```

## CloudTrail

``` bash
aws cloudtrail describe-trails
```

## CloudWatch

``` bash
aws cloudwatch list-metrics
```

------------------------------------------------------------------------

# 69. Common Errors and Fixes

## Error: AccessDenied

Example:

``` text
An error occurred (AccessDeniedException)
```

Check:

1.  Current identity:

``` bash
aws sts get-caller-identity
```

2.  IAM policy.
3.  Resource policy.
4.  SCP.
5.  Permission boundary.
6.  KMS key policy.
7.  Region.
8.  Explicit deny.

------------------------------------------------------------------------

## Error: InvalidClientTokenId

Usually means credentials are invalid or expired.

Run:

``` bash
aws sts get-caller-identity
```

Check:

``` bash
aws configure list
```

If using IAM Identity Center:

``` bash
aws sso login --profile <profile>
```

------------------------------------------------------------------------

## Error: InvalidGroup.NotFound

Check the VPC/security group or group identifier.

Example:

``` bash
aws ec2 describe-security-groups
```

------------------------------------------------------------------------

## Error: DependencyViolation

AWS resource deletion can fail when another resource still depends on
it.

Check:

-   ENIs
-   NAT Gateway
-   Route tables
-   Security groups
-   Load balancers
-   VPC endpoints

Destroy dependent resources first.

Terraform normally handles dependencies when resources are represented
correctly in configuration.

------------------------------------------------------------------------

## Terraform: Provider configuration error

Run:

``` bash
terraform init
```

Then:

``` bash
terraform validate
```

Check:

``` hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
```

------------------------------------------------------------------------

## Terraform: Invalid availability zone

Check available zones:

``` bash
aws ec2 describe-availability-zones \
  --region ap-south-1 \
  --query "AvailabilityZones[].ZoneName"
```

Expected:

``` json
[
  "ap-south-1a",
  "ap-south-1b",
  "ap-south-1c"
]
```

Availability-zone letters can differ by account/region mapping. Do not
assume a zone exists without checking.

------------------------------------------------------------------------

## Terraform: Resource already exists

Terraform may report:

``` text
already exists
```

If the resource was created manually, either:

1.  Delete the manual resource and let Terraform recreate it, or
2.  Import it into Terraform state.

Example:

``` bash
terraform import aws_s3_bucket.example <bucket-name>
```

Then run:

``` bash
terraform plan
```

------------------------------------------------------------------------

# 70. Security Design Decision Table

  Requirement                         AWS service/control
  ----------------------------------- ---------------------
  Human AWS workforce access          IAM Identity Center
  Temporary AWS permissions           IAM Role / STS
  EC2 access to S3                    IAM Role
  Central multi-account management    AWS Organizations
  Limit maximum account permissions   SCP
  Detect unintended external access   IAM Access Analyzer
  Store passwords                     Secrets Manager
  Store configuration                 Parameter Store
  Application authentication          Cognito
  Web attack filtering                AWS WAF
  DDoS protection                     AWS Shield
  Threat detection                    GuardDuty
  Central security findings           Security Hub
  API audit history                   CloudTrail
  Metrics/logs/alarms                 CloudWatch
  Network-level instance filtering    Security Group
  Subnet-level filtering              NACL
  Private AWS service connectivity    VPC Endpoint
  Encryption key management           KMS
  TLS certificates                    ACM
  Object version recovery             S3 Versioning
  Automatic storage transitions       S3 Lifecycle
  Backup management                   AWS Backup

------------------------------------------------------------------------

# 71. SAA-C03 Exam Scenario Patterns

## Scenario 1

**An EC2 instance needs to read objects from S3. Credentials must not be
stored on the instance.**

Answer:

**IAM role attached to EC2.**

------------------------------------------------------------------------

## Scenario 2

**Employees need access to several AWS accounts using centralized
identities.**

Answer:

**IAM Identity Center with AWS Organizations.**

------------------------------------------------------------------------

## Scenario 3

**A company must prevent member accounts from disabling a required
security service.**

Consider:

**SCP.**

------------------------------------------------------------------------

## Scenario 4

**A web application must block SQL injection attempts.**

Answer:

**AWS WAF.**

------------------------------------------------------------------------

## Scenario 5

**A company needs DDoS protection.**

Consider:

**AWS Shield.**

------------------------------------------------------------------------

## Scenario 6

**A security team needs to identify suspicious AWS activity.**

Answer:

**GuardDuty.**

------------------------------------------------------------------------

## Scenario 7

**A security team needs centralized security findings and posture
information.**

Answer:

**Security Hub.**

------------------------------------------------------------------------

## Scenario 8

**An auditor needs to determine who called DeleteBucket.**

Answer:

**CloudTrail.**

------------------------------------------------------------------------

## Scenario 9

**An application needs a database password with rotation capability.**

Answer:

**Secrets Manager.**

------------------------------------------------------------------------

## Scenario 10

**A private EC2 instance needs S3 access without traversing the public
internet.**

Answer:

**S3 VPC gateway endpoint.**

------------------------------------------------------------------------

## Scenario 11

**Traffic to a database must be allowed only from application servers.**

Answer:

Use a database security group whose inbound rule references the
application security group.

Avoid:

``` text
0.0.0.0/0
```

------------------------------------------------------------------------

## Scenario 12

**A subnet must explicitly deny a specific source IP.**

Consider:

**Network ACL**, because security groups do not support deny rules.

------------------------------------------------------------------------

## Scenario 13

**Stored data requires customer-controlled encryption keys.**

Consider:

**Customer-managed KMS key.**

------------------------------------------------------------------------

## Scenario 14

**The application must use HTTPS.**

Consider:

**ACM certificate + TLS-enabled endpoint such as ALB/CloudFront/API
Gateway.**

------------------------------------------------------------------------

# 72. Security Group and NACL Scenario Practice

## Question

An application has:

``` text
Web tier
App tier
DB tier
```

Required:

``` text
Internet -> Web
Web -> App
App -> DB
Internet -X-> DB
```

Correct security design:

``` text
Web SG:
443 from Internet

App SG:
8080 from Web SG

DB SG:
5432 from App SG
```

This creates security-group chaining.

------------------------------------------------------------------------

# 73. IAM Policy Practice

Suppose the application should only read:

``` text
s3://company-reports/public/
```

Do not use:

``` json
{
  "Effect": "Allow",
  "Action": "s3:*",
  "Resource": "*"
}
```

Prefer a narrowly scoped policy such as:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::company-reports/public/*"
    }
  ]
}
```

If listing the bucket is also required, grant `s3:ListBucket` on the
bucket ARN with an appropriate prefix condition.

------------------------------------------------------------------------

# 74. Terraform Security Rules

Follow these rules:

## Rule 1

Do not commit secrets to Git.

## Rule 2

Protect Terraform state.

## Rule 3

Use remote state with appropriate encryption and access control for team
environments.

## Rule 4

Use variables for environment-specific values.

## Rule 5

Use modules for repeated architecture patterns.

## Rule 6

Review every `terraform plan`.

## Rule 7

Tag resources.

Example:

``` hcl
tags = {
  Project     = "SAA-Domain1"
  Environment = "Lab"
  Owner       = "Training"
}
```

## Rule 8

Destroy temporary labs.

------------------------------------------------------------------------

# 75. Suggested Student Lab Sequence

Complete the labs in this order.

## Lab 1

AWS account and MFA

## Lab 2

IAM user

## Lab 3

IAM group

## Lab 4

IAM policy

## Lab 5

IAM role

## Lab 6

EC2 role access to S3

## Lab 7

IAM Identity Center

## Lab 8

AWS Organizations

## Lab 9

SCP

## Lab 10

IAM Access Analyzer

## Lab 11

VPC and subnets

## Lab 12

Security groups

## Lab 13

NACLs

## Lab 14

Route tables

## Lab 15

NAT Gateway

## Lab 16

S3 VPC endpoint

## Lab 17

Secrets Manager

## Lab 18

Parameter Store

## Lab 19

Cognito

## Lab 20

WAF

## Lab 21

GuardDuty

## Lab 22

Security Hub

## Lab 23

CloudTrail

## Lab 24

CloudWatch

## Lab 25

KMS

## Lab 26

S3 encryption/versioning/lifecycle

## Lab 27

ACM/TLS

## Lab 28

Backup

## Lab 29

Secure three-tier architecture

## Lab 30

Complete Terraform capstone

------------------------------------------------------------------------

# 76. Final Practical Exercise

Build the following without copying a finished architecture first.

``` text
                         Internet
                            |
                         HTTPS
                            |
                           WAF
                            |
                           ALB
                       /          \
                  Public-A       Public-B
                       |
                 Private App Tier
                 /             \
             App-A             App-B
                 \             /
                   Private DB
                   /        \
                DB-A       DB-B
```

Implement:

### Identity

-   IAM role for application
-   Least-privilege policy
-   MFA for human access

### Network

-   VPC
-   Public subnets
-   Private application subnets
-   Private database subnets
-   Route tables
-   Security groups
-   NACLs
-   NAT Gateway where required
-   VPC endpoint where appropriate

### Application security

-   WAF
-   Shield awareness
-   Secrets Manager
-   Cognito where application authentication is required

### Data security

-   KMS
-   S3 encryption
-   S3 versioning
-   Lifecycle
-   Database encryption
-   TLS

### Monitoring and detection

-   CloudTrail
-   CloudWatch
-   VPC Flow Logs
-   GuardDuty
-   Security Hub

### Infrastructure as code

Recreate the architecture with Terraform.

------------------------------------------------------------------------

# 77. Capstone Verification Checklist

Before considering the architecture complete, verify:

``` text
[ ] Root MFA enabled
[ ] Human users do not use administrator permissions unnecessarily
[ ] Application uses IAM roles
[ ] No AWS access keys are embedded in application code
[ ] Secrets are stored in Secrets Manager/Parameter Store
[ ] Least privilege policies are used
[ ] SCP strategy is understood for multi-account environments
[ ] VPC uses appropriate subnet segmentation
[ ] Database is not publicly accessible
[ ] Security groups restrict source traffic
[ ] NACLs are configured when required
[ ] Route tables are correct
[ ] Private resources do not need direct internet ingress
[ ] VPC endpoints are used where appropriate
[ ] WAF protects the web entry point
[ ] TLS is enabled
[ ] Data is encrypted at rest
[ ] KMS permissions are controlled
[ ] CloudTrail is enabled
[ ] CloudWatch monitoring exists
[ ] GuardDuty is enabled
[ ] Security Hub is enabled where required
[ ] Backups and retention are configured
[ ] Terraform plan was reviewed
[ ] Terraform state is protected
[ ] Temporary resources are destroyed after the lab
```

------------------------------------------------------------------------

# 78. Official AWS Documentation Reference List

## SAA-C03

SAA-C03 main exam guide:

https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03/solutions-architect-associate-03.html

Domain 1:

https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03/solutions-architect-associate-03-domain1.html

Technologies and Concepts:

https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03/saa-technologies-concepts.html

In-scope services:

https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03/saa-03-in-scope-services.html

## IAM

https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html

https://docs.aws.amazon.com/IAM/latest/UserGuide/access.html

https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html

https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html

https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html

## IAM Identity Center

https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html

https://docs.aws.amazon.com/singlesignon/latest/userguide/identity-center-and-orgs.html

## Organizations

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html

## VPC

https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html

https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html

https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html

https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints.html

## Secrets Manager

https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html

https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html

## Parameter Store

https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html

## Cognito

https://docs.aws.amazon.com/cognito/latest/developerguide/what-is-amazon-cognito.html

## WAF

https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html

## Shield

https://docs.aws.amazon.com/waf/latest/developerguide/ddos-overview.html

## GuardDuty

https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html

## Security Hub

https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html

## CloudTrail

https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html

## CloudWatch

https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html

## KMS

https://docs.aws.amazon.com/kms/latest/developerguide/overview.html

## ACM

https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.html

## S3

https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html

https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html

## Terraform

https://developer.hashicorp.com/terraform/docs

https://registry.terraform.io/providers/hashicorp/aws/latest/docs

------------------------------------------------------------------------

# 79. Final Revision Sheet

Remember these core relationships:

``` text
IAM
 |
 +-- User       -> human/long-lived identity
 +-- Group      -> collection of users
 +-- Role       -> temporary assumable identity
 +-- Policy     -> permissions
 +-- MFA        -> stronger authentication
 +-- STS        -> temporary credentials
 +-- Identity Center -> centralized workforce access
```

``` text
Network security
 |
 +-- Security Group -> resource level, stateful, allow
 +-- NACL           -> subnet level, stateless, allow/deny
 +-- Route Table    -> traffic path
 +-- IGW            -> internet connectivity
 +-- NAT Gateway    -> private subnet outbound internet
 +-- VPC Endpoint   -> private AWS service connectivity
```

``` text
Application security
 |
 +-- Secrets Manager -> secrets
 +-- Parameter Store  -> configuration
 +-- Cognito         -> application identities
 +-- WAF             -> web request protection
 +-- Shield          -> DDoS protection
```

``` text
Detection and audit
 |
 +-- CloudTrail  -> API activity
 +-- CloudWatch  -> metrics/logs/alarms
 +-- GuardDuty   -> threat detection
 +-- Security Hub -> centralized security findings
 +-- Access Analyzer -> unintended external access
```

``` text
Data security
 |
 +-- KMS       -> encryption key management
 +-- ACM       -> TLS certificates
 +-- S3 encryption
 +-- Versioning
 +-- Lifecycle
 +-- Backup
 +-- Replication
 +-- Retention
```

The strongest SAA answers usually combine several controls rather than
relying on one service.

For example:

``` text
Human access
   -> IAM Identity Center
   -> MFA
   -> Permission Set
   -> Least privilege

Application
   -> IAM Role
   -> Private subnet
   -> Security Group
   -> Secrets Manager
   -> KMS

Web
   -> HTTPS
   -> ACM
   -> ALB
   -> WAF
   -> Shield

Data
   -> Encryption
   -> KMS
   -> Backup
   -> Versioning
   -> Lifecycle

Security operations
   -> CloudTrail
   -> CloudWatch
   -> GuardDuty
   -> Security Hub
   -> Access Analyzer
```

------------------------------------------------------------------------

# 80. Completion Standard

The Domain 1 training is complete when you can do all of the following
without following a step-by-step guide:

1.  Explain the difference between authentication and authorization.
2.  Explain IAM user, group, role, and policy.
3.  Explain trust policy versus permissions policy.
4.  Explain explicit deny.
5.  Explain least privilege.
6.  Explain MFA.
7.  Explain IAM Identity Center.
8.  Explain Organizations and SCPs.
9.  Explain cross-account role assumption.
10. Explain security groups versus NACLs.
11. Design public/private subnet architecture.
12. Explain IGW versus NAT Gateway.
13. Explain VPC endpoints.
14. Select Secrets Manager versus Parameter Store.
15. Explain Cognito user pools versus identity pools.
16. Select WAF versus Shield.
17. Explain GuardDuty versus Security Hub.
18. Explain CloudTrail versus CloudWatch.
19. Explain KMS and key policies.
20. Explain encryption at rest versus encryption in transit.
21. Explain S3 versioning and lifecycle.
22. Explain backup versus replication.
23. Implement the security controls manually.
24. Implement the same controls with Terraform.
25. Verify the implementation with AWS CLI.
26. Destroy the lab resources safely.

------------------------------------------------------------------------

# End of AWS SAA-C03 Domain 1 Student Training Material
