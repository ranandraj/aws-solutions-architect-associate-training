# AWS Service Control Policies (SCPs)

## Student Documentation

**Course:** AWS Solutions Architect Associate / AWS Security\
**Implementation:** AWS Management Console, AWS CLI, Terraform\
**Level:** Beginner to Intermediate\
**Updated:** September 2026

------------------------------------------------------------------------

## 1. Learning Objectives

After completing this topic, you should be able to:

-   Explain what an AWS Service Control Policy (SCP) is.
-   Explain SCPs, AWS Organizations, OUs, accounts, and the organization
    root.
-   Distinguish SCPs from IAM permission policies.
-   Explain maximum available permissions and explicit deny.
-   Create, attach, test, detach, and delete an SCP.
-   Implement the same SCP through the Console, AWS CLI, and Terraform.
-   Troubleshoot common SCP problems.
-   Recognize common SAA-C03 SCP scenarios.

AWS defines SCPs as organization policies that centrally control the
maximum available permissions for IAM users and roles in member
accounts. SCPs do not grant permissions. citeturn1view1

------------------------------------------------------------------------

# 2. What is an SCP?

**SCP** means **Service Control Policy**.

An SCP is a policy in **AWS Organizations** that establishes a
permissions guardrail for IAM users and IAM roles in member accounts.

The key rule is:

> **An SCP does not grant permissions. It limits the maximum permissions
> that can be used.**

Example:

``` text
IAM Policy
Allow ec2:TerminateInstances
        |
        v
SCP
Deny ec2:TerminateInstances
        |
        v
Final result = DENIED
```

Even if an IAM policy grants an action, an applicable explicit SCP Deny
can prevent that action. citeturn1view1

------------------------------------------------------------------------

# 3. Why SCPs Are Used

Consider an organization with:

``` text
AWS Organization
|
+-- Management Account
|
+-- Production OU
|    +-- Production Account
|    +-- Database Account
|
+-- Development OU
|    +-- Development Account
|    +-- Testing Account
|
+-- Sandbox OU
     +-- Student Account
```

A company can use SCPs to establish organization-wide guardrails such
as:

-   Prevent selected dangerous operations.
-   Restrict use of particular AWS services.
-   Restrict requests to approved AWS Regions.
-   Prevent member accounts from leaving the organization.
-   Protect security controls from being disabled.
-   Enforce selected organization-level requirements.

AWS describes SCPs as coarse-grained guardrails and recommends testing
them before broad deployment. citeturn0search1

------------------------------------------------------------------------

# 4. AWS Organizations Hierarchy

The hierarchy is:

``` text
Organization
    |
    +-- Root
         |
         +-- Organizational Unit
         |      |
         |      +-- AWS Account
         |      +-- AWS Account
         |
         +-- Organizational Unit
                |
                +-- AWS Account
```

SCPs can be attached to:

-   Root
-   Organizational Unit (OU)
-   AWS account

Terraform's AWS provider supports SCP attachments to accounts, OUs, and
roots. citeturn0search0

------------------------------------------------------------------------

# 5. Management Account vs Member Account

This is an important concept.

## Management account

The account that owns and manages the AWS Organization.

SCPs **do not affect IAM users or roles in the management account**.
citeturn1view1

## Member account

An account inside the organization.

SCPs can restrict IAM users and roles in member accounts, including the
member account root user, subject to AWS exceptions. citeturn1view1

Therefore:

``` text
Management Account
      |
      +-- SCP does not restrict its IAM users/roles

Member Account
      |
      +-- SCP can restrict IAM users/roles
```

------------------------------------------------------------------------

# 6. SCP Does Not Grant Permissions

Suppose:

``` json
{
  "Effect": "Allow",
  "Action": "s3:*",
  "Resource": "*"
}
```

is attached to an IAM role.

The role may use S3 if all other applicable authorization controls
permit it.

An SCP such as:

``` json
{
  "Effect": "Deny",
  "Action": "s3:DeleteBucket",
  "Resource": "*"
}
```

does not grant S3 access.

It only adds a restriction.

Therefore:

``` text
IAM permission
      +
SCP guardrail
      =
Effective access
```

AWS explicitly states that permissions must still be granted by
appropriate IAM or resource-based policies. citeturn1view1

------------------------------------------------------------------------

# 7. Effective Permissions

A useful simplified model is:

``` text
IAM/resource policies
        AND
Applicable SCPs
        |
        v
Effective permissions
```

Example:

``` text
IAM:
Allow ec2:RunInstances

SCP:
Allows the action

Result:
Can be allowed
```

But:

``` text
IAM:
Allow ec2:TerminateInstances

SCP:
Deny ec2:TerminateInstances

Result:
DENIED
```

AWS describes the effective permissions as the intersection between
permissions allowed by applicable organization policies and permissions
granted by IAM/resource policies. citeturn1view1

------------------------------------------------------------------------

# 8. FullAWSAccess

AWS Organizations uses a default `FullAWSAccess` policy when SCPs are
enabled.

A common deny-list model is:

``` text
FullAWSAccess
       +
Specific Deny SCPs
       |
       v
Maximum permissions
```

AWS warns that removing `FullAWSAccess` without replacing it
appropriately can cause AWS actions from member accounts to fail.
citeturn1view1

For learning, a targeted Deny SCP is safer than experimenting with a
broad allow-list SCP.

------------------------------------------------------------------------

# 9. SCP Syntax

SCPs use JSON syntax similar to IAM policies.

Basic structure:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Example",
      "Effect": "Deny",
      "Action": [
        "service:Action"
      ],
      "Resource": "*"
    }
  ]
}
```

Important elements:

``` text
Version
Statement
Sid
Effect
Action
NotAction
Resource
NotResource
Condition
```

AWS documents SCP syntax as a subset of IAM policy syntax.
citeturn0search3

------------------------------------------------------------------------

# 10. Version

``` json
"Version": "2012-10-17"
```

This is the policy language version normally used in AWS IAM-style JSON
policies.

------------------------------------------------------------------------

# 11. Statement

A policy can contain one or more statements.

``` json
"Statement": [
  {
    "Sid": "DenyTerminate",
    "Effect": "Deny",
    "Action": "ec2:TerminateInstances",
    "Resource": "*"
  }
]
```

Multiple statements can implement multiple guardrails.

------------------------------------------------------------------------

# 12. Sid

`Sid` is an optional statement identifier.

Example:

``` json
"Sid": "DenyEC2Terminate"
```

Use meaningful IDs because they make policies easier to read and
troubleshoot.

------------------------------------------------------------------------

# 13. Effect

Common values:

``` json
"Effect": "Allow"
```

or:

``` json
"Effect": "Deny"
```

A guardrail example normally uses:

``` json
"Effect": "Deny"
```

------------------------------------------------------------------------

# 14. Action

`Action` identifies the AWS API operation.

One action:

``` json
"Action": "ec2:TerminateInstances"
```

Multiple actions:

``` json
"Action": [
  "ec2:StopInstances",
  "ec2:TerminateInstances"
]
```

All actions for a service:

``` json
"Action": "ec2:*"
```

Broad actions should be used carefully.

------------------------------------------------------------------------

# 15. Resource

Example:

``` json
"Resource": "*"
```

This means all resources applicable to that action.

Whether a specific ARN can be used depends on the AWS service and
action.

Check the AWS service authorization documentation before using
resource-specific SCPs.

------------------------------------------------------------------------

# 16. Condition

A condition controls when the statement applies.

Example:

``` json
"Condition": {
  "StringNotEquals": {
    "aws:RequestedRegion": [
      "ap-south-1",
      "us-east-1"
    ]
  }
}
```

Conditions can use request context such as:

-   Requested Region
-   Source IP
-   Principal information
-   Service-specific keys

AWS's SCP creation documentation describes global and service-specific
condition keys. citeturn1view2

------------------------------------------------------------------------

# 17. NotAction

`NotAction` means the statement applies to actions other than the
specified actions.

Example:

``` json
{
  "Effect": "Deny",
  "NotAction": [
    "support:*"
  ],
  "Resource": "*"
}
```

`NotAction` can have a much broader effect than expected. Use it only
after carefully reviewing all affected AWS services and actions.

AWS documents `NotAction` as part of SCP syntax. citeturn0search3

------------------------------------------------------------------------

# 18. Student Lab: Deny EC2 Termination

## Objective

Create an SCP that prevents a member account from terminating EC2
instances.

Architecture:

``` text
Management Account
       |
       +-- SCP
       |
       +-- Member Account
              |
              +-- IAM User/Role
                    |
                    +-- EC2
```

SCP:

``` text
Deny:
ec2:TerminateInstances
```

------------------------------------------------------------------------

# 19. Lab Prerequisites

You need:

-   AWS Organization
-   All features enabled
-   Management account access
-   A dedicated sandbox member account
-   AWS CLI
-   Terraform
-   Appropriate AWS Organizations permissions

SCPs are available only when the organization has all features enabled.
citeturn1view1

**Do not use a production account for this exercise.**

------------------------------------------------------------------------

# 20. Check the Organization Using CLI

Run:

``` bash
aws organizations describe-organization
```

Example:

``` json
{
  "Organization": {
    "Id": "o-exampleorg",
    "FeatureSet": "ALL",
    "MasterAccountId": "111122223333"
  }
}
```

Check:

``` text
FeatureSet = ALL
```

------------------------------------------------------------------------

# 21. Check Your AWS Identity

Run:

``` bash
aws sts get-caller-identity
```

Example:

``` json
{
  "UserId": "AIDAXXXXX",
  "Account": "111122223333",
  "Arn": "arn:aws:iam::111122223333:user/admin"
}
```

Confirm that this is the management account before creating the SCP.

------------------------------------------------------------------------

# 22. Find Organization Roots

Run:

``` bash
aws organizations list-roots
```

Example:

``` json
{
  "Roots": [
    {
      "Id": "r-example",
      "Name": "Root",
      "PolicyTypes": [
        {
          "Type": "SERVICE_CONTROL_POLICY",
          "Status": "ENABLED"
        }
      ]
    }
  ]
}
```

------------------------------------------------------------------------

# 23. Find Member Accounts

Run:

``` bash
aws organizations list-accounts
```

Example:

``` json
{
  "Accounts": [
    {
      "Id": "111122223333",
      "Name": "Management",
      "Status": "ACTIVE"
    },
    {
      "Id": "444455556666",
      "Name": "Student-Sandbox",
      "Status": "ACTIVE"
    }
  ]
}
```

Set:

``` text
MEMBER_ACCOUNT_ID=444455556666
```

Use your actual sandbox account ID.

------------------------------------------------------------------------

# 24. Manual Implementation Using AWS Console

## Step 1: Open AWS Organizations

Sign in to the management account.

Open:

``` text
AWS Console
    |
AWS Organizations
```

------------------------------------------------------------------------

## Step 2: Open Service Control Policies

Go to:

``` text
Policies
    |
Service control policies
```

SCPs must be enabled for the organization.

------------------------------------------------------------------------

## Step 3: Create the SCP

Choose:

``` text
Create policy
```

Policy name:

``` text
DenyEC2TerminateInstances
```

Description:

``` text
Prevent EC2 termination in the student sandbox account.
```

AWS's current console supports creating the policy through the JSON
editor or visual editor. citeturn1view2

------------------------------------------------------------------------

# 25. Enter the SCP JSON

Use:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyEC2TerminateInstances",
      "Effect": "Deny",
      "Action": [
        "ec2:TerminateInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

Choose:

``` text
Create policy
```

------------------------------------------------------------------------

# 26. Attach the SCP

Open the target member account.

Select the policy attachment controls and attach:

``` text
DenyEC2TerminateInstances
```

The structure becomes:

``` text
Organization
 |
 +-- Student-Sandbox Account
        |
        +-- DenyEC2TerminateInstances
```

------------------------------------------------------------------------

# 27. Verify the Attachment

In AWS Organizations, open the SCP and check its targets.

The sandbox account should appear as an attached target.

------------------------------------------------------------------------

# 28. Test the SCP Manually

Switch to the member account.

Select a test EC2 instance.

Go to:

``` text
EC2
 |
Instances
 |
Select instance
 |
Instance state
 |
Terminate
```

The request should be denied if the test principal otherwise has
permission to terminate instances.

Expected:

``` text
AccessDenied
```

The exact console message can vary.

------------------------------------------------------------------------

# 29. Test Using CLI

From the member account:

``` bash
aws sts get-caller-identity
```

Then:

``` bash
aws ec2 terminate-instances   --instance-ids i-0123456789abcdef0
```

Expected:

``` text
UnauthorizedOperation
```

or an equivalent authorization error.

The important result is:

``` text
ec2:TerminateInstances = DENIED
```

------------------------------------------------------------------------

# 30. CLI Implementation

Create:

``` text
deny-ec2-terminate.json
```

Contents:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyEC2TerminateInstances",
      "Effect": "Deny",
      "Action": [
        "ec2:TerminateInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

------------------------------------------------------------------------

# 31. Create the SCP Using CLI

Run from the management account:

``` bash
aws organizations create-policy   --name DenyEC2TerminateInstances   --description "Prevent EC2 termination in sandbox member accounts"   --type SERVICE_CONTROL_POLICY   --content file://deny-ec2-terminate.json
```

AWS documents `organizations create-policy` for creating an SCP. The
minimum permission includes `organizations:CreatePolicy`.
citeturn1view2

Example response:

``` json
{
  "Policy": {
    "PolicySummary": {
      "Id": "p-example123",
      "Arn": "arn:aws:organizations::111122223333:policy/o-exampleorg/service_control_policy/p-example123",
      "Name": "DenyEC2TerminateInstances",
      "Type": "SERVICE_CONTROL_POLICY",
      "AwsManaged": false
    }
  }
}
```

Save:

``` text
POLICY_ID=p-example123
```

------------------------------------------------------------------------

# 32. Attach the SCP Using CLI

``` bash
aws organizations attach-policy   --policy-id p-example123   --target-id 444455556666
```

A successful command normally produces no output.

------------------------------------------------------------------------

# 33. Verify the Attachment

``` bash
aws organizations list-policies-for-target   --target-id 444455556666   --filter SERVICE_CONTROL_POLICY
```

Example:

``` json
{
  "Policies": [
    {
      "Id": "p-example123",
      "Name": "DenyEC2TerminateInstances",
      "Type": "SERVICE_CONTROL_POLICY",
      "AwsManaged": false
    }
  ]
}
```

------------------------------------------------------------------------

# 34. Read the SCP

``` bash
aws organizations describe-policy   --policy-id p-example123
```

To display only its content:

``` bash
aws organizations describe-policy   --policy-id p-example123   --query 'Policy.Content'   --output text
```

------------------------------------------------------------------------

# 35. Test the CLI-Created SCP

Switch to member-account credentials:

``` bash
aws sts get-caller-identity
```

Then:

``` bash
aws ec2 terminate-instances   --instance-ids i-0123456789abcdef0
```

Expected:

``` text
UnauthorizedOperation
```

------------------------------------------------------------------------

# 36. Detach the SCP

When the lab is complete:

``` bash
aws organizations detach-policy   --policy-id p-example123   --target-id 444455556666
```

Verify:

``` bash
aws organizations list-policies-for-target   --target-id 444455556666   --filter SERVICE_CONTROL_POLICY
```

------------------------------------------------------------------------

# 37. Delete the SCP

After detaching it:

``` bash
aws organizations delete-policy   --policy-id p-example123
```

The policy must not remain attached when it is deleted.

------------------------------------------------------------------------

# 38. Terraform Implementation

The AWS Terraform provider provides:

``` text
aws_organizations_policy
```

for managing Organizations policies.

It also provides:

``` text
aws_organizations_policy_attachment
```

for attaching a policy to an account, OU, or root.

The current provider supports `SERVICE_CONTROL_POLICY` and currently
lists it as the default type for `aws_organizations_policy`.
citeturn2search0turn0search0

------------------------------------------------------------------------

# 39. Terraform Architecture

``` text
Terraform
    |
    +-- aws_organizations_policy
    |       |
    |       +-- SCP JSON
    |
    +-- aws_organizations_policy_attachment
            |
            +-- Member Account
```

------------------------------------------------------------------------

# 40. Terraform Project

Create:

``` text
terraform-scp-lab/
|
+-- versions.tf
+-- provider.tf
+-- variables.tf
+-- scp.tf
+-- outputs.tf
+-- terraform.tfvars
```

------------------------------------------------------------------------

# 41. `versions.tf`

``` hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.62"
    }
  }
}
```

The current AWS provider documentation lists version 6.62.0 as the
latest release in September 2026. Check the registry before starting a
new project because provider versions change. citeturn2search1

------------------------------------------------------------------------

# 42. `provider.tf`

``` hcl
provider "aws" {
  region = "ap-south-1"
}
```

AWS Organizations is global, but the AWS provider still requires a
region configuration.

------------------------------------------------------------------------

# 43. `variables.tf`

``` hcl
variable "member_account_id" {
  type        = string
  description = "AWS member account ID receiving the SCP"
}
```

------------------------------------------------------------------------

# 44. `terraform.tfvars`

``` hcl
member_account_id = "444455556666"
```

Replace this with your sandbox member account ID.

------------------------------------------------------------------------

# 45. `scp.tf`

``` hcl
resource "aws_organizations_policy" "deny_ec2_terminate" {
  name        = "DenyEC2TerminateInstances"
  description = "Prevent EC2 instance termination in the training account"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "DenyEC2TerminateInstances"
        Effect = "Deny"

        Action = [
          "ec2:TerminateInstances"
        ]

        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "Training"
    Purpose     = "SCP-Lab"
  }
}

resource "aws_organizations_policy_attachment" "member_account" {
  policy_id = aws_organizations_policy.deny_ec2_terminate.id
  target_id = var.member_account_id
}
```

The current Terraform Registry documents these resources and their
account/OU/root attachment behavior. citeturn2search0turn0search0

------------------------------------------------------------------------

# 46. `outputs.tf`

``` hcl
output "scp_id" {
  description = "SCP ID"
  value       = aws_organizations_policy.deny_ec2_terminate.id
}

output "scp_arn" {
  description = "SCP ARN"
  value       = aws_organizations_policy.deny_ec2_terminate.arn
}

output "target_account_id" {
  description = "Account receiving the SCP"
  value       = var.member_account_id
}
```

------------------------------------------------------------------------

# 47. Terraform Initialize

``` bash
cd terraform-scp-lab
terraform init
```

Expected:

``` text
Terraform has been successfully initialized!
```

------------------------------------------------------------------------

# 48. Terraform Format

``` bash
terraform fmt
```

------------------------------------------------------------------------

# 49. Terraform Validate

``` bash
terraform validate
```

Expected:

``` text
Success! The configuration is valid.
```

------------------------------------------------------------------------

# 50. Terraform Plan

``` bash
terraform plan
```

Expected conceptually:

``` text
Plan: 2 to add, 0 to change, 0 to destroy.
```

Resources:

``` text
aws_organizations_policy.deny_ec2_terminate
aws_organizations_policy_attachment.member_account
```

------------------------------------------------------------------------

# 51. Terraform Apply

``` bash
terraform apply
```

Review the plan.

Enter:

``` text
yes
```

Expected:

``` text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

------------------------------------------------------------------------

# 52. Terraform Output

``` bash
terraform output
```

Example:

``` text
scp_id = "p-example123"
scp_arn = "arn:aws:organizations::111122223333:policy/o-exampleorg/service_control_policy/p-example123"
target_account_id = "444455556666"
```

------------------------------------------------------------------------

# 53. Terraform State

``` bash
terraform state list
```

Expected:

``` text
aws_organizations_policy.deny_ec2_terminate
aws_organizations_policy_attachment.member_account
```

Inspect:

``` bash
terraform state show aws_organizations_policy.deny_ec2_terminate
```

and:

``` bash
terraform state show aws_organizations_policy_attachment.member_account
```

------------------------------------------------------------------------

# 54. Verify Terraform Deployment Using AWS CLI

``` bash
aws organizations list-policies-for-target   --target-id 444455556666   --filter SERVICE_CONTROL_POLICY
```

The Terraform-created SCP should appear.

------------------------------------------------------------------------

# 55. Test Terraform-Created SCP

Use member-account credentials:

``` bash
aws sts get-caller-identity
```

Then:

``` bash
aws ec2 terminate-instances   --instance-ids i-0123456789abcdef0
```

Expected:

``` text
UnauthorizedOperation
```

------------------------------------------------------------------------

# 56. Terraform Cleanup

Run:

``` bash
terraform destroy
```

Review:

``` text
2 to destroy
```

Enter:

``` text
yes
```

Terraform should detach/delete the policy resources it manages.

------------------------------------------------------------------------

# 57. SCP at an OU

Instead of attaching to an account:

``` hcl
resource "aws_organizations_policy_attachment" "sandbox_ou" {
  policy_id = aws_organizations_policy.deny_ec2_terminate.id
  target_id = var.sandbox_ou_id
}
```

Architecture:

``` text
Sandbox OU
   |
   +-- Account A
   +-- Account B
   +-- Account C
```

The SCP can then act as a guardrail for accounts under that OU.

Use this only after testing the SCP at a smaller scope.

------------------------------------------------------------------------

# 58. SCP at the Organization Root

An SCP can also be attached to the root.

Conceptually:

``` hcl
resource "aws_organizations_policy_attachment" "root" {
  policy_id = aws_organizations_policy.deny_ec2_terminate.id
  target_id = var.organization_root_id
}
```

This is powerful because it affects member accounts under that root.

Do not use root-level SCPs for initial experimentation.

AWS strongly recommends testing SCPs before attaching them to the
organization root. citeturn1view1

------------------------------------------------------------------------

# 59. Example: Region Restriction

A common advanced requirement is:

> Permit workloads only in approved AWS Regions.

A simplified example is:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnapprovedRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "organizations:*",
        "route53:*",
        "cloudfront:*",
        "support:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "ap-south-1",
            "us-east-1"
          ]
        }
      }
    }
  ]
}
```

This is an advanced example.

Before using such a policy, identify global services and required
exceptions. `NotAction` policies can have a much broader effect than
expected.

------------------------------------------------------------------------

# 60. Example: Prevent Leaving the Organization

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyLeaveOrganization",
      "Effect": "Deny",
      "Action": [
        "organizations:LeaveOrganization"
      ],
      "Resource": "*"
    }
  ]
}
```

This demonstrates how an organization can impose account-level
governance.

------------------------------------------------------------------------

# 61. SCP Evaluation Across OUs

Consider:

``` text
Organization
 |
 +-- Root SCP
 |
 +-- Production OU
      |
      +-- OU SCP
           |
           +-- Account
                |
                +-- Account SCP
```

The account is subject to applicable restrictions inherited through the
hierarchy.

Simplified model:

``` text
Root restrictions
       AND
OU restrictions
       AND
Account restrictions
       AND
IAM permissions
       |
       v
Effective permissions
```

AWS states that a permission blocked at an applicable level cannot be
used even if an administrator attaches `AdministratorAccess` in the
affected member account. citeturn1view1

------------------------------------------------------------------------

# 62. SCP and External Principals

SCPs apply to IAM users and roles managed by member accounts.

They do not directly apply to principals from outside the organization
merely because those principals access a resource owned by an
organization account.

For example:

``` text
Organization Account A
       |
       +-- SCP
       |
       +-- S3 bucket

External Account B
       |
       +-- External principal
```

The SCP in Account A does not directly restrict the external principal
from Account B in the same way it restricts Account A's IAM principals.
Resource policies and other authorization controls still matter.
citeturn1view1

------------------------------------------------------------------------

# 63. SCP Exceptions

AWS documents tasks and entities that are not restricted by SCPs.

Important examples include:

-   Actions performed by the management account.
-   Permissions attached to service-linked roles.
-   Certain AWS-specific tasks.

Always check the current AWS documentation when an SCP appears not to
affect an operation. citeturn1view1

------------------------------------------------------------------------

# 64. Common Troubleshooting

## SCPs are unavailable

Check:

``` bash
aws organizations describe-organization
```

Ensure:

``` text
FeatureSet = ALL
```

------------------------------------------------------------------------

## AccessDenied while creating an SCP

The identity needs appropriate AWS Organizations permissions.

At minimum, AWS documents:

``` text
organizations:CreatePolicy
```

for creating an SCP. citeturn1view2

------------------------------------------------------------------------

## SCP has no effect

Check:

1.  Correct target account.
2.  Correct OU.
3.  Correct principal.
4.  Correct AWS account.
5.  Correct denied action.
6.  Test is not being performed in the management account.
7.  Test is not using a service-linked role.
8.  SCP policy type is enabled.
9.  The SCP is attached at the expected hierarchy level.

------------------------------------------------------------------------

## An SCP caused unexpected denial

Immediately review:

``` bash
aws organizations list-policies-for-target   --target-id ACCOUNT_ID   --filter SERVICE_CONTROL_POLICY
```

Then inspect each applicable SCP.

Also inspect IAM policies and permission boundaries.

------------------------------------------------------------------------

# 65. SCP Best Practices

## Use targeted restrictions

Prefer:

``` text
Deny:
ec2:TerminateInstances
```

over an unnecessarily broad:

``` text
Deny:
ec2:*
```

------------------------------------------------------------------------

## Test in a sandbox

Use:

``` text
Sandbox Account
```

or:

``` text
Sandbox OU
```

first.

------------------------------------------------------------------------

## Document the policy

Record:

``` text
Policy name
Purpose
Owner
Target
Denied actions
Exceptions
Test results
Date
Change history
```

------------------------------------------------------------------------

## Review with Terraform

Use:

``` bash
terraform plan
```

before:

``` bash
terraform apply
```

------------------------------------------------------------------------

## Avoid broad `NotAction`

Understand every service/action affected before using it.

------------------------------------------------------------------------

# 66. Practical Exercise 1

Create:

``` text
DenyEC2TerminateInstances
```

Requirement:

``` text
Student sandbox account must not terminate EC2 instances.
```

Implement using:

``` text
AWS Console
AWS CLI
Terraform
```

Test:

``` bash
aws ec2 terminate-instances   --instance-ids INSTANCE_ID
```

Expected:

``` text
Denied
```

Clean up the SCP after testing.

------------------------------------------------------------------------

# 67. Practical Exercise 2

Create:

``` text
DenyLeaveOrganization
```

Use:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyLeaveOrganization",
      "Effect": "Deny",
      "Action": [
        "organizations:LeaveOrganization"
      ],
      "Resource": "*"
    }
  ]
}
```

Implement it using:

``` text
Console
CLI
Terraform
```

Verify the attachment.

------------------------------------------------------------------------

# 68. Practical Exercise 3

Create an SCP preventing IAM user creation:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyCreateIAMUsers",
      "Effect": "Deny",
      "Action": [
        "iam:CreateUser"
      ],
      "Resource": "*"
    }
  ]
}
```

Test it from a member account where the test principal otherwise has IAM
permissions.

------------------------------------------------------------------------

# 69. Practical Exercise 4: Region Guardrail

Design an SCP that restricts workloads to approved Regions.

Process:

``` text
Identify approved Regions
        |
Identify global services
        |
Identify required exceptions
        |
Create SCP
        |
Test sandbox
        |
Test allowed Region
        |
Test denied Region
```

Do not apply a region-restriction SCP directly to a production root
during learning.

------------------------------------------------------------------------

# 70. Practical Exercise 5: Terraform

Create the SCP with:

``` hcl
resource "aws_organizations_policy" "example" {
  # ...
}

resource "aws_organizations_policy_attachment" "example" {
  # ...
}
```

Run:

``` bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform state list
terraform output
```

Verify:

``` bash
aws organizations list-policies-for-target
```

Then:

``` bash
terraform destroy
```

------------------------------------------------------------------------

# 71. SAA-C03 Exam Points

Remember:

### 1

SCP = organization-level permissions guardrail.

### 2

SCP does **not** grant permissions.

### 3

IAM policies still grant permissions.

### 4

SCP controls maximum available permissions.

### 5

An applicable explicit SCP Deny overrides an IAM Allow.

### 6

SCPs apply to member accounts.

### 7

SCPs do not restrict IAM users and roles in the management account.

### 8

SCPs can be attached to root, OU, or account.

### 9

SCPs require AWS Organizations with all features enabled.

### 10

Test SCPs before broad deployment.

------------------------------------------------------------------------

# 72. Common SAA-C03 Scenario

**Scenario:**

A company has 20 AWS accounts in an organization. Administrators want to
prevent development accounts from using a particular AWS service even if
local IAM administrators grant themselves `AdministratorAccess`.

**Answer:**

``` text
AWS Organizations SCP
```

Reason:

``` text
Central organization guardrail
+
Maximum permission boundary
+
Member-account enforcement
```

------------------------------------------------------------------------

# 73. Another Scenario

**Scenario:**

An IAM role has `AdministratorAccess`, but an SCP explicitly denies
`ec2:TerminateInstances`.

**Result:**

``` text
DENIED
```

The SCP limits the maximum available permissions.

------------------------------------------------------------------------

# 74. Another Scenario

**Scenario:**

A company wants to give a user access to S3.

Should it use only an SCP?

**Answer:**

``` text
No.
```

Use an IAM identity-based policy or appropriate resource-based policy to
grant access.

Use SCPs for organization-level guardrails.

------------------------------------------------------------------------

# 75. Console vs CLI vs Terraform

  Method            Purpose
  ----------------- ----------------------------------------------------
  Console           Learn and visually manage SCPs
  CLI               Automate through AWS Organizations APIs
  Terraform         Manage SCPs as Infrastructure as Code
  Git + Terraform   Version control and review organization guardrails

Recommended learning sequence:

``` text
Console
   |
Understand SCP
   |
CLI
   |
Understand Organizations API operations
   |
Terraform
   |
Automate and version-control SCPs
```

------------------------------------------------------------------------

# 76. Final Student Checklist

You should now be able to explain:

-   [ ] What SCP means.
-   [ ] What AWS Organizations is.
-   [ ] Organization root.
-   [ ] Organizational Unit.
-   [ ] Member account.
-   [ ] Management account.
-   [ ] Maximum available permissions.
-   [ ] IAM policy vs SCP.
-   [ ] Explicit Deny.
-   [ ] FullAWSAccess.
-   [ ] SCP JSON syntax.
-   [ ] `Version`.
-   [ ] `Statement`.
-   [ ] `Sid`.
-   [ ] `Effect`.
-   [ ] `Action`.
-   [ ] `NotAction`.
-   [ ] `Resource`.
-   [ ] `Condition`.
-   [ ] Console implementation.
-   [ ] CLI implementation.
-   [ ] Terraform implementation.
-   [ ] SCP testing.
-   [ ] SCP troubleshooting.
-   [ ] SCP cleanup.
-   [ ] SAA-C03 SCP scenarios.

------------------------------------------------------------------------

# 77. Final Architecture

``` text
                         AWS Organization
                                |
              +-----------------+----------------+
              |                                  |
       Management Account                       Root
              |                                  |
       SCP does not restrict              Applicable SCP
       its IAM users/roles                       |
                                                 |
                                  +--------------+--------------+
                                  |                             |
                              Production OU                  Dev OU
                                  |                             |
                            +-----+-----+                 +-----+-----+
                            |           |                 |           |
                         Account A   Account B          Account C   Account D
                            |           |                 |           |
                            +-----------+-----------------+-----------+
                                        |
                                  Applicable SCPs
                                        |
                                        v
                             Maximum permissions
                                        |
                                       AND
                                        |
                             IAM/resource policies
                                        |
                                        v
                               Effective access
```

------------------------------------------------------------------------

# 78. Official Documentation

## AWS Organizations

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html

## Service Control Policies

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html

## SCP Syntax

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_syntax.html

## Creating Organization Policies

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_policies_create.html

## SCP Examples

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html

## SCP Troubleshooting

https://docs.aws.amazon.com/organizations/latest/userguide/org_troubleshoot_policies.html

## AWS Organizations Concepts

https://docs.aws.amazon.com/organizations/latest/userguide/orgs_getting-started_concepts.html

## Terraform `aws_organizations_policy`

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy

## Terraform `aws_organizations_policy_attachment`

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment

------------------------------------------------------------------------

# 79. Final Summary

The central concept is:

``` text
IAM / Resource Policies
        |
        | Grant permissions
        v
+-----------------------+
|     SCP Guardrail     |
| Maximum Permissions   |
+-----------------------+
        |
        v
Effective Access
```

Remember:

``` text
IAM policy
    =
What the principal is granted

SCP
    =
Maximum permissions allowed by the organization

Effective access
    =
Permissions that survive both controls
```

For practical learning, implement the same SCP three ways:

``` text
AWS Console
      |
      v
AWS CLI
      |
      v
Terraform
```

Then test the denied operation from a **member account**, verify the SCP
attachment, and remove the SCP after the lab.

AWS recommends thorough testing before applying SCPs broadly,
particularly at the organization root. citeturn1view1

------------------------------------------------------------------------

# End of Student Documentation
