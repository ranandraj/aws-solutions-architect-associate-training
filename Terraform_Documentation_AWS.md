# Terraform: What It Is, Working, Architecture, Syntax and AWS Examples

**Audience:** Students learning Infrastructure as Code (IaC) and AWS\
**Focus:** Terraform fundamentals with practical AWS examples\
**Updated:** September 2026

------------------------------------------------------------------------

## 1. What is Terraform?

Terraform is an **Infrastructure as Code (IaC)** tool developed by
HashiCorp.

It allows infrastructure to be described in human-readable configuration
files and then creates, changes, and manages that infrastructure through
APIs.

Instead of manually creating:

-   VPCs
-   Subnets
-   EC2 instances
-   Security groups
-   S3 buckets
-   IAM roles
-   Load balancers
-   RDS databases

you describe the desired infrastructure in Terraform configuration
files.

Terraform then determines what needs to be created, changed, or removed.

HashiCorp describes Terraform as an infrastructure-as-code tool that can
build, change, and version cloud and on-premises resources. Terraform
uses configuration files to describe the desired end state and uses
state to track managed infrastructure.\
Official reference: https://developer.hashicorp.com/terraform/intro

------------------------------------------------------------------------

## 2. Infrastructure as Code

Infrastructure as Code means defining infrastructure through code or
configuration instead of relying entirely on manual console operations.

### Traditional approach

``` text
Open AWS Console
      |
Create VPC
      |
Create subnet
      |
Create route table
      |
Create security group
      |
Create EC2
      |
Configure everything manually
```

### Infrastructure as Code

``` text
Terraform files
      |
terraform plan
      |
Review changes
      |
terraform apply
      |
AWS infrastructure
```

The configuration can be stored in Git, reviewed, reused and applied
repeatedly.

------------------------------------------------------------------------

## 3. Declarative Infrastructure

Terraform is primarily **declarative**.

You describe the desired end state rather than writing every API
operation.

Example:

``` hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

This describes a VPC that should exist with CIDR `10.0.0.0/16`.

You do not write the sequence of AWS API calls required to create it.

Terraform builds a dependency graph and determines the order in which
resources must be created or changed. Independent resources can be
processed in parallel.

Official reference: https://developer.hashicorp.com/terraform/language

------------------------------------------------------------------------

## 4. Terraform Architecture

A simplified architecture is:

``` text
                 Terraform Configuration
                       .tf files
                           |
                           v
                  +----------------+
                  |    Terraform   |
                  |      CLI       |
                  +----------------+
                    |            |
                    v            v
              Configuration    State
                    |            |
                    +-----+------+
                          |
                          v
                   Dependency Graph
                          |
                          v
                       Provider
                          |
                          v
                      AWS APIs
                          |
                          v
                +---------------------+
                | AWS Infrastructure  |
                |                     |
                | VPC                 |
                | EC2                 |
                | S3                  |
                | IAM                 |
                | RDS                 |
                +---------------------+
```

### Main components

1.  Terraform configuration
2.  Terraform CLI
3.  Provider
4.  State
5.  Dependency graph
6.  AWS APIs
7.  AWS resources

------------------------------------------------------------------------

## 5. Terraform Configuration Files

Terraform code is normally stored in files ending with:

``` text
.tf
```

Terraform also supports:

``` text
.tf.json
```

Example project:

``` text
terraform-aws-lab/
|
+-- terraform.tf
+-- providers.tf
+-- variables.tf
+-- main.tf
+-- outputs.tf
+-- terraform.tfvars
```

Terraform evaluates all configuration files in the same directory as one
module. The filenames do not determine execution order.

Official reference:
https://developer.hashicorp.com/terraform/language/files

------------------------------------------------------------------------

## 6. HCL and Terraform Syntax

Terraform's native configuration language is based on **HCL**, the
HashiCorp Configuration Language.

Example:

``` hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

The main syntax elements are:

-   Blocks
-   Arguments
-   Expressions
-   Identifiers
-   Values
-   References
-   Functions

Official reference:
https://developer.hashicorp.com/terraform/language/syntax/configuration

------------------------------------------------------------------------

## 7. Basic Terraform Block Syntax

General form:

``` hcl
BLOCK_TYPE "LABEL_1" "LABEL_2" {
  argument = value
}
```

Example:

``` hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

Breakdown:

``` text
resource
   |
   +-- Block type

"aws_vpc"
   |
   +-- Resource type

"main"
   |
   +-- Terraform local name

{
   |
   +-- Block body

cidr_block = "10.0.0.0/16"
   |
   +-- Argument
}
```

------------------------------------------------------------------------

## 8. Blocks

A block is a container for related configuration.

Example:

``` hcl
resource "aws_s3_bucket" "training" {
  bucket_prefix = "terraform-training-"
}
```

Common Terraform block types include:

``` text
terraform
provider
resource
data
variable
locals
module
output
import
moved
check
```

------------------------------------------------------------------------

## 9. Arguments

An argument assigns a value to a name.

Example:

``` hcl
cidr_block = "10.0.0.0/16"
```

Another:

``` hcl
instance_type = "t3.micro"
```

The argument schema depends on the block type and provider resource.

------------------------------------------------------------------------

## 10. Comments

Single-line:

``` hcl
# Create the VPC
```

Also supported:

``` hcl
// Create the VPC
```

Multi-line:

``` hcl
/*
Create the
main VPC.
*/
```

------------------------------------------------------------------------

## 11. Terraform Values

### String

``` hcl
name = "production"
```

### Number

``` hcl
instance_count = 3
```

### Boolean

``` hcl
enabled = true
```

### List

``` hcl
availability_zones = [
  "ap-south-1a",
  "ap-south-1b"
]
```

### Map

``` hcl
tags = {
  Environment = "Training"
  Project     = "SAA"
}
```

------------------------------------------------------------------------

## 12. Variables

Variables make configurations reusable.

Without a variable:

``` hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

With a variable:

``` hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}
```

Variable definition:

``` hcl
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
```

Official reference:
https://developer.hashicorp.com/terraform/language/values/variables

------------------------------------------------------------------------

## 13. Variable Types

Common types:

``` text
string
number
bool
list
set
map
object
tuple
```

Examples:

``` hcl
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
```

``` hcl
variable "instance_count" {
  type    = number
  default = 2
}
```

``` hcl
variable "enable_monitoring" {
  type    = bool
  default = true
}
```

------------------------------------------------------------------------

## 14. terraform.tfvars

Variables can be assigned using `terraform.tfvars`.

`variables.tf`:

``` hcl
variable "aws_region" {
  type = string
}

variable "instance_type" {
  type = string
}
```

`terraform.tfvars`:

``` hcl
aws_region    = "ap-south-1"
instance_type = "t3.micro"
```

Run:

``` bash
terraform plan
```

Terraform automatically loads `terraform.tfvars`.

Do not store production passwords or other secrets in an unprotected
`.tfvars` file.

------------------------------------------------------------------------

## 15. Variable Validation

Variables can contain validation rules.

``` hcl
variable "environment" {
  type        = string
  description = "Environment name"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}
```

This prevents invalid environment names.

------------------------------------------------------------------------

## 16. Sensitive Variables

Example:

``` hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

The sensitive flag reduces accidental display of the value in normal CLI
output.

It does **not** mean the value is absent from Terraform state.

Protect Terraform state accordingly.

------------------------------------------------------------------------

## 17. Local Values

Locals store reusable expressions.

``` hcl
locals {
  project     = "saa-training"
  environment = "dev"

  common_tags = {
    Project     = local.project
    Environment = local.environment
  }
}
```

Use:

``` hcl
tags = local.common_tags
```

------------------------------------------------------------------------

## 18. Resources

Resources are infrastructure objects managed by Terraform.

Example:

``` hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

The resource address is:

``` text
aws_vpc.main
```

Where:

``` text
aws_vpc = resource type
main    = local Terraform name
```

The AWS provider supports resource types for VPC, EC2, S3, RDS, Lambda,
ECS and many other AWS services.

Official reference:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs

------------------------------------------------------------------------

## 19. Resource References

Resources can reference other resources.

``` hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}
```

This:

``` hcl
aws_vpc.main.id
```

means:

``` text
resource type = aws_vpc
resource name = main
attribute     = id
```

Terraform automatically understands that the subnet depends on the VPC.

------------------------------------------------------------------------

## 20. Data Sources

A resource normally creates or manages infrastructure.

A data source reads information about existing infrastructure.

Example:

``` hcl
data "aws_vpc" "existing" {
  id = "vpc-0123456789abcdef"
}
```

Use it:

``` hcl
resource "aws_subnet" "public" {
  vpc_id     = data.aws_vpc.existing.id
  cidr_block = "10.0.1.0/24"
}
```

Data sources are useful when Terraform needs information about
infrastructure that it does not create.

------------------------------------------------------------------------

## 21. Outputs

Outputs expose useful values.

``` hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}
```

After:

``` bash
terraform apply
```

you may see:

``` text
vpc_id = "vpc-0123456789abcdef"
```

Outputs can also be used as module outputs.

Official reference:
https://developer.hashicorp.com/terraform/language/values/outputs

------------------------------------------------------------------------

## 22. Providers

A provider is a plugin that allows Terraform to communicate with AWS and
other platforms.

AWS architecture:

``` text
Terraform
    |
AWS Provider
    |
AWS APIs
    |
AWS resources
```

Provider declaration:

``` hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.62"
    }
  }
}
```

Provider configuration:

``` hcl
provider "aws" {
  region = "ap-south-1"
}
```

The AWS provider version changes over time. Check the current Terraform
Registry before starting a new project. The current registry release
observed in September 2026 is 6.62.0.

Official reference:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs

------------------------------------------------------------------------

## 23. Terraform Block

The `terraform` block defines Terraform-specific requirements.

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

It can specify:

-   Terraform CLI version
-   Required providers
-   Provider version constraints
-   Backend configuration

------------------------------------------------------------------------

## 24. Provider Block

``` hcl
provider "aws" {
  region = "ap-south-1"
}
```

Using a variable:

``` hcl
provider "aws" {
  region = var.aws_region
}
```

------------------------------------------------------------------------

# 25. Terraform Working Process

The basic process is:

``` text
Terraform .tf files
        |
        v
terraform init
        |
        v
terraform fmt
        |
        v
terraform validate
        |
        v
terraform plan
        |
        v
Review
        |
        v
terraform apply
        |
        v
AWS Infrastructure
```

When changes are made:

``` text
Modify .tf files
       |
terraform plan
       |
Review
       |
terraform apply
```

To remove the lab:

``` bash
terraform destroy
```

------------------------------------------------------------------------

## 26. `terraform init`

Run:

``` bash
terraform init
```

Terraform:

-   Initializes the working directory.
-   Downloads required providers.
-   Initializes the backend.
-   Initializes modules.

Typical output:

``` text
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

------------------------------------------------------------------------

## 27. `terraform fmt`

Run:

``` bash
terraform fmt
```

For all subdirectories:

``` bash
terraform fmt -recursive
```

This formats Terraform source files according to Terraform's standard
formatting.

------------------------------------------------------------------------

## 28. `terraform validate`

Run:

``` bash
terraform validate
```

Expected:

``` text
Success! The configuration is valid.
```

This catches configuration and syntax problems before planning.

------------------------------------------------------------------------

## 29. `terraform plan`

Run:

``` bash
terraform plan
```

Terraform calculates the proposed changes.

Example:

``` text
Plan: 3 to add, 0 to change, 0 to destroy.
```

Common symbols:

``` text
+    create
-    destroy
~    modify
-/+  replace
```

Always review a production plan before applying it.

------------------------------------------------------------------------

## 30. `terraform apply`

Run:

``` bash
terraform apply
```

Terraform shows the planned actions and asks for confirmation.

Enter:

``` text
yes
```

Example:

``` text
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

------------------------------------------------------------------------

## 31. `terraform destroy`

Run:

``` bash
terraform destroy
```

Terraform proposes removal of managed resources.

Example:

``` text
Plan: 0 to add, 0 to change, 3 to destroy.
```

Enter:

``` text
yes
```

Use this carefully in real environments.

------------------------------------------------------------------------

# 32. Terraform State

Terraform maintains state to track resources.

Local state normally appears as:

``` text
terraform.tfstate
```

Conceptually:

``` text
Terraform resource:
aws_vpc.main

AWS resource:
vpc-0123456789abcdef
```

Terraform uses state when calculating changes.

State can contain sensitive infrastructure information and sometimes
secret values. Protect it.

------------------------------------------------------------------------

## 33. State Commands

List resources:

``` bash
terraform state list
```

Inspect a resource:

``` bash
terraform state show aws_vpc.main
```

Show state:

``` bash
terraform show
```

Remove a resource from state:

``` bash
terraform state rm aws_vpc.main
```

`terraform state rm` normally removes Terraform's tracking relationship.
It does not mean "delete this AWS resource."

Use state commands carefully.

------------------------------------------------------------------------

# 34. Dependency Graph

Suppose:

``` text
VPC
 |
 +-- Subnet
      |
      +-- EC2
```

Terraform sees:

``` hcl
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
}
```

and:

``` hcl
resource "aws_instance" "web" {
  subnet_id = aws_subnet.public.id
}
```

Terraform can infer:

``` text
VPC
 |
 v
Subnet
 |
 v
EC2
```

The dependency graph determines resource ordering.

------------------------------------------------------------------------

# 35. AWS Example 1: S3 Bucket

Create a directory:

``` text
terraform-s3-lab/
```

Create `main.tf`:

``` hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.62"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "training" {
  bucket_prefix = "terraform-training-"

  tags = {
    Name        = "Terraform Training Bucket"
    Environment = "Lab"
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

Enter:

``` text
yes
```

Verify:

``` bash
aws s3api list-buckets
```

Clean up:

``` bash
terraform destroy
```

------------------------------------------------------------------------

# 36. AWS Example 2: VPC

``` hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform-vpc"
  }
}
```

The AWS provider documentation provides the current `aws_vpc` resource
schema and examples.

Reference:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

------------------------------------------------------------------------

# 37. AWS Example 3: VPC and Subnet

``` hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform-public-subnet"
  }
}
```

Dependency:

``` text
aws_vpc.main
     |
     v
aws_subnet.public
```

------------------------------------------------------------------------

# 38. AWS Example 4: Internet Gateway

``` hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-igw"
  }
}
```

Architecture:

``` text
VPC
 |
 +-- Internet Gateway
```

------------------------------------------------------------------------

# 39. AWS Example 5: Route Table

``` hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "terraform-public-rt"
  }
}
```

Associate:

``` hcl
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

------------------------------------------------------------------------

# 40. AWS Example 6: Security Group

``` hcl
resource "aws_security_group" "web" {
  name        = "terraform-web-sg"
  description = "Allow HTTPS"
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
    Name = "terraform-web-sg"
  }
}
```

For production, restrict source ranges as much as the architecture
permits.

------------------------------------------------------------------------

# 41. AWS Example 7: EC2

An EC2 resource normally needs:

-   AMI
-   Instance type
-   Subnet
-   Security group
-   Optional IAM instance profile
-   Optional storage configuration

Example:

``` hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  tags = {
    Name = "terraform-web"
  }
}
```

The AMI must exist in the selected AWS region.

Official AWS provider resource:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

------------------------------------------------------------------------

# 42. AWS Example 8: Ubuntu AMI Data Source

Rather than hard-coding an AMI ID, use a data source.

Example:

``` hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

Use it:

``` hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  tags = {
    Name = "terraform-ubuntu"
  }
}
```

Always verify the current AMI name and owner for the OS, architecture
and AWS region you are using.

------------------------------------------------------------------------

# 43. AWS Example 9: IAM Role for EC2

Do not place AWS access keys in application code or EC2 configuration
when an IAM role can be used.

``` hcl
resource "aws_iam_role" "ec2_role" {
  name = "terraform-ec2-role"

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
```

Instance profile:

``` hcl
resource "aws_iam_instance_profile" "ec2" {
  name = "terraform-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
```

EC2:

``` hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public.id

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  tags = {
    Name = "terraform-web"
  }
}
```

------------------------------------------------------------------------

# 44. AWS Example 10: EC2 Role Reading S3

Suppose the EC2 application needs only `s3:GetObject`.

``` hcl
resource "aws_iam_role_policy" "s3_read" {
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.training.arn}/*"
      }
    ]
  })
}
```

Architecture:

``` text
EC2
 |
IAM Instance Profile
 |
IAM Role
 |
IAM Policy
 |
S3
```

This demonstrates least privilege.

------------------------------------------------------------------------

# 45. Meta-Arguments

Common Terraform meta-arguments:

``` text
count
for_each
depends_on
provider
lifecycle
```

------------------------------------------------------------------------

# 46. `count`

Create multiple resources:

``` hcl
resource "aws_s3_bucket" "bucket" {
  count = 3

  bucket_prefix = "training-${count.index}-"
}
```

Terraform addresses them as:

``` text
aws_s3_bucket.bucket[0]
aws_s3_bucket.bucket[1]
aws_s3_bucket.bucket[2]
```

Use `count` when the instances are interchangeable.

------------------------------------------------------------------------

# 47. `for_each`

``` hcl
variable "environments" {
  type = set(string)

  default = [
    "dev",
    "test",
    "prod"
  ]
}

resource "aws_s3_bucket" "environment" {
  for_each = var.environments

  bucket_prefix = "${each.key}-training-"
}
```

Addresses:

``` text
aws_s3_bucket.environment["dev"]
aws_s3_bucket.environment["test"]
aws_s3_bucket.environment["prod"]
```

Use `for_each` when meaningful keys identify each instance.

------------------------------------------------------------------------

# 48. `depends_on`

Terraform normally infers dependencies from references.

Explicit dependency:

``` hcl
resource "aws_instance" "web" {
  # configuration

  depends_on = [
    aws_iam_role_policy.s3_read
  ]
}
```

Use it only when the dependency cannot be inferred naturally.

------------------------------------------------------------------------

# 49. `lifecycle`

Example:

``` hcl
resource "aws_instance" "web" {
  # configuration

  lifecycle {
    create_before_destroy = true
  }
}
```

Another:

``` hcl
lifecycle {
  prevent_destroy = true
}
```

`prevent_destroy` can intentionally block deletion. Use it carefully.

------------------------------------------------------------------------

# 50. Functions and Expressions

Example:

``` hcl
lower("AWS")
```

Result:

``` text
aws
```

Length:

``` hcl
length(["a", "b", "c"])
```

Result:

``` text
3
```

Conditional:

``` hcl
instance_type = var.environment == "prod" ? "t3.medium" : "t3.micro"
```

CIDR calculation:

``` hcl
cidrsubnet("10.0.0.0/16", 8, 1)
```

------------------------------------------------------------------------

# 51. Modules

A module is a reusable collection of Terraform configuration.

Example:

``` text
modules/
|
+-- vpc/
|   +-- main.tf
|   +-- variables.tf
|   +-- outputs.tf
|
+-- ec2/
    +-- main.tf
    +-- variables.tf
    +-- outputs.tf
```

Call a module:

``` hcl
module "network" {
  source = "./modules/vpc"

  vpc_cidr = "10.0.0.0/16"
}
```

Use its output:

``` hcl
resource "aws_subnet" "public" {
  vpc_id     = module.network.vpc_id
  cidr_block = "10.0.1.0/24"
}
```

------------------------------------------------------------------------

# 52. Terraform State and Remote State

For individual learning:

``` text
terraform.tfstate
```

may be stored locally.

For team environments, use an appropriate remote backend with:

-   Encryption
-   Restricted access
-   State versioning
-   Concurrency protection
-   Monitoring
-   Backup/recovery

Never expose Terraform state publicly.

An AWS S3-backed state architecture is a common pattern, but the exact
backend and locking approach should follow the current Terraform and AWS
documentation.

------------------------------------------------------------------------

# 53. `.terraform` and Lock File

After:

``` bash
terraform init
```

Terraform creates:

``` text
.terraform/
```

Do not normally commit it.

Terraform also creates:

``` text
.terraform.lock.hcl
```

The lock file records selected provider dependency information and
checksums and is normally committed to version control.

------------------------------------------------------------------------

# 54. Recommended `.gitignore`

A typical project can use:

``` text
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfvars.json
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
```

Review this for your organization's requirements before committing a
project.

------------------------------------------------------------------------

# 55. Terraform and AWS Credentials

Terraform does not create AWS credentials.

The AWS provider must obtain credentials through a supported AWS
credential mechanism.

Common options include:

``` text
AWS CLI configuration
AWS environment variables
IAM Identity Center profiles
IAM roles
EC2 instance roles
CI/CD identity mechanisms
```

Check your AWS identity:

``` bash
aws sts get-caller-identity
```

Avoid hard-coding:

``` hcl
provider "aws" {
  access_key = "..."
  secret_key = "..."
}
```

Use the AWS provider credential chain instead.

------------------------------------------------------------------------

# 56. Terraform Drift

Drift occurs when AWS infrastructure is changed outside Terraform.

Example:

``` text
Terraform configuration:
HTTPS only

AWS Console:
Someone manually adds SSH port 22
```

Terraform configuration and real infrastructure now differ.

Run:

``` bash
terraform plan
```

Terraform can identify differences and propose corrective changes.

------------------------------------------------------------------------

# 57. Terraform Import

Existing AWS resources can be brought under Terraform management.

Example:

``` hcl
import {
  to = aws_vpc.existing
  id = "vpc-0123456789abcdef"
}

resource "aws_vpc" "existing" {
  # Complete configuration to represent
  # the intended resource.
}
```

Then:

``` bash
terraform plan
```

Terraform's current import mechanisms should be checked in the Terraform
version and provider documentation being used.

AWS VPC reference:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

------------------------------------------------------------------------

# 58. Complete AWS Terraform Example

Directory:

``` text
terraform-aws-example/
|
+-- terraform.tf
+-- providers.tf
+-- variables.tf
+-- main.tf
+-- outputs.tf
```

## `terraform.tf`

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

## `providers.tf`

``` hcl
provider "aws" {
  region = var.aws_region
}
```

## `variables.tf`

``` hcl
variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "Public subnet CIDR"
  default     = "10.0.1.0/24"
}
```

## `main.tf`

``` hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform-training-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-training-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "terraform-training-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "terraform-training-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "terraform-training-web"
  description = "Web security group"
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
    Name = "terraform-training-web-sg"
  }
}

resource "aws_s3_bucket" "training" {
  bucket_prefix = "terraform-training-"

  tags = {
    Name = "terraform-training-s3"
  }
}
```

## `outputs.tf`

``` hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Web security group ID"
  value       = aws_security_group.web.id
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.training.id
}
```

------------------------------------------------------------------------

# 59. Run the Complete Example

Open the directory:

``` bash
cd terraform-aws-example
```

Initialize:

``` bash
terraform init
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

Apply:

``` bash
terraform apply
```

Enter:

``` text
yes
```

Show outputs:

``` bash
terraform output
```

Example:

``` text
public_subnet_id = "subnet-xxxxxxxx"
s3_bucket_name = "terraform-training-xxxx"
security_group_id = "sg-xxxxxxxx"
vpc_id = "vpc-xxxxxxxx"
```

List state:

``` bash
terraform state list
```

------------------------------------------------------------------------

# 60. Verify Using AWS CLI

VPC:

``` bash
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=terraform-training-vpc"
```

Subnet:

``` bash
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=terraform-training-public"
```

Security group:

``` bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=terraform-training-web"
```

S3:

``` bash
aws s3api list-buckets
```

------------------------------------------------------------------------

# 61. Destroy the Lab

After completing the exercise:

``` bash
terraform destroy
```

Enter:

``` text
yes
```

Confirm the resources were removed.

For example:

``` bash
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=terraform-training-vpc"
```

------------------------------------------------------------------------

# 62. Practical Exercise: Secure S3

Create:

``` text
S3 bucket
Versioning
Public access block
Encryption
Lifecycle
```

Implement it:

1.  Manually through the AWS Console.
2.  With AWS CLI.
3.  With Terraform.

Compare the three approaches.

------------------------------------------------------------------------

# 63. Practical Exercise: VPC

Create:

``` text
VPC
2 subnets
Internet Gateway
Route Table
Security Group
```

Terraform resources:

``` text
aws_vpc
aws_subnet
aws_internet_gateway
aws_route_table
aws_route_table_association
aws_security_group
```

Verify with:

``` bash
terraform state list
```

and:

``` bash
aws ec2 describe-vpcs
aws ec2 describe-subnets
aws ec2 describe-route-tables
aws ec2 describe-security-groups
```

------------------------------------------------------------------------

# 64. Practical Exercise: EC2 with IAM Role

Build:

``` text
VPC
 |
Public subnet
 |
Security group
 |
EC2
 |
IAM Role
```

The EC2 instance should use the IAM role for AWS API access.

Do not put AWS access keys in the instance.

------------------------------------------------------------------------

# 65. Practical Exercise: EC2 to S3

Build:

``` text
EC2
 |
IAM Role
 |
IAM Policy
 |
S3
```

Allow:

``` text
s3:GetObject
```

only on:

``` text
arn:aws:s3:::training-bucket/*
```

Test access from the instance.

Then test an unrelated S3 operation.

This demonstrates least privilege.

------------------------------------------------------------------------

# 66. Practical Exercise: Variables

Create:

``` hcl
variable "environment" {
  type    = string
  default = "dev"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
```

Use:

``` hcl
tags = {
  Environment = var.environment
}
```

Run:

``` bash
terraform apply \
  -var="environment=test" \
  -var="instance_type=t3.micro"
```

------------------------------------------------------------------------

# 67. Practical Exercise: `for_each`

``` hcl
variable "bucket_names" {
  type = set(string)

  default = [
    "logs",
    "reports",
    "backups"
  ]
}

resource "aws_s3_bucket" "example" {
  for_each = var.bucket_names

  bucket_prefix = "${each.key}-training-"
}
```

Run:

``` bash
terraform plan
terraform apply
terraform state list
```

------------------------------------------------------------------------

# 68. Practical Exercise: Module

Create:

``` text
modules/
└── vpc/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

Root module:

``` hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = "10.0.0.0/16"
}
```

Use module output:

``` hcl
resource "aws_subnet" "public" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.0.1.0/24"
}
```

------------------------------------------------------------------------

# 69. Common Errors

## Provider not installed

Run:

``` bash
terraform init
```

------------------------------------------------------------------------

## Configuration error

Run:

``` bash
terraform fmt
terraform validate
```

Read the exact file and line number in the error.

------------------------------------------------------------------------

## AWS AccessDenied

Check:

``` bash
aws sts get-caller-identity
```

Then inspect:

-   IAM policy
-   Resource policy
-   SCP
-   Permission boundary
-   KMS policy
-   AWS region
-   Explicit denies

------------------------------------------------------------------------

## Wrong region

Check:

``` bash
aws configure get region
```

Check the Terraform provider:

``` hcl
provider "aws" {
  region = var.aws_region
}
```

------------------------------------------------------------------------

## Resource already exists

If the resource was created manually, either remove the lab resource or
import it into Terraform.

------------------------------------------------------------------------

## Terraform wants to replace a resource

Look for:

``` text
-/+
```

This indicates replacement.

Understand why replacement is required before applying the plan.

------------------------------------------------------------------------

# 70. Terraform vs AWS Console

  -----------------------------------------------------------------------
  AWS Console                         Terraform
  ----------------------------------- -----------------------------------
  Manual                              Automated

  Interactive                         Configuration-driven

  Harder to reproduce                 Reproducible

  Good for exploration                Good for repeatable environments

  Changes can be undocumented         Configuration can be version
                                      controlled

  Easy to start                       Requires IaC knowledge
  -----------------------------------------------------------------------

A useful learning sequence is:

``` text
AWS Console
     |
Understand the service
     |
AWS CLI
     |
Understand API-style operations
     |
Terraform
     |
Automate infrastructure
```

------------------------------------------------------------------------

# 71. Terraform vs CloudFormation

Terraform:

``` text
Multi-provider
AWS
Azure
GCP
Kubernetes
SaaS
Other APIs
```

CloudFormation:

``` text
AWS-focused
```

Terraform uses providers.

CloudFormation is AWS's native Infrastructure as Code service.

For AWS certification preparation, learn the AWS architecture first and
then learn how Terraform represents that architecture.

------------------------------------------------------------------------

# 72. Recommended Terraform Project Structure

Small project:

``` text
terraform/
|
+-- terraform.tf
+-- providers.tf
+-- variables.tf
+-- main.tf
+-- outputs.tf
+-- terraform.tfvars
```

Larger project:

``` text
terraform/
|
+-- terraform.tf
+-- providers.tf
+-- variables.tf
+-- locals.tf
+-- network.tf
+-- security.tf
+-- compute.tf
+-- storage.tf
+-- database.tf
+-- monitoring.tf
+-- outputs.tf
```

HashiCorp's style guidance recommends clear logical organization as
configurations grow.

Reference: https://developer.hashicorp.com/terraform/language/style

------------------------------------------------------------------------

# 73. Recommended Learning Method

For every AWS service:

### Step 1

Create the resource manually.

### Step 2

Inspect it using AWS CLI.

### Step 3

Write the Terraform configuration.

### Step 4

Run:

``` bash
terraform fmt
terraform validate
terraform plan
```

### Step 5

Apply:

``` bash
terraform apply
```

### Step 6

Compare:

``` text
Console
CLI
Terraform
```

### Step 7

Change one attribute.

### Step 8

Run:

``` bash
terraform plan
```

Observe the proposed change.

### Step 9

Apply it.

### Step 10

Destroy the lab.

This sequence builds both AWS knowledge and Infrastructure as Code
skills.

------------------------------------------------------------------------

# 74. Terraform Command Cheat Sheet

``` bash
terraform version
```

Check version.

``` bash
terraform init
```

Initialize project.

``` bash
terraform fmt
```

Format configuration.

``` bash
terraform validate
```

Validate configuration.

``` bash
terraform plan
```

Preview changes.

``` bash
terraform apply
```

Apply changes.

``` bash
terraform destroy
```

Destroy managed infrastructure.

``` bash
terraform show
```

Display state/configuration information.

``` bash
terraform output
```

Display outputs.

``` bash
terraform state list
```

List resources in state.

``` bash
terraform state show RESOURCE
```

Inspect a resource.

``` bash
terraform providers
```

Display providers.

``` bash
terraform graph
```

Generate a dependency graph.

``` bash
terraform console
```

Evaluate Terraform expressions interactively.

``` bash
terraform import
```

Import an existing resource.

------------------------------------------------------------------------

# 75. Final Mental Model

Remember Terraform as:

``` text
                  YOU
                   |
                   v
            Terraform .tf files
                   |
                   v
            terraform plan
                   |
                   v
             Proposed changes
                   |
                   v
            terraform apply
                   |
                   v
                Provider
                   |
                   v
                AWS APIs
                   |
                   v
             AWS Resources
                   |
                   v
             Terraform State
                   |
                   +------> Next plan
```

The most important concept is:

> Terraform configuration describes the desired infrastructure.
> Terraform compares that desired configuration with its knowledge of
> existing infrastructure and determines the changes required to reach
> the desired state.

------------------------------------------------------------------------

# 76. Official Documentation

## Terraform

https://developer.hashicorp.com/terraform/intro

https://developer.hashicorp.com/terraform/language

https://developer.hashicorp.com/terraform/language/syntax/configuration

https://developer.hashicorp.com/terraform/language/files

https://developer.hashicorp.com/terraform/language/providers

https://developer.hashicorp.com/terraform/language/resources

https://developer.hashicorp.com/terraform/language/style

https://developer.hashicorp.com/terraform/language/values/variables

https://developer.hashicorp.com/terraform/language/values/outputs

## AWS Provider

https://registry.terraform.io/providers/hashicorp/aws/latest/docs

## AWS VPC Resource

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

## AWS EC2 Resource

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

------------------------------------------------------------------------

# 77. Completion Exercise

Build this architecture completely with Terraform:

``` text
AWS Region
   |
   +-- VPC: 10.0.0.0/16
          |
          +-- Public Subnet
          |      |
          |      +-- Internet Gateway
          |      +-- Route Table
          |      +-- Security Group
          |      +-- EC2
          |
          +-- Private Subnet
          |
          +-- S3 Bucket
```

Requirements:

1.  Use variables for region and CIDRs.
2.  Use outputs for VPC ID and S3 bucket name.
3.  Use tags.
4.  Use an IAM role for EC2.
5.  Do not put AWS access keys in Terraform.
6.  Use a data source for the Ubuntu AMI.
7.  Use a security group allowing only required traffic.
8.  Run `terraform fmt`.
9.  Run `terraform validate`.
10. Run `terraform plan`.
11. Run `terraform apply`.
12. Verify using AWS CLI.
13. Modify one resource.
14. Run `terraform plan` again.
15. Observe the proposed change.
16. Apply the change.
17. Run `terraform state list`.
18. Run `terraform destroy`.
19. Confirm the AWS resources were removed.

------------------------------------------------------------------------

# End of Terraform Student Documentation
