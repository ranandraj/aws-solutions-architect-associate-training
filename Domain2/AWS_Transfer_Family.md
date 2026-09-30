# AWS Transfer Family

## Professional Documentation for AWS Solutions Architect Associate (SAA-C03)

**Scope:** Concepts, architecture, Amazon S3 integration, SFTP
implementation, authentication, IAM, networking, Management Console, AWS
CLI, Terraform, security, monitoring, troubleshooting, architecture
decisions, and SAA-C03 exam points.

------------------------------------------------------------------------

## 1. Overview

AWS Transfer Family is a fully managed file transfer service for moving
files into and out of AWS storage without operating an FTP/SFTP server
fleet. It supports **SFTP, FTPS, FTP, AS2, and browser-based
transfers**, with Amazon S3 or Amazon EFS as storage targets. AWS states
that Transfer Family servers are backed by an auto-scaling, redundant
fleet and can use up to three Availability Zones. citeturn0search0

A common architecture is:

``` text
SFTP Client
     |
     | SSH/SFTP
     v
AWS Transfer Family
     |
     | IAM-controlled access
     v
Amazon S3
     |
     +---- Lambda / EventBridge / Glue / Athena / EC2
```

Transfer Family is managed by AWS. You do not install or patch an SFTP
server operating system. Users, authentication, storage permissions,
networking, logging, and protocol settings are configured around the
managed endpoint. citeturn0search0turn0search2

------------------------------------------------------------------------

## 2. SAA-C03 Relevance

For SAA-C03, focus on the architectural decision rather than memorizing
every Transfer Family API option.

  -----------------------------------------------------------------------
  Requirement                         AWS service/design
  ----------------------------------- -----------------------------------
  Existing partners require SFTP      AWS Transfer Family

  Need managed SFTP endpoint          Transfer Family

  Store transferred files as objects  Transfer Family + S3

  Need shared POSIX-style filesystem  Transfer Family + EFS

  Need encrypted file transfer using  SFTP
  SSH                                 

  Need legacy FTP compatibility       FTP/FTPS depending on security
                                      requirement

  Need B2B AS2 exchange               Transfer Family AS2

  Need browser-based S3 file access   Transfer Family web app

  Need process files after upload     Transfer Family managed workflows /
                                      EventBridge / Lambda

  Need user authorization to S3       IAM role and optionally session
                                      policy

  Need private endpoint               VPC-hosted Transfer Family endpoint
  -----------------------------------------------------------------------

AWS explicitly supports S3 and EFS as storage domains.
citeturn0search0

------------------------------------------------------------------------

# 3. Transfer Family Protocols

## 3.1 SFTP

SFTP is SSH File Transfer Protocol. AWS Transfer Family supports SFTP
version 3. SFTP normally uses TCP port 22. VPC-hosted Transfer Family
SFTP servers can also use supported alternate ports such as 2222, 2223,
or 22000. citeturn0search2

Use SFTP when secure partner file transfer is required and partners
already use SSH/SFTP clients.

## 3.2 FTPS

FTPS is FTP protected with TLS. It is different from SFTP because FTPS
is based on FTP plus TLS, while SFTP is based on SSH.

For FTP and FTPS data connections, Transfer Family uses TCP ports
8192-8200 for the data channel. citeturn0search0

## 3.3 FTP

FTP is unencrypted. AWS documentation recommends secure protocols such
as SFTP or FTPS when data traverses a public network.
citeturn0search8

## 3.4 AS2

AS2 is commonly used for B2B and supply-chain workflows where
message-level security and business document exchange are required.
Transfer Family supports AS2 as a managed protocol. citeturn0search0

## 3.5 Web apps

Transfer Family web apps provide browser-based access to S3 without
requiring users to operate an SFTP client. AWS describes them as a
managed interface for browsing, uploading, and downloading S3 data.
citeturn0search7

------------------------------------------------------------------------

# 4. SFTP vs FTPS vs FTP vs AS2

  ----------------------------------------------------------------------------
  Feature        SFTP           FTPS           FTP             AS2
  -------------- -------------- -------------- --------------- ---------------
  Security       SSH            TLS            None by         Message-level
  protocol                                     protocol        security

  Typical use    Secure file    Legacy FTP +   Legacy          B2B/EDI
                 transfer       TLS            non-encrypted   workflows
                                               FTP             

  Common control 22             21             21              HTTP/HTTPS
  port                                                         transport

  Encryption     Yes            Yes            No              Yes, depending
                                                               on
                                                               configuration

  SSH keys       Yes            No             No              No

  TLS            No             Yes            No              Certificates
  certificate                                                  commonly used

  SAA-C03 focus  Secure managed Secure legacy  Legacy          B2B integration
                 file transfer  FTP            compatibility   
  ----------------------------------------------------------------------------

------------------------------------------------------------------------

# 5. Storage Options

## Amazon S3

With S3, transferred files are stored as objects. This is the most
common architecture for cloud-native file transfer workflows.

``` text
Partner
  |
  | SFTP
  v
Transfer Family
  |
  v
S3 bucket
  |
  +---- EventBridge
  +---- Lambda
  +---- Glue
  +---- Athena
  +---- S3 Lifecycle
  +---- S3 Object Lock
```

AWS recommends S3 when you want durable object storage and integration
with native AWS analytics, processing, reporting, and archival services.
citeturn0search0

## Amazon EFS

EFS provides a managed file system and is appropriate when workloads
need filesystem semantics rather than S3 object semantics. AWS documents
use cases including data distribution, supply chain, content management,
and web serving. citeturn0search0

### S3 vs EFS

  -----------------------------------------------------------------------
  Characteristic          S3                      EFS
  ----------------------- ----------------------- -----------------------
  Storage model           Objects                 Filesystem

  POSIX semantics         No                      Yes

  Typical Transfer Family Partner uploads/data    Shared filesystem
  use                     lake                    workflows

  Scalability             Object storage          Elastic filesystem

  IAM/S3 policy           Yes                     IAM + POSIX permissions

  Session policies        Supported               Not the same model
  -----------------------------------------------------------------------

AWS documents that S3 supports session policies and EFS supports POSIX
user/group IDs for access control. citeturn0search11

------------------------------------------------------------------------

# 6. Core Transfer Family Architecture

A Transfer Family server has several logical components:

``` text
                       AWS Transfer Family
                              Server
                                |
             +------------------+------------------+
             |                  |                  |
       Protocol endpoint   Identity provider   Logging
             |                  |                  |
         SFTP/FTPS          Service-managed    CloudWatch
         FTP/AS2            Directory/Lambda
             |
             v
        S3 or EFS
```

The service-managed identity provider stores users and keys within
Transfer Family. Other supported identity-provider designs can integrate
directory services or custom authentication. AWS's SFTP creation
workflow presents service-managed and directory/custom options.
citeturn0search2

------------------------------------------------------------------------

# 7. Identity Provider Options

  -----------------------------------------------------------------------
  Identity provider                   Typical use
  ----------------------------------- -----------------------------------
  Service managed                     Simple SFTP deployment; users
                                      stored in Transfer Family

  AWS Directory Service               Existing Active Directory
                                      authentication

  Custom API/Lambda-based             Custom identity systems
  authentication                      
  -----------------------------------------------------------------------

For a first SAA-C03 lab, use **Service managed** because it clearly
demonstrates the Transfer Family server, IAM role, S3 bucket, SSH key,
and user relationship.

------------------------------------------------------------------------

# 8. IAM Model

There are two important authorization layers.

### Transfer Family user role

The IAM role assigned to the Transfer Family user controls access to the
S3 bucket or EFS file system. AWS requires a trust relationship allowing
the Transfer Family service to assume the role. citeturn0search14

``` text
SFTP User
    |
    v
Transfer Family
    |
    | AssumeRole
    v
IAM Role
    |
    v
S3 Bucket
```

### Trust policy

A basic trust relationship is conceptually:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "transfer.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Least-privilege S3 policy

Avoid `s3:*` in production. Grant only the actions required by the user.

Example read/write policy for a user prefix:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListBucketPrefix",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::my-transfer-bucket",
      "Condition": {
        "StringLike": {
          "s3:prefix": ["home/alice", "home/alice/*"]
        }
      }
    },
    {
      "Sid": "ObjectAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::my-transfer-bucket/home/alice/*"
    }
  ]
}
```

------------------------------------------------------------------------

# 9. Home Directories and Logical Directories

A Transfer Family user can be assigned a home directory. You can also
use logical directory mappings to present a virtual directory structure.

Example:

``` text
SFTP client sees:
/
├── uploads/
└── downloads/
```

But the actual S3 locations can be:

``` text
s3://my-bucket/partners/alice/uploads/
s3://my-bucket/partners/alice/downloads/
```

AWS supports `HOME_DIRECTORY` and `LOGICAL` configurations. The logical
directory model is particularly useful when you want users to see a
restricted virtual filesystem rather than the actual S3 path.
citeturn0search11turn1search2

------------------------------------------------------------------------

# 10. SFTP Authentication

Service-managed SFTP users commonly use an SSH public key.

Generate a key pair locally:

``` bash
ssh-keygen -t ed25519 -f transfer-family-user -C "transfer-user"
```

This creates:

``` text
transfer-family-user       # private key
transfer-family-user.pub   # public key
```

The public key is registered with the Transfer Family user. The private
key stays with the client.

AWS CLI supports RSA, ECDSA, and ED25519 public keys for Transfer Family
users. citeturn0search9

------------------------------------------------------------------------

# 11. Management Console Lab

## Objective

Build this architecture:

``` text
Windows/Linux/Mac SFTP Client
          |
          | SSH / TCP 22
          v
AWS Transfer Family SFTP Server
          |
          | IAM role
          v
Amazon S3
```

### Lab values

  Resource            Example
  ------------------- --------------------------------------
  Region              `ap-south-1`
  Bucket              `arinfotek-transfer-demo-ACCOUNT_ID`
  S3 prefix           `home/alice/`
  SFTP username       `alice`
  Protocol            SFTP
  Identity provider   Service managed
  Endpoint            Public

Use a globally unique bucket name.

------------------------------------------------------------------------

## 12. Create S3 Bucket

Open the S3 console.

Choose **Create bucket**.

Example:

``` text
Bucket name:
arinfotek-transfer-demo-ACCOUNT_ID
```

Keep Block Public Access enabled.

Keep the bucket private.

Create the bucket.

No public S3 access is required because Transfer Family accesses the
bucket using an IAM role.

------------------------------------------------------------------------

# 13. Create IAM Policy

Open:

**IAM → Policies → Create policy**

Choose JSON and use a least-privilege policy similar to:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME",
      "Condition": {
        "StringLike": {
          "s3:prefix": [
            "home/alice",
            "home/alice/*"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/home/alice/*"
    }
  ]
}
```

Replace `YOUR_BUCKET_NAME`.

Create the policy:

``` text
Name:
TransferFamilyAliceS3Policy
```

------------------------------------------------------------------------

# 14. Create IAM Role

Go to:

**IAM → Roles → Create role**

Trusted entity:

``` text
AWS service
```

Service/use case:

Select the appropriate Transfer Family service role/trust relationship,
or create the role and set the trust policy manually.

The trust relationship must allow:

``` json
{
  "Effect": "Allow",
  "Principal": {
    "Service": "transfer.amazonaws.com"
  },
  "Action": "sts:AssumeRole"
}
```

Attach:

``` text
TransferFamilyAliceS3Policy
```

Name:

``` text
TransferFamilyAliceRole
```

AWS's role guidance requires a Transfer Family trust relationship and
permissions for the target S3/EFS resources. citeturn0search14

------------------------------------------------------------------------

# 15. Create Transfer Family SFTP Server

Open:

**AWS Transfer Family → Servers → Create server**

### Protocols

Select:

``` text
SFTP
```

AWS's current SFTP creation workflow begins by selecting SFTP, then an
identity provider, storage domain, and server options.
citeturn0search2

### Identity provider

Select:

``` text
Service managed
```

### Endpoint

For the simple lab:

``` text
Endpoint type:
Publicly accessible
```

A public endpoint is the easiest option for connecting from your laptop.

### Domain

Select:

``` text
Amazon S3
```

### Logging

Enable CloudWatch logging if available in your configuration.

### Security policy

Use the current recommended Transfer Family security policy offered by
the console unless you have a specific compatibility requirement.

Create the server.

The server may initially show `Starting` and later become `Online`. AWS
notes that a newly created server can take a few minutes to become
Online. citeturn0search2

------------------------------------------------------------------------

# 16. Copy the SFTP Endpoint

Open the server details.

You will see an endpoint similar to:

``` text
s-0123456789abcdef0.server.transfer.ap-south-1.amazonaws.com
```

This is the hostname used by the SFTP client.

------------------------------------------------------------------------

# 17. Add SFTP User

Open the server.

Choose:

**Add user**

Enter:

``` text
Username:
alice
```

For role:

``` text
TransferFamilyAliceRole
```

For home directory, use:

``` text
/home/alice
```

For a simple S3 setup, configure the S3 home directory according to the
console's available `Home directory` and `Restricted` settings.

For a tightly restricted design, use a logical directory mapping such
as:

``` text
Entry:
/

Target:
/YOUR_BUCKET_NAME/home/alice
```

Add the SSH public key from:

``` text
transfer-family-user.pub
```

Save the user.

AWS's user workflow requires a username, IAM role, home directory, and
optional SSH public key. citeturn0search6turn0search11

------------------------------------------------------------------------

# 18. Connect From Windows

Windows 11 includes OpenSSH in many standard installations.

Check:

``` powershell
ssh -V
```

For SFTP:

``` powershell
sftp -i .\transfer-family-user alice@s-0123456789abcdef0.server.transfer.ap-south-1.amazonaws.com
```

If prompted about the host key, verify the server fingerprint using the
AWS Transfer Family server details before accepting it.

------------------------------------------------------------------------

# 19. Upload a File

Inside SFTP:

``` text
sftp> pwd
sftp> ls
sftp> put sample.txt
sftp> ls
sftp> exit
```

Verify in S3:

``` text
S3
 → bucket
 → home/alice/
```

The uploaded file should appear as an S3 object.

------------------------------------------------------------------------

# 20. Download a File

From SFTP:

``` text
sftp> get sample.txt
```

Or:

``` text
sftp> get /sample.txt downloaded.txt
```

------------------------------------------------------------------------

# 21. Test With WinSCP

Install WinSCP on Windows.

Configure:

``` text
File protocol: SFTP
Host name: Transfer Family endpoint
Port: 22
User name: alice
Private key: transfer-family-user private key
```

Connect and verify the S3-backed directory.

AWS lists OpenSSH, WinSCP, Cyberduck, and FileZilla among commonly used
Transfer Family clients. citeturn0search0

------------------------------------------------------------------------

# 22. AWS CLI Implementation

The CLI examples below implement the same S3 + SFTP +
service-managed-user architecture.

## Create Bucket

``` bash
aws s3api create-bucket \
  --bucket arinfotek-transfer-demo-ACCOUNT_ID \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
```

For `us-east-1`, omit `--create-bucket-configuration`.

------------------------------------------------------------------------

# 23. Create IAM Trust Policy

Create `trust-policy.json`:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "transfer.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Create the role:

``` bash
aws iam create-role \
  --role-name TransferFamilyAliceRole \
  --assume-role-policy-document file://trust-policy.json
```

------------------------------------------------------------------------

# 24. Create S3 Access Policy

Create `s3-policy.json`:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME",
      "Condition": {
        "StringLike": {
          "s3:prefix": ["home/alice", "home/alice/*"]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/home/alice/*"
    }
  ]
}
```

Create the policy:

``` bash
aws iam create-policy \
  --policy-name TransferFamilyAliceS3Policy \
  --policy-document file://s3-policy.json
```

Attach it:

``` bash
aws iam attach-role-policy \
  --role-name TransferFamilyAliceRole \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/TransferFamilyAliceS3Policy
```

------------------------------------------------------------------------

# 25. Generate SSH Key

On your client:

``` bash
ssh-keygen -t ed25519 -f transfer-family-user -C "alice"
```

Display the public key:

``` bash
cat transfer-family-user.pub
```

On Windows PowerShell:

``` powershell
Get-Content .\transfer-family-user.pub
```

------------------------------------------------------------------------

# 26. Create Transfer Family Server Using CLI

``` bash
aws transfer create-server \
  --protocols SFTP \
  --identity-provider-type SERVICE_MANAGED \
  --domain S3
```

Save the returned:

``` text
ServerId
Endpoint
```

The AWS CLI provides the `transfer` command group for creating and
managing Transfer Family servers, users, keys, connectors, and related
resources. citeturn0search4

------------------------------------------------------------------------

# 27. Create Transfer User

``` bash
aws transfer create-user \
  --server-id s-0123456789abcdef0 \
  --user-name alice \
  --role arn:aws:iam::ACCOUNT_ID:role/TransferFamilyAliceRole \
  --home-directory-type LOGICAL \
  --home-directory-mappings '[
    {
      "Entry": "/",
      "Target": "/YOUR_BUCKET_NAME/home/alice"
    }
  ]' \
  --ssh-public-key-body "$(cat transfer-family-user.pub)"
```

AWS CLI `create-user` requires the server ID, username, IAM role, and
supports the SSH public key and logical directory settings.
citeturn0search9

On Windows PowerShell, use the appropriate JSON quoting for your shell.
A JSON file can be easier to maintain for complex mappings.

------------------------------------------------------------------------

# 28. List Servers

``` bash
aws transfer list-servers
```

Describe a server:

``` bash
aws transfer describe-server \
  --server-id s-0123456789abcdef0
```

------------------------------------------------------------------------

# 29. List Users

``` bash
aws transfer list-users \
  --server-id s-0123456789abcdef0
```

------------------------------------------------------------------------

# 30. Test SFTP

``` bash
sftp -i transfer-family-user \
  alice@s-0123456789abcdef0.server.transfer.ap-south-1.amazonaws.com
```

------------------------------------------------------------------------

# 31. Terraform Implementation

The Terraform implementation uses:

``` text
aws_s3_bucket
       |
       v
IAM role + policy
       |
       v
aws_transfer_server
       |
       v
aws_transfer_user
       |
       v
aws_transfer_ssh_key
```

The current AWS provider documents `aws_transfer_server`,
`aws_transfer_user`, and `aws_transfer_ssh_key`. The server resource
supports S3/EFS domains, public or VPC endpoints, protocols, security
policies, logging, and other Transfer Family options.
citeturn1search1turn1search2turn1search0

------------------------------------------------------------------------

# 32. Terraform Provider

`versions.tf`:

``` hcl
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

Use the provider version appropriate for your environment. The Terraform
Registry is the authoritative reference for the current provider
resource schema. citeturn1search1

------------------------------------------------------------------------

# 33. S3 Bucket

``` hcl
resource "aws_s3_bucket" "transfer" {
  bucket = "arinfotek-transfer-demo-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "Transfer Family Demo"
  }
}

data "aws_caller_identity" "current" {}
```

------------------------------------------------------------------------

# 34. IAM Trust Policy

``` hcl
data "aws_iam_policy_document" "transfer_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
```

------------------------------------------------------------------------

# 35. IAM Role

``` hcl
resource "aws_iam_role" "transfer_user" {
  name               = "TransferFamilyAliceRole"
  assume_role_policy = data.aws_iam_policy_document.transfer_assume_role.json
}
```

------------------------------------------------------------------------

# 36. S3 Policy

``` hcl
data "aws_iam_policy_document" "transfer_s3" {
  statement {
    effect = "Allow"

    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.transfer.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["home/alice", "home/alice/*"]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.transfer.arn}/home/alice/*"
    ]
  }
}
```

------------------------------------------------------------------------

# 37. Attach S3 Policy

``` hcl
resource "aws_iam_role_policy" "transfer_s3" {
  name   = "TransferFamilyAliceS3Policy"
  role   = aws_iam_role.transfer_user.id
  policy = data.aws_iam_policy_document.transfer_s3.json
}
```

------------------------------------------------------------------------

# 38. Transfer Family Server

``` hcl
resource "aws_transfer_server" "sftp" {
  identity_provider_type = "SERVICE_MANAGED"
  domain                 = "S3"
  protocols              = ["SFTP"]

  security_policy_name = "TransferSecurityPolicy-2025-03"

  tags = {
    Name = "SFTP-Transfer-Server"
  }
}
```

The provider currently supports multiple Transfer Family security policy
names; select a policy compatible with your organization's requirements
and region. citeturn1search1

------------------------------------------------------------------------

# 39. Generate an SSH Key With Terraform

Use the TLS provider:

``` hcl
terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
    }
  }
}

resource "tls_private_key" "transfer_user" {
  algorithm = "ED25519"
}
```

The private key is sensitive and should not be casually committed to
source control or exposed in outputs.

------------------------------------------------------------------------

# 40. Transfer User

``` hcl
resource "aws_transfer_user" "alice" {
  server_id = aws_transfer_server.sftp.id
  user_name = "alice"
  role      = aws_iam_role.transfer_user.arn

  home_directory_type = "LOGICAL"

  home_directory_mappings {
    entry  = "/"
    target = "/${aws_s3_bucket.transfer.id}/home/alice"
  }
}
```

The Terraform AWS provider documents logical directory mappings for
Transfer users. citeturn1search2

------------------------------------------------------------------------

# 41. Register SSH Public Key

``` hcl
resource "aws_transfer_ssh_key" "alice" {
  server_id = aws_transfer_server.sftp.id
  user_name = aws_transfer_user.alice.user_name
  body      = trimspace(tls_private_key.transfer_user.public_key_openssh)
}
```

The provider's official example uses `aws_transfer_ssh_key` with the
public key generated by the TLS provider. citeturn1search0

------------------------------------------------------------------------

# 42. Terraform Outputs

``` hcl
output "transfer_server_id" {
  value = aws_transfer_server.sftp.id
}

output "transfer_endpoint" {
  value = aws_transfer_server.sftp.endpoint
}

output "sftp_username" {
  value = aws_transfer_user.alice.user_name
}
```

Do not output the private SSH key unless you have a deliberate secure
secret-handling design.

------------------------------------------------------------------------

# 43. Apply Terraform

``` bash
terraform init
```

Then:

``` bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

After completion:

``` bash
terraform output
```

Use the endpoint with the private key generated by Terraform.

------------------------------------------------------------------------

# 44. Private VPC-Hosted Transfer Family Endpoint

A public endpoint is simplest for a first lab. For an enterprise design,
a VPC-hosted endpoint can be appropriate when access must be controlled
through VPC networking.

Architecture:

``` text
Partner Network
      |
      | VPN / Direct Connect / controlled network
      v
VPC
 |
 +-- Private Subnets
       |
       v
Transfer Family VPC Endpoint
       |
       v
S3 / EFS
```

AWS documents VPC-hosted endpoints and explains that public endpoints do
not support security-group restrictions, while VPC-hosted endpoints can
be placed in a VPC with security groups. citeturn0search5

For an internet-facing VPC-hosted endpoint, AWS documents SFTP and FTPS
as supported protocols. citeturn0search5

------------------------------------------------------------------------

# 45. Public vs VPC Endpoint

  -----------------------------------------------------------------------
  Feature                 Public endpoint         VPC-hosted endpoint
  ----------------------- ----------------------- -----------------------
  Internet accessible     Yes                     Depends on
                                                  configuration

  Simple partner access   Yes                     More networking
                                                  required

  Security groups         Not for public endpoint Yes for VPC-hosted
                                                  endpoint

  Private networking      No                      Yes

  Integration with VPN/DX Possible through        Strong fit
                          architecture            

  Operational complexity  Lower                   Higher

  SAA-C03 use case        Internet-based partner  Private enterprise
                          access                  network
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 46. Monitoring

Enable CloudWatch logging for operational visibility.

Typical architecture:

``` text
SFTP Client
     |
Transfer Family
     |
     +---- CloudWatch Logs
     |
     +---- S3
```

The Transfer Family server supports a logging role and structured log
destinations through the AWS provider. citeturn1search1

Monitor:

-   Authentication failures
-   Successful connections
-   Upload/download activity
-   User activity
-   Server state
-   Transfer errors
-   Workflow failures

------------------------------------------------------------------------

# 47. Managed Workflows

Transfer Family managed workflows can process files after transfer. AWS
describes workflow steps including copying, tagging, scanning,
filtering, compression/decompression, and encryption/decryption.
citeturn0search0

Example:

``` text
Partner
  |
  | SFTP upload
  v
Transfer Family
  |
  v
S3
  |
  v
Managed Workflow
  |
  +---- Scan
  +---- Tag
  +---- Move
  +---- Lambda processing
  +---- Archive
```

This can remove the need for a separate always-running file-processing
server.

------------------------------------------------------------------------

# 48. Security Best Practices

1.  Prefer SFTP or FTPS over unencrypted FTP when data crosses untrusted
    networks.
2.  Use least-privilege IAM roles.
3.  Restrict each user to only the required S3 prefix.
4.  Use logical directories when users should not see the physical S3
    layout.
5.  Protect private SSH keys.
6.  Enable CloudWatch logging.
7.  Use VPC-hosted endpoints when private network access and
    security-group controls are required.
8.  Use S3 Block Public Access.
9.  Encrypt S3 objects using SSE-S3 or SSE-KMS as required.
10. Rotate SSH keys and remove unused users.
11. Use AWS CloudTrail for API-level auditing.
12. Use managed workflows or event-driven processing rather than
    maintaining a permanent processing server when appropriate.

------------------------------------------------------------------------

# 49. Transfer Family vs Running Your Own SFTP Server

  Requirement                   Transfer Family          EC2 SFTP server
  ----------------------------- ------------------------ --------------------------
  Server OS management          AWS managed              Customer managed
  Patching                      AWS managed              Customer responsibility
  Scaling                       Managed                  Design required
  HA architecture               Managed service          Must design
  S3 integration                Native                   Configure manually
  User management               Managed/custom options   OS/application dependent
  Operational overhead          Lower                    Higher
  Fine OS-level customization   Limited                  High

The architectural advantage of Transfer Family is that the file transfer
endpoint is managed by AWS rather than implemented as a fleet of
EC2-based file servers. AWS describes Transfer Family as fully managed
and backed by a redundant, auto-scaling fleet. citeturn0search0

------------------------------------------------------------------------

# 50. Transfer Family vs S3 Presigned URLs

  Requirement                           Transfer Family         S3 presigned URL
  ------------------------------------- ----------------------- ------------------
  SFTP client compatibility             Yes                     No
  Existing FTP/SFTP partner             Yes                     No
  Browser/object download               Possible via web apps   Yes
  Object-level temporary access         Not primary purpose     Yes
  User-specific filesystem experience   Yes                     No
  B2B SFTP migration                    Yes                     No

Use Transfer Family when the external party already expects a
file-transfer protocol.

Use presigned URLs when the requirement is temporary HTTP-based object
access.

------------------------------------------------------------------------

# 51. Transfer Family vs AWS DataSync

  -----------------------------------------------------------------------
  Requirement             Transfer Family         DataSync
  ----------------------- ----------------------- -----------------------
  Partner SFTP endpoint   Yes                     No

  Managed recurring bulk  Not primary purpose     Yes
  data movement                                   

  SMB/NFS transfers       Not the primary         Yes
                          protocol model          

  Existing SFTP clients   Yes                     No

  Interactive file        Yes                     No
  transfer                                        

  Large-scale storage     Possible but not        Strong fit
  migration               primary                 
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 52. SAA-C03 Decision Scenarios

### Scenario 1

A company has external vendors that already upload files using SFTP. The
company wants to move the backend storage to Amazon S3 without
maintaining SFTP servers.

**Architecture:**

``` text
Vendors
  |
 SFTP
  |
Transfer Family
  |
 S3
```

### Scenario 2

Users require a private SFTP endpoint reachable only through corporate
networking.

**Architecture:**

``` text
Corporate Network
      |
 VPN / Direct Connect
      |
 VPC
      |
 Transfer Family VPC endpoint
```

### Scenario 3

Users need temporary HTTP access to individual S3 objects.

**Architecture:** S3 presigned URLs rather than Transfer Family.

### Scenario 4

An organization needs to migrate millions of files from an NFS
environment into AWS.

**Architecture:** consider AWS DataSync rather than using Transfer
Family as a migration engine.

------------------------------------------------------------------------

# 53. Important Exam Distinctions

  Service            Primary purpose
  ------------------ -----------------------------------------
  Transfer Family    Managed SFTP/FTPS/FTP/AS2/file transfer
  S3                 Object storage
  EFS                Managed elastic filesystem
  DataSync           Managed data transfer/migration
  Storage Gateway    Hybrid storage integration
  CloudFront         CDN
  API Gateway        Managed APIs
  Client VPN         Client-based VPN access
  Site-to-Site VPN   Network-to-network IPsec VPN
  Direct Connect     Dedicated private connectivity to AWS

------------------------------------------------------------------------

# 54. Troubleshooting

## Authentication failure

Check:

``` text
Username
SSH public key
Private key
Server status
Identity provider
```

Check the user:

``` bash
aws transfer list-users --server-id s-xxxxxxxxxxxxxxxxx
```

## Permission denied after login

The SSH authentication succeeded but the IAM role may not permit the S3
operation.

Check:

``` text
IAM trust policy
IAM permissions
S3 bucket ARN
S3 object prefix
Home directory
Logical mappings
```

## Cannot connect to port 22

For a public endpoint check:

``` text
Correct endpoint
Correct region
Client network firewall
Corporate outbound filtering
Server status = ONLINE
```

For a VPC endpoint check:

``` text
Subnet
Security group
NACL
Route table
Network path
```

## User can see files outside intended location

Review the home directory and logical mappings. Use restricted logical
mappings and prefix-scoped IAM policies for stronger isolation.

------------------------------------------------------------------------

# 55. CLI Quick Reference

``` bash
# List servers
aws transfer list-servers

# Describe server
aws transfer describe-server --server-id s-xxxxxxxxxxxxxxxxx

# List users
aws transfer list-users --server-id s-xxxxxxxxxxxxxxxxx

# Describe user
aws transfer describe-user \
  --server-id s-xxxxxxxxxxxxxxxxx \
  --user-name alice

# Create server
aws transfer create-server \
  --protocols SFTP \
  --identity-provider-type SERVICE_MANAGED \
  --domain S3

# Delete server
aws transfer delete-server \
  --server-id s-xxxxxxxxxxxxxxxxx
```

See the AWS CLI Transfer Family reference for the complete command set.
citeturn0search4

------------------------------------------------------------------------

# 56. Terraform Quick Reference

Core resources:

``` text
aws_transfer_server
aws_transfer_user
aws_transfer_ssh_key
```

Common supporting resources:

``` text
aws_s3_bucket
aws_iam_role
aws_iam_role_policy
aws_cloudwatch_log_group
aws_eip
aws_security_group
aws_subnet
aws_vpc
```

The current Terraform AWS provider documents these Transfer Family
resources and their server, user, SSH key, endpoint, protocol,
identity-provider, logging, and directory configuration options.
citeturn1search1turn1search2turn1search0

------------------------------------------------------------------------

# 57. Console vs CLI vs Terraform

  Area                         Management Console   AWS CLI     Terraform
  ---------------------------- -------------------- ----------- --------------------
  Initial learning             Easiest              Moderate    Moderate/high
  Repeatability                Low                  High        Very high
  Version control              No                   Scripts     Yes
  Automation                   Limited              Strong      Strong
  Visual configuration         Yes                  No          No
  Best for lab demonstration   Yes                  Yes         Yes
  Best for production IaC      No                   Sometimes   Yes
  Drift management             Manual               Manual      Terraform workflow

------------------------------------------------------------------------

# 58. Cleanup

If the lab is temporary, remove resources to avoid ongoing charges.

Terraform:

``` bash
terraform destroy
```

CLI:

``` bash
aws transfer delete-user \
  --server-id s-xxxxxxxxxxxxxxxxx \
  --user-name alice

aws transfer delete-server \
  --server-id s-xxxxxxxxxxxxxxxxx
```

Then remove:

``` text
S3 bucket and objects
IAM role/policies
CloudWatch log group
VPC resources if created for the lab
```

AWS notes that instantiated Transfer Family servers incur service
charges even when offline, in addition to applicable data-transfer
charges. citeturn0search4

------------------------------------------------------------------------

# 59. Official AWS Documentation

## AWS Transfer Family

-   AWS Transfer Family overview:
    https://docs.aws.amazon.com/transfer/latest/userguide/what-is-aws-transfer-family.html
-   AWS Transfer Family documentation:
    https://docs.aws.amazon.com/transfer/
-   AWS Transfer Family getting started:
    https://docs.aws.amazon.com/transfer/latest/userguide/getting-started.html
-   Create an SFTP server:
    https://docs.aws.amazon.com/transfer/latest/userguide/create-server-sftp.html
-   Create a VPC-hosted server:
    https://docs.aws.amazon.com/transfer/latest/userguide/create-server-in-vpc.html
-   Manage Transfer Family users:
    https://docs.aws.amazon.com/transfer/latest/userguide/create-user.html
-   IAM roles and policies:
    https://docs.aws.amazon.com/transfer/latest/userguide/requirements-roles.html
-   Transfer Family web apps:
    https://docs.aws.amazon.com/transfer/latest/userguide/web-app.html
-   AWS Transfer Family API reference:
    https://docs.aws.amazon.com/transfer/latest/APIReference/Welcome.html
-   AWS CLI reference:
    https://docs.aws.amazon.com/cli/latest/reference/transfer/

## Protocol-specific documentation

-   SFTP:
    https://docs.aws.amazon.com/transfer/latest/userguide/create-server-sftp.html
-   FTP:
    https://docs.aws.amazon.com/transfer/latest/userguide/create-server-ftp.html
-   FTPS and server protocol/security configuration:
    https://docs.aws.amazon.com/transfer/latest/userguide/
-   AS2: https://docs.aws.amazon.com/transfer/latest/userguide/

## Terraform

-   `aws_transfer_server`:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_server
-   `aws_transfer_user`:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_user
-   `aws_transfer_ssh_key`:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_ssh_key

------------------------------------------------------------------------

# 60. SAA-C03 Final Mental Model

Remember the architecture as:

``` text
Existing SFTP/FTPS/FTP/AS2 clients
              |
              v
      AWS Transfer Family
              |
       +------+------+
       |             |
       v             v
      S3            EFS
       |
       +---- Lambda
       +---- EventBridge
       +---- Glue
       +---- Athena
       +---- Archive
```

The key SAA-C03 decision is:

> **When an organization needs a managed endpoint that supports
> traditional file-transfer protocols and wants the transferred data
> stored in AWS storage, consider AWS Transfer Family.**

For the common SFTP-to-S3 architecture:

``` text
SFTP Client
    |
    | SSH
    v
Transfer Family
    |
    | IAM role
    v
Amazon S3
```

This removes the need to operate an EC2-based SFTP server while
preserving compatibility with standard SFTP clients. AWS explicitly
describes Transfer Family as a fully managed service for transferring
files directly into and out of S3 or EFS. citeturn0search0
