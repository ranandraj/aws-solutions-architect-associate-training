# AWS VPC Endpoints

## Concepts, Architecture, Console, AWS CLI and Terraform

## 1. Overview

A VPC endpoint provides private connectivity from a VPC to supported AWS
services or PrivateLink destinations without requiring the workload to
use a public Internet path.

For SAA-C03, focus especially on:

-   Gateway VPC endpoints for Amazon S3 and DynamoDB
-   Interface VPC endpoints using AWS PrivateLink
-   Private DNS
-   Endpoint network interfaces
-   Security groups
-   Endpoint policies
-   Route-table integration
-   High availability across Availability Zones
-   VPC endpoint versus NAT Gateway

AWS also supports Gateway Load Balancer, resource, and service-network
endpoint types. The core SAA-C03 distinction is Gateway versus
Interface.

Official concepts:
https://docs.aws.amazon.com/vpc/latest/privatelink/concepts.html

------------------------------------------------------------------------

## 2. What is a VPC Endpoint?

A VPC endpoint is a logical connection between a VPC and a supported AWS
service, endpoint service, resource, or service network.

Typical architecture:

``` text
Private EC2
    |
    v
VPC Endpoint
    |
    v
AWS Service
```

Without an endpoint, a private-subnet workload may need a NAT Gateway
for AWS service access. With an appropriate endpoint, traffic can remain
on AWS private connectivity.

AWS PrivateLink documentation:
https://docs.aws.amazon.com/vpc/latest/privatelink/privatelink-access-aws-services.html

------------------------------------------------------------------------

## 3. Endpoint Types

  --------------------------------------------------------------------------
  Type              Purpose              Mechanism         SAA-C03
                                                           importance
  ----------------- -------------------- ----------------- -----------------
  Gateway           S3 and DynamoDB      Route table +     Very High
                                         AWS-managed       
                                         prefix list       

  Interface         Many AWS services    ENI + private     Very High
                    and PrivateLink      IP + PrivateLink  
                    services                               

  Gateway Load      Virtual appliances   Route-based       Medium
  Balancer                                                 

  Resource          Supported resources  PrivateLink       Lower
                    in another VPC                         

  Service Network   Services/resources   Private           Lower
                    in a service network connectivity      
  --------------------------------------------------------------------------

AWS reference:
https://docs.aws.amazon.com/vpc/latest/privatelink/concepts.html

------------------------------------------------------------------------

# 4. Gateway VPC Endpoint

Gateway endpoints provide private connectivity to:

-   Amazon S3
-   Amazon DynamoDB

They do not use AWS PrivateLink.

They use VPC route tables. When a gateway endpoint is associated with a
route table, AWS adds a route using an AWS-managed prefix list.

``` text
EC2
 |
 v
Private Route Table
 |
 v
S3 Gateway Endpoint
 |
 v
Amazon S3
```

Gateway endpoints have no additional endpoint charge.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html

------------------------------------------------------------------------

# 5. Interface VPC Endpoint

Interface endpoints use AWS PrivateLink.

AWS creates requester-managed network interfaces in the selected
subnets. Each endpoint ENI receives a private IP address.

``` text
EC2
 |
 | TCP 443
 v
Endpoint ENI
 |
 v
AWS PrivateLink
 |
 v
AWS Service
```

You can select one subnet per Availability Zone.

Interface endpoints are billed for hourly usage in each Availability
Zone and data processing.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html

------------------------------------------------------------------------

# 6. Gateway vs Interface Endpoint

  -----------------------------------------------------------------------
  Feature                 Gateway                 Interface
  ----------------------- ----------------------- -----------------------
  Main services           S3, DynamoDB            Many AWS services

  Technology              VPC routing             AWS PrivateLink

  Endpoint ENI            No                      Yes

  Private IP              Not through endpoint    Yes
                          ENI                     

  Route table association Required                Not used as the
                                                  endpoint mechanism

  Security group          No                      Yes

  Private DNS             Not the normal model    Yes

  On-premises access      No                      Supported for eligible
                                                  services

  Cross-region use        No for gateway model    Supported for eligible
                                                  PrivateLink services

  Cost                    No additional endpoint  Hourly + data
                          charge                  processing

  S3                      Yes                     Yes

  DynamoDB                Yes                     Service-dependent
                                                  interface support
  -----------------------------------------------------------------------

S3 comparison:
https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-s3.html

------------------------------------------------------------------------

# 7. VPC Endpoint vs NAT Gateway

  -------------------------------------------------------------------------
  Requirement       Gateway Endpoint  Interface Endpoint  NAT Gateway
  ----------------- ----------------- ------------------- -----------------
  Private EC2 -\>   Best fit          Possible            Works but
  S3                                                      unnecessary for
                                                          endpoint
                                                          architecture

  Private EC2 -\>   Best fit          Service-dependent   Works but
  DynamoDB                                                unnecessary

  Private EC2 -\>   Not applicable    Best fit            Possible
  SSM                                                     

  Private EC2 -\>   Not applicable    Best fit            Possible only if
  supported                                               service has
  PrivateLink                                             public access and
  service                                                 architecture
                                                          permits

  Private EC2 -\>   No                No                  Yes
  Internet                                                

  General outbound  No                No                  Yes
  Internet                                                

  Endpoint ENI      No                Yes                 NAT has its own
                                                          network interface

  Additional        No                Yes                 NAT charges apply
  endpoint charge                                         
  -------------------------------------------------------------------------

A VPC endpoint is not a replacement for NAT Gateway for arbitrary
Internet access.

------------------------------------------------------------------------

# 8. Interface Endpoint DNS

With private DNS enabled, a normal AWS service hostname can resolve to
the private IP addresses of the endpoint ENIs.

Example:

``` text
ssm.ap-south-1.amazonaws.com
             |
             v
Private DNS
             |
             v
10.0.1.50 / 10.0.2.50
             |
             v
Interface Endpoint
```

AWS recommends private DNS for normal AWS service access through
interface endpoints.

The VPC must have DNS resolution and DNS hostnames enabled.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/privatelink/interface-endpoints.html

------------------------------------------------------------------------

# 9. Endpoint Security Groups

Interface endpoint ENIs use security groups.

For HTTPS-based AWS service access, a common rule is:

``` text
Inbound
Protocol: TCP
Port: 443
Source: Application security group
```

Example:

``` text
EC2 SG
  |
  | TCP 443
  v
Endpoint SG
  |
  v
Endpoint ENI
```

Also check network ACLs when troubleshooting.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html

------------------------------------------------------------------------

# 10. Endpoint Policies

An endpoint policy is a resource-based IAM policy attached to a VPC
endpoint.

It controls which principals can use the endpoint to access the service.

The default policy allows full access:

``` json
{
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```

An endpoint policy does not replace IAM identity policies or service
resource policies.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-access.html

------------------------------------------------------------------------

# 11. Console: Create an S3 Gateway Endpoint

## Step 1

Open:

https://console.aws.amazon.com/vpc/

Select the required Region.

## Step 2

Choose:

``` text
VPC -> Endpoints -> Create endpoint
```

## Step 3

Choose:

``` text
Service category: AWS services
Service type: Gateway
```

Select:

``` text
com.amazonaws.<region>.s3
```

Example:

``` text
com.amazonaws.ap-south-1.s3
```

## Step 4

Select the VPC.

## Step 5

Select the private route tables that should use the endpoint.

Example:

``` text
private-route-table-a
private-route-table-b
```

## Step 6

Choose endpoint policy:

``` text
Full Access
```

for a lab, or configure a custom policy for controlled access.

## Step 7

Add tags:

``` text
Name = s3-gateway-endpoint
Environment = lab
```

## Step 8

Choose:

``` text
Create endpoint
```

## Step 9: Verify

Open:

``` text
VPC -> Route Tables -> private-route-table -> Routes
```

You should see an entry similar to:

``` text
Destination: pl-xxxxxxxx
Target: vpce-xxxxxxxx
```

AWS automatically manages this endpoint route.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html

------------------------------------------------------------------------

# 12. Test the S3 Gateway Endpoint

From an EC2 instance in an associated private subnet:

``` bash
aws s3 ls
```

Or:

``` bash
aws s3 ls s3://your-bucket-name
```

The request still requires appropriate IAM and S3 resource permissions.

Verify:

``` bash
aws ec2 describe-vpc-endpoints   --vpc-endpoint-ids vpce-xxxxxxxx
```

------------------------------------------------------------------------

# 13. Console: Create an Interface Endpoint

Example: Systems Manager.

## Step 1: Create Endpoint Security Group

Create:

``` text
vpce-ssm-sg
```

Allow:

``` text
HTTPS
TCP 443
Source: application/EC2 security group
```

## Step 2

Open:

``` text
VPC -> Endpoints -> Create endpoint
```

## Step 3

Choose:

``` text
AWS services
```

Select an interface service, for example:

``` text
com.amazonaws.ap-south-1.ssm
```

## Step 4

Select the VPC.

## Step 5

Select one private subnet per required Availability Zone.

Example:

``` text
ap-south-1a -> private-subnet-a
ap-south-1b -> private-subnet-b
```

## Step 6

Select:

``` text
vpce-ssm-sg
```

## Step 7

Enable:

``` text
Enable DNS name
```

This enables normal service DNS resolution through the private endpoint.

## Step 8

Choose an endpoint policy.

For a lab:

``` text
Full Access
```

For production, restrict actions/resources as required.

## Step 9

Choose:

``` text
Create endpoint
```

AWS procedure:
https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html

------------------------------------------------------------------------

# 14. Verify Interface Endpoint ENIs

Open:

``` text
EC2 -> Network Interfaces
```

Search for the endpoint.

You should see requester-managed ENIs with private IP addresses.

CLI:

``` bash
aws ec2 describe-vpc-endpoints   --vpc-endpoint-ids vpce-xxxxxxxx
```

Check:

``` text
State
VpcEndpointType
SubnetIds
NetworkInterfaceIds
Groups
PrivateDnsEnabled
DnsEntries
```

------------------------------------------------------------------------

# 15. AWS CLI: Gateway Endpoint

Identify the VPC:

``` bash
aws ec2 describe-vpcs
```

Identify the route table:

``` bash
aws ec2 describe-route-tables
```

Create the S3 endpoint:

``` bash
aws ec2 create-vpc-endpoint   --vpc-id vpc-xxxxxxxx   --vpc-endpoint-type Gateway   --service-name com.amazonaws.ap-south-1.s3   --route-table-ids rtb-xxxxxxxx
```

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/ec2/create-vpc-endpoint.html

------------------------------------------------------------------------

# 16. AWS CLI: Interface Endpoint

``` bash
aws ec2 create-vpc-endpoint   --vpc-id vpc-xxxxxxxx   --vpc-endpoint-type Interface   --service-name com.amazonaws.ap-south-1.ssm   --subnet-ids subnet-aaaaaaaa subnet-bbbbbbbb   --security-group-ids sg-xxxxxxxx   --private-dns-enabled
```

Important options:

  CLI option                Purpose
  ------------------------- --------------------------------------------
  `--vpc-id`                Target VPC
  `--vpc-endpoint-type`     Gateway or Interface
  `--service-name`          AWS service
  `--route-table-ids`       Used by gateway endpoints
  `--subnet-ids`            Used by interface endpoints
  `--security-group-ids`    Interface endpoint ENI security groups
  `--private-dns-enabled`   Enables private DNS for interface endpoint
  `--policy-document`       Endpoint policy

AWS CLI reference:
https://docs.aws.amazon.com/cli/latest/reference/ec2/create-vpc-endpoint.html

------------------------------------------------------------------------

# 17. AWS CLI: Verify

``` bash
aws ec2 describe-vpc-endpoints
```

For a specific endpoint:

``` bash
aws ec2 describe-vpc-endpoints   --vpc-endpoint-ids vpce-xxxxxxxx
```

Filter by VPC:

``` bash
aws ec2 describe-vpc-endpoints   --filters Name=vpc-id,Values=vpc-xxxxxxxx
```

For an interface endpoint, inspect:

``` text
State
SubnetIds
NetworkInterfaceIds
Groups
DnsEntries
PrivateDnsEnabled
```

------------------------------------------------------------------------

# 18. AWS CLI: Modify and Delete

Add a security group:

``` bash
aws ec2 modify-vpc-endpoint   --vpc-endpoint-id vpce-xxxxxxxx   --add-security-group-ids sg-yyyyyyyy
```

Enable private DNS:

``` bash
aws ec2 modify-vpc-endpoint   --vpc-endpoint-id vpce-xxxxxxxx   --private-dns-enabled
```

Delete:

``` bash
aws ec2 delete-vpc-endpoints   --vpc-endpoint-ids vpce-xxxxxxxx
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/privatelink/interface-endpoints.html

------------------------------------------------------------------------

# 19. Terraform

Terraform uses the AWS provider resource:

``` hcl
resource "aws_vpc_endpoint" "example" {
  ...
}
```

Official Terraform resource:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint

The current AWS provider documentation exposes attributes including
`route_table_ids`, `subnet_ids`, `security_group_ids`,
`private_dns_enabled`, `policy`, `dns_entry`, `network_interface_ids`,
and `prefix_list_id`.

------------------------------------------------------------------------

# 20. Terraform: S3 Gateway Endpoint

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

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-endpoint-demo"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-south-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "s3-gateway-endpoint"
  }
}
```

------------------------------------------------------------------------

# 21. Terraform: DynamoDB Gateway Endpoint

``` hcl
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-south-1.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "dynamodb-gateway-endpoint"
  }
}
```

------------------------------------------------------------------------

# 22. Terraform: Interface Endpoint

``` hcl
resource "aws_security_group" "vpce" {
  name        = "vpce-ssm-sg"
  description = "Security group for SSM interface endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-south-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true

  tags = {
    Name = "ssm-interface-endpoint"
  }
}
```

For production multi-AZ deployment:

``` hcl
subnet_ids = [
  aws_subnet.private_a.id,
  aws_subnet.private_b.id
]
```

------------------------------------------------------------------------

# 23. Terraform: Endpoint Policy

``` hcl
data "aws_iam_policy_document" "s3_endpoint" {
  statement {
    sid    = "AllowS3Access"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = ["*"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-south-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  policy = data.aws_iam_policy_document.s3_endpoint.json
}
```

------------------------------------------------------------------------

# 24. Terraform Workflow

``` bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Verify state:

``` bash
terraform state list
```

Destroy lab resources:

``` bash
terraform destroy
```

Expected resources may include:

``` text
aws_vpc.main
aws_subnet.private
aws_route_table.private
aws_route_table_association.private
aws_vpc_endpoint.s3
```

------------------------------------------------------------------------

# 25. High Availability

For interface endpoints, deploy endpoint ENIs across multiple
Availability Zones when the application spans multiple AZs.

``` text
VPC
 |
 +-- AZ-a
 |    |
 |    +-- EC2
 |    +-- Endpoint ENI
 |
 +-- AZ-b
      |
      +-- EC2
      +-- Endpoint ENI
              |
              v
        AWS PrivateLink
              |
              v
          AWS Service
```

AWS allows one subnet per Availability Zone for an interface endpoint.

Reference:
https://docs.aws.amazon.com/vpc/latest/privatelink/interface-endpoints.html

------------------------------------------------------------------------

# 26. Troubleshooting

## Interface endpoint timeout

Check:

``` text
Endpoint state
Security group TCP 443
Network ACL
Subnet routing
DNS
Private DNS
IAM permissions
Endpoint policy
Service support
```

## DNS problem

Verify:

``` text
enableDnsSupport = true
enableDnsHostnames = true
Private DNS = enabled
```

Test:

``` bash
nslookup ssm.ap-south-1.amazonaws.com
```

or:

``` bash
dig ssm.ap-south-1.amazonaws.com
```

## S3 gateway endpoint problem

Check:

``` text
Correct VPC
Correct route table
Subnet association with route table
Endpoint state
Endpoint policy
IAM policy
S3 bucket policy
```

Remember that a gateway endpoint is associated with route tables, not
directly with subnets.

------------------------------------------------------------------------

# 27. Security Architecture

A VPC endpoint does not automatically grant access.

A request may be affected by:

``` text
IAM identity policy
        +
Endpoint policy
        +
Service resource policy
        +
SCP / other organization controls
        +
Network controls
```

For S3, a bucket policy can restrict access through a specific endpoint
using `aws:sourceVpce`.

Example pattern:

``` json
"Condition": {
  "StringNotEquals": {
    "aws:sourceVpce": "vpce-xxxxxxxx"
  }
}
```

Use explicit Deny carefully because an incorrect Deny can block
legitimate access paths.

AWS endpoint-policy documentation:
https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-access.html

------------------------------------------------------------------------

# 28. SAA-C03 Exam Points

  -----------------------------------------------------------------------
  Question pattern                    Correct concept
  ----------------------------------- -----------------------------------
  Private EC2 -\> S3 without NAT      S3 Gateway Endpoint

  Private EC2 -\> DynamoDB without    DynamoDB Gateway Endpoint
  NAT                                 

  Private EC2 -\> SSM privately       Interface Endpoint

  AWS service does not support        Interface Endpoint if supported
  gateway endpoint                    

  PrivateLink service in another      Interface Endpoint
  account                             

  Endpoint implemented through route  Gateway Endpoint
  tables                              

  Endpoint has ENIs/private IPs       Interface Endpoint

  Need normal AWS hostname to resolve Private DNS on Interface Endpoint
  privately                           

  Need endpoint-level access          Endpoint Policy
  restriction                         

  Need arbitrary Internet access      NAT Gateway/Internet architecture,
                                      not VPC endpoint

  Need no additional endpoint charge  Gateway Endpoint
  for S3/DynamoDB                     

  Need private connectivity from      Interface Endpoint plus VPN/Direct
  on-premises to supported            Connect connectivity
  PrivateLink service                 
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 29. Key Architecture Decision Table

  -----------------------------------------------------------------------
  Requirement                         Recommended solution
  ----------------------------------- -----------------------------------
  Private EC2 to S3                   Gateway endpoint

  Private EC2 to DynamoDB             Gateway endpoint

  Private EC2 to Systems Manager      Interface endpoint

  Private EC2 to supported AWS API    Interface endpoint

  Private EC2 to third-party          Interface endpoint
  PrivateLink service                 

  Private EC2 to arbitrary Internet   NAT Gateway

  Public subnet to Internet           Internet Gateway

  Restrict S3 to a VPC endpoint       Endpoint + S3 bucket policy

  Avoid NAT for S3/DynamoDB           Gateway endpoint

  Multi-AZ private service access     Interface endpoint ENIs in multiple
                                      AZs
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 30. Official AWS Documentation by Topic

  ------------------------------------------------------------------------------------------------------------------------------
  Topic                               AWS documentation
  ----------------------------------- ------------------------------------------------------------------------------------------
  PrivateLink concepts                https://docs.aws.amazon.com/vpc/latest/privatelink/concepts.html

  PrivateLink overview                https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html

  Access AWS services through         https://docs.aws.amazon.com/vpc/latest/privatelink/privatelink-access-aws-services.html
  PrivateLink                         

  Gateway endpoints                   https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html

  S3 gateway endpoints                https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-s3.html

  Create interface endpoint           https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html

  Configure interface endpoint        https://docs.aws.amazon.com/vpc/latest/privatelink/interface-endpoints.html

  Endpoint policies                   https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-access.html

  AWS CLI create-vpc-endpoint         https://docs.aws.amazon.com/cli/latest/reference/ec2/create-vpc-endpoint.html

  Terraform aws_vpc_endpoint          https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
  ------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 31. Final Summary

``` text
Gateway Endpoint
    |
    +-- S3 / DynamoDB
    +-- Route tables
    +-- AWS-managed prefix list
    +-- Does not use PrivateLink
    +-- No additional endpoint charge

Interface Endpoint
    |
    +-- AWS PrivateLink
    +-- ENI
    +-- Private IP
    +-- Security group
    +-- Private DNS
    +-- Hourly + data processing charges
```

The key SAA-C03 rule is:

**Use a Gateway VPC Endpoint for S3 or DynamoDB when the gateway model
meets the requirement. Use an Interface VPC Endpoint when private
connectivity through AWS PrivateLink is required for a supported service
or endpoint service. Use NAT Gateway when the private workload needs
general outbound Internet access.**
