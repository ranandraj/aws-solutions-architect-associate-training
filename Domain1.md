# AWS Certified Solutions Architect Associate
## SAA-C03 Domain 1: Design Secure Architectures
### Student Training Material + Step-by-Step Hands-On Guide

This module is designed as a self-learning and practical lab manual. Each section explains the concept first and then gives you steps to implement it in AWS.

AWS's current SAA-C03 exam guide places **Design Secure Architectures** at 30% of the scored content. The domain covers secure access, secure workloads and applications, and appropriate data security controls.

> **Important:** AWS services can incur charges. Where possible, use the AWS Free Tier and delete resources immediately after completing a lab. NAT Gateway, RDS, load balancers, CloudFront and some security services can incur charges.

---

# 1. AWS Shared Responsibility Model

## 1.1 What is the Shared Responsibility Model?

When you use AWS, security is shared between **AWS and you**.

AWS is responsible for protecting the infrastructure that runs AWS services.

You are responsible for configuring and protecting your workloads and data.

The exact responsibility depends on the service.

### AWS responsibility

AWS manages:

- Physical data centers
- Physical servers
- Physical storage
- Physical networking
- AWS Regions
- Availability Zones
- Hypervisor infrastructure
- Physical access controls

### Your responsibility

You may manage:

- IAM
- Operating systems
- Applications
- Security groups
- Network configuration
- Data
- Encryption configuration
- Application credentials
- Access permissions
- Patching

For EC2:

```text
AWS
├── Data center
├── Physical servers
├── Networking
└── Hypervisor

You
├── Operating system
├── Applications
├── Security configuration
├── Patching
└── Data
```

For S3, you do not manage the underlying operating system or physical storage. You are responsible for your bucket configuration, permissions and data.

## 1.2 Practical Exercise

Open the AWS console.

Create an EC2 instance.

After connecting to it, install a package:

```bash
sudo apt update
sudo apt install nginx -y
```

You are responsible for this operating system and software configuration.

AWS is responsible for the underlying EC2 infrastructure.

## AWS Documentation

- [AWS Shared Responsibility Model](https://aws.amazon.com/compliance/shared-responsibility-model/)
- [AWS Shared Responsibility Model Documentation](https://docs.aws.amazon.com/whitepapers/latest/aws-risk-and-compliance/shared-responsibility-model.html)

---

# 2. AWS Identity and Access Management, IAM

## 2.1 What is IAM?

IAM controls access to AWS resources.

IAM answers two questions:

### Authentication

Who are you?

### Authorization

What are you allowed to do?

For example:

```text
User
  |
  | Login
  ↓
Authentication
  |
  ↓
IAM permissions
  |
  ↓
Authorization
  |
  ↓
S3
```

IAM provides:

- Users
- Groups
- Roles
- Policies
- Permissions
- MFA

## 2.2 IAM Security Principle

Use **least privilege**.

If an application only needs to read an S3 bucket, it should not receive administrator permissions.

Bad:

```text
AdministratorAccess
```

Better:

```text
s3:GetObject
```

for the required bucket.

## AWS Documentation

- [AWS IAM Documentation](https://docs.aws.amazon.com/iam/)

---

# 3. IAM Users

## 3.1 What is an IAM User?

An IAM user represents an identity within an AWS account.

An IAM user can have:

- Console password
- Access keys
- MFA
- Group membership
- Permissions

For example:

```text
IAM User
   |
   +-- Password
   +-- MFA
   +-- Access Keys
   +-- Groups
   +-- Policies
```

For workforce access, AWS recommends using centralized access mechanisms such as IAM Identity Center where appropriate instead of creating long-lived IAM credentials for every person.

## 3.2 Create an IAM User

### Step 1

Sign in to the AWS Management Console.

Open:

**IAM**

### Step 2

Select:

**Users**

### Step 3

Select:

**Create user**

Enter:

```text
Username:
student-user
```

### Step 4

Configure console access if required for the lab.

### Step 5

Create the user.

Initially, don't give unnecessary permissions.

## 3.3 Test the User

Sign in using the new identity.

Try opening S3.

Without appropriate permissions, AWS should deny operations that the identity is not authorized to perform.

This demonstrates:

```text
Identity
   ↓
Authentication succeeds
   ↓
Authorization fails
```

## AWS Documentation

- [IAM Users](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html)

---

# 4. IAM Groups

## 4.1 What is an IAM Group?

A group is a collection of IAM users.

Suppose five developers need the same permissions.

Instead of:

```text
User1 → Policy
User2 → Policy
User3 → Policy
User4 → Policy
User5 → Policy
```

use:

```text
Developers Group
       |
       +-- User1
       +-- User2
       +-- User3
       +-- User4
       +-- User5
       |
       ↓
Developer Policy
```

This makes permission management easier.

## 4.2 Create a Group

Go to:

**IAM → User groups → Create group**

Enter:

```text
Group name:
Developers
```

Attach an appropriate policy for the lab.

Add:

```text
student-user
```

to the group.

## 4.3 Test

Log in as the user.

Check whether the permissions provided by the group are available.

Remove the user from the group.

Test again.

The user's permissions should change.

## AWS Documentation

- [IAM User Groups](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_groups.html)

---

# 5. IAM Policies

## 5.1 What is an IAM Policy?

A policy defines what actions are allowed or denied.

Policies are normally written in JSON.

Example:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::training-bucket/*"
    }
  ]
}
```

## 5.2 Understand the Policy

### Version

```text
"Version": "2012-10-17"
```

Defines the policy language version.

### Effect

```text
Allow
Deny
```

### Action

Specifies the AWS API operation.

Example:

```text
s3:GetObject
```

### Resource

Specifies the resource.

```text
arn:aws:s3:::training-bucket/*
```

### Condition

Allows additional restrictions.

For example:

- Source IP
- MFA
- Region
- Tags
- Time conditions

## 5.3 Create a Custom Policy

Go to:

**IAM → Policies → Create policy**

Choose the JSON editor.

Enter:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    }
  ]
}
```

Give it a name:

```text
TrainingS3ListPolicy
```

Create the policy.

Attach it to the test user.

## 5.4 Test

Using the AWS CLI:

```bash
aws sts get-caller-identity
```

Then:

```bash
aws s3 ls
```

Try an operation that was not allowed.

For example:

```bash
aws ec2 describe-instances
```

You should receive an authorization error if no EC2 permission exists.

## AWS Documentation

- [Policies and Permissions in IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)

---

# 6. Identity-Based Policies

Identity-based policies are attached to:

- Users
- Groups
- Roles

Example:

```text
IAM User
   ↓
Identity Policy
   ↓
S3 permissions
```

The policy determines what that identity can do.

## Practical Exercise

Create a role or user with:

```text
s3:GetObject
```

only.

Try:

```bash
aws s3 cp s3://bucket/file.txt .
```

It should work.

Try deleting the object:

```bash
aws s3 rm s3://bucket/file.txt
```

It should fail if `s3:DeleteObject` isn't allowed.

This is a practical demonstration of least privilege.

## AWS Documentation

- [Identity-based Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html)

---

# 7. Resource-Based Policies

A resource-based policy is attached to the resource.

Examples:

- S3 bucket policy
- SQS queue policy
- SNS topic policy
- KMS key policy

For S3:

```text
User/Role
    |
    ↓
S3 Bucket Policy
    |
    ↓
S3 Bucket
```

## 7.1 Create an S3 Bucket

Go to:

**S3 → Create bucket**

Use a globally unique name such as:

```text
arinfotek-saa-training-12345
```

Keep public access blocked.

Create the bucket.

## 7.2 Upload a File

Create:

```text
hello.txt
```

containing:

```text
AWS SAA Domain 1
```

Upload it.

## 7.3 Study Bucket Policy

Open:

**Permissions → Bucket policy**

A resource-based policy can control access to the bucket.

For example, it can grant access to a particular role or account.

### Important

Never make your training bucket public unless a specific lab requires it and you understand the security implications.

## AWS Documentation

- [Identity-Based and Resource-Based Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html)
- [Amazon S3 Bucket Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-policies.html)

---

# 8. IAM Roles

IAM roles are essential for AWS architecture.

A role provides temporary credentials.

Example:

```text
EC2
 |
 | assumes
 ↓
IAM Role
 |
 ↓
S3
```

Instead of putting AWS access keys inside an application:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

the application can use an IAM role.

## 8.1 EC2 → S3 Role Lab

### Step 1

Create an S3 bucket.

Upload:

```text
test.txt
```

### Step 2

Go to:

**IAM → Roles → Create role**

### Step 3

Select:

```text
Trusted entity:
AWS service
```

Choose:

```text
EC2
```

### Step 4

Attach a policy that provides only the S3 permissions needed for this lab.

For example:

```text
s3:ListBucket
s3:GetObject
```

### Step 5

Name the role:

```text
EC2S3ReadRole
```

Create it.

### Step 6

Launch an EC2 instance.

During instance configuration:

**IAM instance profile**

select:

```text
EC2S3ReadRole
```

### Step 7

Connect to EC2.

Run:

```bash
aws sts get-caller-identity
```

You should see the role identity.

Then:

```bash
aws s3 ls
```

Then:

```bash
aws s3 cp s3://YOUR-BUCKET/test.txt .
```

The instance can access S3 without storing permanent AWS access keys.

## AWS Documentation

- [IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
- [IAM Role Concepts](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html)

---

# 9. Trust Policy and Permission Policy

An IAM role has two important policy concepts.

## Trust policy

Answers:

> Who can assume this role?

Example:

```text
EC2 service
       ↓
Can assume role
```

## Permissions policy

Answers:

> What can the role do?

Example:

```text
Role
 ↓
s3:GetObject
```

So:

```text
Trust Policy
     ↓
Who can use the role?

Permissions Policy
     ↓
What can the role do?
```

This distinction is very important in SAA-C03 questions.

## AWS Documentation

- [IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)

---

# 10. IAM Policy Evaluation

Suppose you have:

```text
Policy 1:
Allow s3:GetObject

Policy 2:
Deny s3:GetObject
```

The explicit deny wins.

Simplified:

```text
Request
   ↓
Policy evaluation
   ↓
Explicit Deny?
   |
   +-- YES → DENY
   |
   +-- NO
        ↓
      Allow?
        |
        +-- YES → ALLOW
        |
        +-- NO → DENY
```

## Practical Exercise

Create an IAM policy allowing:

```text
s3:GetObject
```

Test it.

Then create another policy denying:

```text
s3:GetObject
```

Test again.

Observe that the explicit deny overrides the allow.

## AWS Documentation

- [IAM Policy Evaluation Logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)

---

# 11. Least Privilege

Least privilege means giving only the permissions required.

Suppose your application only downloads reports.

Required:

```text
s3:GetObject
```

Not required:

```text
s3:DeleteObject
s3:PutObject
s3:PutBucketPolicy
iam:CreateUser
ec2:TerminateInstances
```

## Practical Exercise

Create two policies.

### Policy A

```json
{
  "Effect": "Allow",
  "Action": "s3:*",
  "Resource": "*"
}
```

### Policy B

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject"
  ],
  "Resource": "arn:aws:s3:::training-bucket/reports/*"
}
```

Compare the permissions.

Policy B follows least privilege much more closely.

## AWS Documentation

- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

# 12. Multi-Factor Authentication, MFA

MFA adds an additional authentication factor.

Typical authentication:

```text
Password
```

MFA:

```text
Password
+
MFA factor
```

AWS supports MFA mechanisms such as:

- Virtual MFA
- Security keys
- Hardware MFA
- Passkeys

## Practical Exercise

Secure your AWS root user with MFA.

Then configure MFA for the appropriate administrative identity.

Do not use the root account for ordinary daily administration.

## AWS Documentation

- [AWS MFA Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html)

---

# 13. IAM Identity Center

IAM Identity Center is designed for workforce access to AWS accounts and applications.

Architecture:

```text
Employees
    |
    ↓
IAM Identity Center
    |
    +------ AWS Account A
    |
    +------ AWS Account B
    |
    +------ AWS Account C
```

Instead of maintaining separate IAM users in every AWS account, centralized identities can receive access through **permission sets**.

## 13.1 Create IAM Identity Center

Open:

**IAM Identity Center**

Enable it according to the AWS console instructions.

Create a group:

```text
Developers
```

Create users and add them to the group.

## 13.2 Create Permission Set

Create:

```text
DeveloperAccess
```

Attach appropriate permissions.

Assign:

```text
Developers
       ↓
DeveloperAccess
       ↓
Development AWS Account
```

## AWS Documentation

- [IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)

---

# 14. AWS Organizations

Organizations allows you to manage multiple AWS accounts centrally.

Example:

```text
Organization
│
├── Security OU
│   └── Security Account
│
├── Production OU
│   └── Production Account
│
└── Development OU
    ├── Dev Account
    └── Test Account
```

Benefits include:

- Centralized account management
- Consolidated billing
- Organizational Units
- Service Control Policies
- Central governance

## Practical Exercise

If your AWS account supports Organizations:

Open:

**AWS Organizations**

Create an organization.

Create:

```text
Development
Production
Security
```

organizational units.

Study how accounts can be organized.

## AWS Documentation

- [AWS Organizations](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html)

---

# 15. Service Control Policies, SCP

An SCP controls the maximum permissions available within an AWS Organizations hierarchy.

An SCP **does not grant permissions**.

Example:

```text
IAM Policy
   ↓
Allow EC2 termination

SCP
   ↓
Deny EC2 termination

Result
   ↓
DENIED
```

## Practical Exercise

If you have a multi-account organization, create a development OU.

Create an SCP that denies:

```text
ec2:TerminateInstances
```

Attach it to the OU.

Test from the member account.

### Important

Do not attach restrictive SCPs to your production environment without understanding the impact. A badly designed SCP can block required administrative operations.

## AWS Documentation

- [Service Control Policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)

---

# 16. Cross-Account Access

Cross-account access allows an identity in one AWS account to access resources in another account.

Example:

```text
Account A
Developer
   |
   | AssumeRole
   ↓
Account B
ProductionReadOnlyRole
   |
   ↓
Production resources
```

The role in Account B has a trust policy that allows the appropriate principal from Account A to assume it.

## Practical Exercise

If two AWS accounts are available:

### Account B

Create:

```text
ProductionReadOnlyRole
```

Configure its trust relationship for Account A.

Attach a read-only policy.

### Account A

Allow the appropriate identity to perform:

```text
sts:AssumeRole
```

Then use:

```bash
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT-B-ID:role/ProductionReadOnlyRole \
  --role-session-name training-session
```

Study the temporary credentials returned by STS.

## AWS Documentation

- [AWS Cross-Account IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html)

---

# 17. IAM Access Analyzer

Access Analyzer helps identify unintended resource access.

It can identify resources accessible by:

- External AWS accounts
- Public principals
- Other external identities

It also provides capabilities related to policy validation and unused permissions.

## Practical Exercise

Open:

**IAM → Access Analyzer**

Create an analyzer.

Review findings.

For example, if an S3 bucket is unintentionally shared externally, Access Analyzer can identify the external access.

Fix the bucket policy.

Recheck the analyzer.

## AWS Documentation

- [IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html)

---

# 18. AWS Key Management Service, KMS

KMS manages cryptographic keys.

Common AWS services that integrate with KMS include:

- S3
- EBS
- RDS
- Secrets Manager
- Lambda
- CloudTrail

Basic concept:

```text
Data
 ↓
Encryption
 ↓
Encrypted Data
```

KMS manages the keys used for cryptographic operations.

## 18.1 KMS Key Types

Understand:

### AWS owned keys

Managed by AWS and used by services.

### AWS managed keys

Created and managed by AWS for your account.

### Customer managed keys

You create and manage them.

Customer managed keys provide greater control over:

- Key policies
- Permissions
- Rotation settings
- Lifecycle

## 18.2 Create a KMS Key

Open:

**KMS → Customer managed keys**

Select:

**Create key**

Choose:

```text
Symmetric
```

Add an alias:

```text
alias/saa-training
```

Complete the wizard.

## 18.3 Encrypt an S3 Object

Create an S3 bucket.

Go to:

**Properties → Default encryption**

Select:

```text
SSE-KMS
```

Select your KMS key.

Upload:

```text
secret.txt
```

Open the object's properties.

Check the encryption information.

## 18.4 Test Permission

Remove the required KMS permission from the identity.

Try to access the encrypted object.

You can now observe how both:

```text
S3 permissions
+
KMS permissions
```

can matter when using SSE-KMS.

## AWS Documentation

- [AWS KMS Concepts](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html)
- [KMS Key Policies](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html)

---

# 19. AWS Secrets Manager

Secrets Manager is designed to store sensitive information.

Examples:

```text
Database password
API key
OAuth token
Application credential
```

Instead of:

```text
const password = "MyPassword123";
```

use:

```text
Application
    ↓
Secrets Manager
    ↓
Secret
```

## 19.1 Create a Secret

Open:

**Secrets Manager → Store a new secret**

For training, create a secret containing a sample application credential.

Name:

```text
training/database
```

## 19.2 Retrieve with CLI

After configuring the required IAM permission:

```bash
aws secretsmanager get-secret-value \
  --secret-id training/database
```

The application can retrieve the secret when it has permission.

## 19.3 Secret Rotation

Secrets Manager supports rotation for supported use cases.

The goal is:

```text
Old credential
     ↓
Rotation
     ↓
New credential
```

This reduces dependence on permanent credentials.

## AWS Documentation

- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [Secrets Manager Rotation](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html)

---

# 20. Systems Manager Parameter Store

Parameter Store stores application configuration.

Example:

```text
/app/dev/database/host
/app/dev/database/port
/app/dev/database/name
/app/prod/database/host
```

Parameter types include:

```text
String
StringList
SecureString
```

## Practical Exercise

Open:

**Systems Manager → Parameter Store**

Create:

```text
/myapp/dev/database/host
```

Value:

```text
database.example.internal
```

Create:

```text
/myapp/dev/database/port
```

Value:

```text
5432
```

Create:

```text
/myapp/dev/database/password
```

as:

```text
SecureString
```

## Retrieve

```bash
aws ssm get-parameter \
  --name "/myapp/dev/database/host"
```

For encrypted values:

```bash
aws ssm get-parameter \
  --name "/myapp/dev/database/password" \
  --with-decryption
```

## AWS Documentation

- [Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)

---

# 21. Secrets Manager vs Parameter Store

| Requirement | Recommended service |
|---|---|
| Application configuration | Parameter Store |
| Database password | Secrets Manager |
| API secret | Secrets Manager |
| Simple configuration string | Parameter Store |
| SecureString configuration | Parameter Store |
| Automatic secret rotation | Secrets Manager |
| Central configuration hierarchy | Parameter Store |

These services can also be used together.

---

# 22. Amazon Cognito

Cognito is used primarily for **application user authentication and identity**.

This is different from IAM.

```text
IAM
 ↓
AWS resource access

Cognito
 ↓
Application user authentication
```

Cognito has two major concepts:

```text
Cognito
├── User Pools
└── Identity Pools
```

## User Pool

A user pool provides an application user directory and authentication capabilities.

Example:

```text
Web Application
      ↓
Cognito User Pool
      ↓
Login
      ↓
Token
```

## Identity Pool

An identity pool can provide temporary AWS credentials to application users.

Example:

```text
Mobile App
    ↓
Cognito
    ↓
Identity Pool
    ↓
Temporary AWS credentials
    ↓
S3
```

## Practical Exercise

Open:

**Amazon Cognito**

Create a User Pool.

Configure:

```text
Username/email sign-in
Password policy
MFA settings
```

Create a test user.

Complete the sign-in flow.

Study the authentication tokens produced by the user pool.

## AWS Documentation

- [Amazon Cognito](https://docs.aws.amazon.com/cognito/latest/developerguide/what-is-amazon-cognito.html)
- [Cognito User Pools](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools.html)
- [Cognito Identity Pools](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-identity.html)

---

# 23. VPC Security Fundamentals

A VPC is your logical network inside AWS.

Basic architecture:

```text
VPC
10.0.0.0/16
│
├── Public Subnet
│
└── Private Subnet
```

A secure application commonly separates:

```text
Internet-facing components
        ↓
Public subnet

Application
        ↓
Private subnet

Database
        ↓
Private subnet
```

---

# 24. Security Groups

Security Groups act as stateful virtual firewalls.

Example:

```text
Internet
   |
   | HTTPS 443
   ↓
ALB
   |
   | TCP 8080
   ↓
Application
   |
   | TCP 5432
   ↓
Database
```

Create:

```text
ALB-SG
APP-SG
DB-SG
```

## ALB-SG

Allow:

```text
TCP 443
Source: Internet
```

## APP-SG

Allow:

```text
TCP 8080
Source: ALB-SG
```

## DB-SG

Allow:

```text
TCP 5432
Source: APP-SG
```

This is preferable to allowing:

```text
5432 from 0.0.0.0/0
```

## Practical Exercise

Create three security groups.

Don't open database ports to the internet.

Launch an EC2 instance using `APP-SG`.

Create another test resource using `DB-SG`.

Test the permitted and denied connections.

## AWS Documentation

- [VPC Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)

---

# 25. Network ACLs

Network ACLs operate at the **subnet level**.

They are:

- Stateless
- Ordered
- Associated with subnets
- Capable of Allow and Deny rules

Example:

```text
VPC
 |
 Subnet
 |
 NACL
 |
 +-- Rule 100 Allow
 +-- Rule 110 Deny
 +-- Rule 120 Allow
```

## Security Group vs NACL

| Security Group | NACL |
|---|---|
| Resource level | Subnet level |
| Stateful | Stateless |
| Allow rules | Allow + Deny |
| No rule ordering | Rule numbers |
| Return traffic automatically handled | Return traffic must be allowed |

## Practical Exercise

Create a custom NACL.

Add an inbound rule:

```text
Rule: 100
Protocol: TCP
Port: 80
Source: appropriate test CIDR
Allow
```

Add an explicit deny for a test source where appropriate.

Test the behavior.

Remember that because NACLs are stateless, both directions of traffic may need appropriate rules.

## AWS Documentation

- [Network ACLs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)

---

# 26. VPC Endpoints

VPC endpoints provide private connectivity between VPC resources and supported AWS services.

Example:

```text
Private EC2
     |
     ↓
VPC Endpoint
     |
     ↓
S3
```

This is useful when private workloads need AWS services without relying on the public internet path.

## Gateway Endpoint

Commonly used for:

```text
S3
DynamoDB
```

## Interface Endpoint

Uses AWS PrivateLink and creates network interfaces in your subnets.

Common examples include:

```text
Secrets Manager
Systems Manager
CloudWatch
```

## Practical Lab

Create:

```text
Private EC2
```

with no public IP.

Create an S3 Gateway Endpoint.

Configure the route table.

From EC2:

```bash
aws s3 ls
```

Test S3 access.

The purpose of this lab is to understand private AWS service connectivity.

## AWS Documentation

- [AWS PrivateLink and VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/concepts.html)
- [Amazon S3 Gateway Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-s3.html)

---

# 27. AWS WAF

AWS WAF is a web application firewall.

It examines HTTP/HTTPS requests.

Architecture:

```text
Internet
   ↓
CloudFront / ALB / API Gateway
   ↓
AWS WAF
   ↓
Application
```

WAF can use rules based on:

- IP address
- HTTP headers
- URI
- Query strings
- Geographic location
- Request rate
- Managed rule groups

Actions include:

- Allow
- Block
- Count
- CAPTCHA
- Challenge

## Practical Lab

Create a Web ACL.

Add a rate-based rule.

Associate it with an appropriate supported application resource.

Test your application normally.

Review WAF metrics and sampled requests where available.

## AWS Documentation

- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/latest/developerguide/what-is-aws-waf.html)
- [How AWS WAF Works](https://docs.aws.amazon.com/waf/latest/developerguide/how-aws-waf-works.html)

---

# 28. AWS Shield

AWS Shield provides DDoS protection.

There are two primary protection levels:

```text
Shield Standard
Shield Advanced
```

Shield Standard provides automatic baseline DDoS protection.

Shield Advanced provides additional capabilities for more sophisticated protection and visibility.

## WAF vs Shield

```text
WAF
 ↓
Web request filtering

Shield
 ↓
DDoS protection
```

They can be used together.

## AWS Documentation

- [AWS Shield](https://docs.aws.amazon.com/shield/latest/developerguide/what-is-aws-shield.html)

---

# 29. Amazon GuardDuty

GuardDuty is a threat detection service.

It looks for suspicious activity using supported AWS data sources and threat intelligence.

Examples:

- Compromised credentials
- Suspicious API calls
- Cryptocurrency mining
- Malware
- Unusual network behavior

Architecture:

```text
AWS Environment
       ↓
GuardDuty
       ↓
Finding
       ↓
Security response
```

## Practical Lab

Open:

**Amazon GuardDuty**

Enable it according to the console workflow.

Explore:

```text
Findings
Malware protection
Account protection
S3 protection
```

Use the official sample findings mechanism when you want to practice investigating a finding without generating real malicious activity.

## AWS Documentation

- [Amazon GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html)

---

# 30. AWS Security Hub

Security Hub provides a centralized view of security findings and security posture.

It can receive findings from AWS security services and supported integrations.

Example:

```text
GuardDuty
    |
Inspector
    |
Macie
    |
Other sources
    |
    ↓
Security Hub
    ↓
Central security findings
```

## Practical Lab

Open:

**Security Hub**

Enable it.

Review:

- Security standards
- Controls
- Findings
- Security score

If GuardDuty is enabled, review how findings can appear in Security Hub.

## AWS Documentation

- [AWS Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html)

---

# 31. AWS CloudTrail

CloudTrail records AWS API activity.

It helps answer:

```text
Who?
What?
When?
Where?
Which API?
Which resource?
```

Example:

```text
Administrator
     ↓
Delete S3 bucket
     ↓
CloudTrail
     ↓
Event
```

CloudTrail supports event categories including management events and data events.

## Practical Lab

Open:

**CloudTrail → Event history**

Perform:

```text
Create S3 bucket
Upload object
Delete object
```

Return to CloudTrail.

Search the event history.

Inspect:

```text
Event name
User identity
Event time
Source IP
AWS Region
Resource
```

## AWS Documentation

- [AWS CloudTrail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html)
- [CloudTrail Concepts](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html)

---

# 32. Amazon CloudWatch

CloudWatch is used for monitoring and observability.

It provides:

- Metrics
- Logs
- Alarms
- Dashboards

Example:

```text
EC2
 ↓
CPU Metric
 ↓
CloudWatch
 ↓
Alarm
 ↓
Action
```

## Practical Lab

Launch EC2.

Open:

**CloudWatch → Metrics → EC2**

Find:

```text
CPUUtilization
```

Create an alarm.

Example:

```text
CPUUtilization > 70%
```

for a defined evaluation period.

Add an appropriate notification or action.

## CloudWatch Logs

Install/configure the CloudWatch agent where required.

Send application logs to:

```text
CloudWatch Logs
```

Study:

```text
Log Group
Log Stream
Log Events
```

## AWS Documentation

- [Amazon CloudWatch Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)

---

# 33. CloudWatch vs CloudTrail

This is an important SAA-C03 distinction.

| CloudWatch | CloudTrail |
|---|---|
| Monitoring | Auditing |
| Metrics | API events |
| Logs | Account activity |
| Alarms | User/API investigation |
| Performance | Governance/security |

Example:

### Question

> EC2 CPU utilization has reached 95%.

Use:

**CloudWatch**

### Question

> Who terminated the EC2 instance?

Use:

**CloudTrail**

---

# 34. Encryption at Rest

Encryption at rest protects stored data.

Examples:

```text
S3 → Encryption
EBS → Encryption
RDS → Encryption
Secrets Manager → Encryption
```

Example:

```text
Plaintext
   ↓
Encryption
   ↓
Encrypted storage
```

KMS is commonly involved in customer-controlled encryption-key management.

## Practical Lab

Create an S3 bucket.

Enable:

```text
SSE-KMS
```

Upload a file.

Check:

```text
Object → Properties → Server-side encryption
```

Confirm that the object is encrypted using the configured key.

---

# 35. Encryption in Transit

Encryption in transit protects data while it moves between systems.

Common technology:

```text
TLS
HTTPS
```

Example:

```text
Browser
   |
 HTTPS
   ↓
ALB
   |
 HTTPS
   ↓
Application
```

AWS Certificate Manager, or ACM, can provide certificates for supported AWS services.

## Practical Lab

If you have a domain:

1. Open ACM.
2. Request a public certificate.
3. Enter your domain.
4. Complete DNS validation.
5. Create an ALB.
6. Configure an HTTPS listener.
7. Attach the certificate.
8. Test the HTTPS endpoint.

---

# 36. Data Protection with S3 Versioning

S3 Versioning maintains multiple versions of an object.

Example:

```text
report.txt
   ↓
Version 1

report.txt
   ↓
Version 2

report.txt
   ↓
Version 3
```

If an object is accidentally overwritten or deleted, an earlier version may be recoverable.

## Practical Lab

Create an S3 bucket.

Open:

**Properties → Bucket Versioning**

Enable it.

Upload:

```text
report.txt
```

Modify the file.

Upload it again.

Delete the current object.

Open:

**Show versions**

Observe the previous versions.

Restore the required version.

## AWS Documentation

- [S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)

---

# 37. S3 Lifecycle Policies

Lifecycle policies automatically transition or delete objects based on rules.

Example:

```text
Day 0
S3 Standard

Day 30
Different storage class

Day 90
Archive

Day 365
Delete
```

This is useful for managing data retention and storage cost.

## Practical Lab

Create an S3 lifecycle rule.

For training, use a short test period only where the service permits it.

Configure a rule targeting a test prefix such as:

```text
training/
```

Study:

- Transition actions
- Expiration
- Noncurrent versions

Do not apply aggressive deletion rules to important data.

## AWS Documentation

- [S3 Lifecycle Management](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)

---

# 38. Secure Three-Tier Application

Now combine the concepts.

Architecture:

```text
                         INTERNET
                            |
                            ↓
                         Route 53
                            |
                            ↓
                       CloudFront
                            |
                            ↓
                          WAF
                            |
                            ↓
                           ALB
                            |
              +-------------+-------------+
              |                           |
             EC2                         EC2
              |                           |
              +-------------+-------------+
                            |
                            ↓
                       Private Subnet
                            |
                            ↓
                           RDS
```

Security:

```text
IAM
 ↓
Roles and policies

KMS
 ↓
Encryption

Secrets Manager
 ↓
Database credentials

Security Groups
 ↓
Network access

NACL
 ↓
Subnet control

VPC Endpoint
 ↓
Private AWS service access

CloudTrail
 ↓
Audit

CloudWatch
 ↓
Monitoring

GuardDuty
 ↓
Threat detection

Security Hub
 ↓
Security findings
```

---

# 39. Complete Practical Project

## Step 1: Create the VPC

CIDR:

```text
10.0.0.0/16
```

Create four subnets:

```text
Public-A
10.0.1.0/24

Public-B
10.0.2.0/24

Private-A
10.0.11.0/24

Private-B
10.0.12.0/24
```

Use two Availability Zones.

---

# Step 2: Internet Gateway

Create:

```text
Internet Gateway
```

Attach it to the VPC.

Configure the public route table:

```text
Destination:
0.0.0.0/0

Target:
Internet Gateway
```

---

# Step 3: Security Groups

Create:

```text
ALB-SG
APP-SG
DB-SG
```

Configure:

```text
ALB-SG
HTTPS 443
Source: Internet
```

```text
APP-SG
Application port
Source: ALB-SG
```

```text
DB-SG
Database port
Source: APP-SG
```

---

# Step 4: Application EC2

Launch two EC2 instances into private subnets if you have the required networking configured.

Attach:

```text
ApplicationEC2Role
```

Do not store AWS access keys inside the application.

---

# Step 5: RDS

Create an RDS database in private subnets.

Use:

```text
DB-SG
```

Do not expose the database directly to the internet.

---

# Step 6: Secrets Manager

Store the database credentials in:

```text
Secrets Manager
```

Example secret:

```text
production/database
```

Allow the application role to retrieve only the required secret.

---

# Step 7: KMS

Create a customer managed KMS key.

Use it for appropriate encryption requirements such as:

```text
S3
RDS
Secrets Manager
```

where applicable.

---

# Step 8: ALB

Create an Application Load Balancer.

Place it in:

```text
Public-A
Public-B
```

Attach:

```text
ALB-SG
```

Register the application instances as targets.

---

# Step 9: WAF

Create a Web ACL.

Add:

```text
Managed rule group
Rate-based rule
```

Associate the Web ACL with the appropriate supported application resource.

---

# Step 10: CloudWatch

Monitor:

```text
EC2
ALB
RDS
Application logs
```

Create alarms for important metrics.

---

# Step 11: CloudTrail

Enable appropriate CloudTrail logging.

Review events generated when:

```text
S3 bucket created
EC2 launched
Security group changed
IAM policy changed
```

---

# Step 12: GuardDuty

Enable GuardDuty.

Review the security findings interface.

Use sample findings for controlled practice.

---

# Step 13: Security Hub

Enable Security Hub.

Review security controls and findings.

---

# Step 14: IAM Access Analyzer

Review:

```text
External access
Public access
Policy issues
Unused access
```

Fix unnecessary permissions.

---

# 40. Final Domain 1 Practice Checklist

Before moving to Domain 2, you should be able to perform the following tasks.

### IAM

- [ ] Create an IAM user
- [ ] Create an IAM group
- [ ] Attach a policy
- [ ] Write a basic JSON policy
- [ ] Explain Allow and Deny
- [ ] Explain explicit Deny
- [ ] Create an IAM role
- [ ] Attach an EC2 role
- [ ] Explain a trust policy
- [ ] Explain a permissions policy
- [ ] Implement least privilege
- [ ] Configure MFA

### Identity and Governance

- [ ] Explain IAM Identity Center
- [ ] Create a permission set
- [ ] Explain AWS Organizations
- [ ] Explain OUs
- [ ] Explain SCPs
- [ ] Explain cross-account roles
- [ ] Use IAM Access Analyzer

### Data Security

- [ ] Create a KMS key
- [ ] Encrypt S3 data with KMS
- [ ] Explain KMS key policies
- [ ] Create a Secrets Manager secret
- [ ] Retrieve a secret
- [ ] Create Parameter Store parameters
- [ ] Use SecureString
- [ ] Explain Cognito User Pools
- [ ] Explain Cognito Identity Pools
- [ ] Enable S3 Versioning
- [ ] Create an S3 lifecycle rule

### Network Security

- [ ] Create a VPC
- [ ] Create public/private subnets
- [ ] Configure route tables
- [ ] Configure security groups
- [ ] Configure NACLs
- [ ] Explain stateful vs stateless
- [ ] Create an S3 VPC endpoint
- [ ] Explain Gateway vs Interface endpoints

### Security Services

- [ ] Configure WAF
- [ ] Explain Shield
- [ ] Enable GuardDuty
- [ ] Review GuardDuty findings
- [ ] Enable Security Hub
- [ ] Review security findings
- [ ] Configure CloudTrail
- [ ] Find API events
- [ ] Configure CloudWatch metrics
- [ ] Create CloudWatch alarms

---

# 41. SAA-C03 Domain 1 Service Selection Cheat Sheet

| Requirement in a scenario | AWS service/concept |
|---|---|
| Manage AWS identities | IAM |
| Centralize employee AWS access | IAM Identity Center |
| Application needs AWS permissions | IAM Role |
| Multiple users need same permissions | IAM Group |
| Control maximum permissions across accounts | SCP |
| Manage multiple AWS accounts | AWS Organizations |
| Cross-account access | IAM Role / resource policy |
| Find unintended external access | IAM Access Analyzer |
| Encrypt data | KMS |
| Store passwords/API secrets | Secrets Manager |
| Store application configuration | Parameter Store |
| Application user authentication | Cognito |
| Web request filtering | AWS WAF |
| DDoS protection | AWS Shield |
| Threat detection | GuardDuty |
| Centralize security findings | Security Hub |
| API activity auditing | CloudTrail |
| Metrics/logs/alarms | CloudWatch |
| Instance-level firewall | Security Group |
| Subnet-level firewall | Network ACL |
| Private access to supported AWS services | VPC Endpoint |
| Object recovery | S3 Versioning |
| Automated data transitions | S3 Lifecycle |
| Data encryption at rest | KMS/S3/EBS/RDS encryption |
| Data encryption in transit | TLS/HTTPS/ACM |

---

# 42. Official AWS Documentation Collection

Use these as your primary references while completing the labs.

### IAM and Identity

- [AWS IAM](https://docs.aws.amazon.com/iam/)
- [IAM Users](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html)
- [IAM Groups](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_groups.html)
- [IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
- [IAM Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
- [Policy Evaluation Logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

### Governance

- [IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)
- [AWS Organizations](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html)
- [Service Control Policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
- [IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html)

### Encryption and Secrets

- [AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html)
- [KMS Key Policies](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [Amazon Cognito](https://docs.aws.amazon.com/cognito/latest/developerguide/what-is-amazon-cognito.html)

### Network Security

- [Amazon VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)
- [Network ACLs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)
- [VPC Endpoints and PrivateLink](https://docs.aws.amazon.com/vpc/latest/privatelink/concepts.html)

### Security Monitoring

- [AWS WAF](https://docs.aws.amazon.com/waf/latest/developerguide/what-is-aws-waf.html)
- [AWS Shield](https://docs.aws.amazon.com/shield/latest/developerguide/what-is-aws-shield.html)
- [Amazon GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html)
- [AWS Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html)
- [AWS CloudTrail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html)
- [Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)

### Data Protection

- [S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [S3 Lifecycle Management](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)

---

# Domain 1 Completion Target

By the end of this module, you should be able to take a requirement such as:

> "A company needs a secure web application where users authenticate, EC2 instances access S3 without storing credentials, the database remains private, sensitive credentials are securely stored, all important data is encrypted, web attacks are filtered, AWS activity is audited, and suspicious activity is detected."

and independently design:

```text
                    INTERNET
                       |
                    Route 53
                       |
                   CloudFront
                       |
                      WAF
                       |
                      ALB
                       |
              +--------+--------+
              |                 |
             EC2               EC2
              |                 |
              +--------+--------+
                       |
                    Private
                       |
                      RDS
```

with:

```text
IAM Role
KMS
Secrets Manager
Security Groups
NACL
VPC Endpoint
CloudTrail
CloudWatch
GuardDuty
Security Hub
```

That architecture and the individual labs give you the practical foundation needed before moving into **Domain 2: Design Resilient Architectures**.
