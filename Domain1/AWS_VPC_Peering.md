# AWS VPC Peering

## Concepts, Architecture, Management Console, AWS CLI and Terraform

## 1. Overview

Amazon VPC Peering is a networking connection between two VPCs that
allows resources in the VPCs to communicate using private IPv4 or IPv6
addresses.

A VPC peering connection can connect:

-   VPCs in the same AWS account
-   VPCs in different AWS accounts
-   VPCs in the same AWS Region
-   VPCs in different AWS Regions

Traffic between peered VPCs does not traverse the public Internet. AWS
provides a direct network path between the VPCs using the existing AWS
network infrastructure.

AWS defines VPC peering as a one-to-one relationship between two VPCs.
It is not a transit mechanism, so VPC peering does not support
transitive routing.

Official AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html

------------------------------------------------------------------------

# 2. VPC Peering Architecture

Consider two VPCs:

``` text
VPC A                                      VPC B
10.0.0.0/16                               10.1.0.0/16

+-------------------+                     +-------------------+
| Private Subnet    |                     | Private Subnet    |
| 10.0.1.0/24       |                     | 10.1.1.0/24       |
|                   |                     |                   |
| EC2-A             |                     | EC2-B             |
| 10.0.1.10         |                     | 10.1.1.10         |
+---------+---------+                     +---------+---------+
          |                                         |
          |                                         |
          +----------- VPC Peering -----------------+
                     pcx-xxxxxxxx
```

The peering connection alone does not make traffic flow.

You must configure routes in the route tables of both VPCs.

``` text
VPC A Route Table
Destination       Target
10.0.0.0/16       local
10.1.0.0/16       pcx-xxxxxxxx


VPC B Route Table
Destination       Target
10.1.0.0/16       local
10.0.0.0/16       pcx-xxxxxxxx
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-routing.html

------------------------------------------------------------------------

# 3. Key Characteristics

  Characteristic                 VPC Peering
  ------------------------------ -------------
  Connects                       Two VPCs
  Same Region                    Yes
  Different Regions              Yes
  Different AWS accounts         Yes
  Uses private IP addressing     Yes
  Uses public Internet           No
  Requires VPN                   No
  Requires Internet Gateway      No
  Requires NAT Gateway           No
  Requires route-table entries   Yes
  Supports IPv4                  Yes
  Supports IPv6                  Yes
  Transitive routing             No
  CIDR overlap allowed           No
  Security groups                Still apply
  Network ACLs                   Still apply
  One-to-one relationship        Yes
  Direct network path            Yes

AWS reference:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html

------------------------------------------------------------------------

# 4. VPC Peering Is Not a Router

A common SAA-C03 mistake is treating VPC peering as a transit network.

Suppose:

``` text
VPC A
  |
  | Peering
  |
VPC B
  |
  | Peering
  |
VPC C
```

You cannot use VPC B as a router to allow:

``` text
VPC A -> VPC B -> VPC C
```

VPC peering is not transitive.

If VPC A must communicate directly with VPC C, create another peering
connection:

``` text
        VPC A
       /     \
      /       \
     v         v
 VPC B       VPC C
```

For large numbers of VPCs or hub-and-spoke connectivity, consider AWS
Transit Gateway.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html

------------------------------------------------------------------------

# 5. CIDR Block Requirement

The VPCs must have non-overlapping CIDR blocks.

Valid:

``` text
VPC A: 10.0.0.0/16
VPC B: 10.1.0.0/16
```

Invalid:

``` text
VPC A: 10.0.0.0/16
VPC B: 10.0.0.0/16
```

Also invalid:

``` text
VPC A: 10.0.0.0/16
VPC B: 10.0.1.0/24
```

The second CIDR is contained within the first and therefore overlaps.

AWS does not allow VPC peering between VPCs with overlapping IPv4 or
IPv6 CIDR blocks.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html

------------------------------------------------------------------------

# 6. VPC Peering Traffic Flow

Assume:

``` text
VPC A = 10.0.0.0/16
VPC B = 10.1.0.0/16

EC2-A = 10.0.1.10
EC2-B = 10.1.1.10
```

EC2-A sends traffic to:

``` text
10.1.1.10
```

The route table checks:

``` text
10.1.0.0/16 -> pcx-xxxxxxxx
```

The traffic is sent through the peering connection.

The response from EC2-B requires a corresponding route:

``` text
10.0.0.0/16 -> pcx-xxxxxxxx
```

Therefore, VPC peering requires routing in both directions.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-routing.html

------------------------------------------------------------------------

# 7. VPC Peering and Security Groups

VPC peering does not bypass security controls.

You still need appropriate:

-   Security group rules
-   Network ACL rules
-   Host-level firewall rules
-   Application-level permissions

Example:

``` text
EC2-A
10.0.1.10
   |
   | TCP 3306
   v
EC2-B
10.1.1.10
```

The database instance's security group must permit the required traffic.

For same-Region peering, AWS allows security group references across the
peering connection.

Example:

``` text
Inbound rule on DB Security Group

Type: MySQL/Aurora
Port: 3306
Source: EC2-A security group
```

This is preferable to unnecessarily opening:

``` text
10.0.0.0/16
```

when the architecture allows a security-group reference.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html

------------------------------------------------------------------------

# 8. VPC Peering and Route Tables

A route table controls traffic leaving a subnet.

For VPC peering, add a route where:

``` text
Destination = Peer VPC CIDR
Target      = VPC Peering Connection
```

Example:

``` text
VPC A route table

Destination       Target
10.0.0.0/16       local
10.1.0.0/16       pcx-12345678
```

And:

``` text
VPC B route table

Destination       Target
10.1.0.0/16       local
10.0.0.0/16       pcx-12345678
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-routing.html

------------------------------------------------------------------------

# 9. VPC Peering vs Transit Gateway

  -----------------------------------------------------------------------
  Feature                 VPC Peering             Transit Gateway
  ----------------------- ----------------------- -----------------------
  Basic model             Point-to-point          Central network hub

  Transitive routing      No                      Yes

  Number of VPCs          Suitable for smaller    Suitable for large
                          direct connectivity     networks

  Route management        Distributed across VPCs Centralized through TGW
                                                  route tables

  Hub-and-spoke           Not directly transitive Native design

  Cross-account           Yes                     Yes

  Cross-Region            Yes, peering supported  Supports inter-Region
                                                  TGW peering

  Best use                Direct VPC-to-VPC       Large multi-VPC
                          connectivity            architecture
  -----------------------------------------------------------------------

For SAA-C03, remember:

``` text
Few direct VPC connections
        -> VPC Peering

Many VPCs / centralized routing
        -> Transit Gateway
```

AWS VPC peering:
https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html

AWS Transit Gateway:
https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html

------------------------------------------------------------------------

# 10. VPC Peering vs Site-to-Site VPN

  -----------------------------------------------------------------------
  Feature                 VPC Peering             Site-to-Site VPN
  ----------------------- ----------------------- -----------------------
  Main purpose            VPC-to-VPC              Network-to-VPC

  Encryption              AWS private network;    IPsec VPN
                          inter-Region traffic is 
                          encrypted before        
                          leaving AWS facilities  

  Internet traversal      No                      VPN uses public
                                                  connectivity or
                                                  appropriate private
                                                  connectivity

  Connects on-premises    Not directly            Yes

  Requires Customer       No                      Yes
  Gateway                                         

  Requires Virtual        No                      Yes
  Private Gateway/Transit                         
  Gateway                                         

  Typical use             VPC-to-VPC              On-premises-to-AWS
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 11. VPC Peering vs PrivateLink

  ---------------------------------------------------------------------------
  Feature                 VPC Peering             AWS PrivateLink
  ----------------------- ----------------------- ---------------------------
  Main model              Network-to-network      Service-to-consumer

  Access scope            Can route to peer VPC   Access selected endpoint
                          CIDRs                   service

  Transitive              No                      Service-specific

  Consumer needs full     Yes, through routes     No
  network connectivity                            

  Endpoint ENI            No                      Interface endpoint ENI

  Common use              Application VPC to      Private access to a service
                          database VPC            

  CIDR overlap            Not allowed             PrivateLink can support
                                                  service-provider/consumer
                                                  scenarios without requiring
                                                  full VPC routing

  Technology              VPC networking          PrivateLink
  ---------------------------------------------------------------------------

------------------------------------------------------------------------

# 12. Types of VPC Peering

## Same-Region VPC Peering

``` text
Region: ap-south-1

VPC A
10.0.0.0/16
    |
    | PCX
    |
VPC B
10.1.0.0/16
```

## Inter-Region VPC Peering

``` text
Region A                         Region B

VPC A                            VPC B
10.0.0.0/16                      10.1.0.0/16
    |                                |
    +------ Inter-Region PCX --------+
```

AWS states that inter-Region peering allows resources to communicate
using private IP addresses without using a gateway, VPN, or network
appliance. Inter-Region traffic stays on the AWS global backbone.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html

------------------------------------------------------------------------

# 13. Same-Account vs Cross-Account Peering

  Feature                        Same Account   Cross Account
  ------------------------------ -------------- -------------------
  Requester creates connection   Yes            Yes
  Accepter accepts request       Yes            Yes
  Accepter account required      Same account   Different account
  Route configuration            Both VPCs      Both VPC owners
  Security groups                Apply          Apply
  CIDR overlap restriction       Yes            Yes

A peering request expires after 7 days if it is not accepted.

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/ec2/create-vpc-peering-connection.html

------------------------------------------------------------------------

# 14. Management Console Implementation

The following example creates:

``` text
VPC A
CIDR: 10.0.0.0/16

VPC B
CIDR: 10.1.0.0/16

Peering:
VPC A <-> VPC B
```

Assume both VPCs already exist.

------------------------------------------------------------------------

# 15. Step 1: Open VPC Console

Open:

https://console.aws.amazon.com/vpc/

Select the AWS Region containing the requester VPC.

Navigate to:

``` text
VPC
 -> Peering connections
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/create-vpc-peering-connection.html

------------------------------------------------------------------------

# 16. Step 2: Create Peering Connection

Choose:

``` text
Create peering connection
```

Configure:

``` text
Name:
vpc-a-to-vpc-b

VPC ID (Requester):
VPC-A
```

Under the accepter configuration:

``` text
Account:
My account
```

for same-account peering.

For cross-account:

``` text
Account:
Another account
```

Then provide the accepter AWS account ID.

For same-Region:

``` text
Region:
This Region
```

For inter-Region:

``` text
Region:
Another Region
```

Then select the accepter VPC.

Choose:

``` text
Create peering connection
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/create-vpc-peering-connection.html

------------------------------------------------------------------------

# 17. Step 3: Accept the Peering Request

Navigate to:

``` text
VPC
 -> Peering connections
```

Select the newly created connection.

Choose:

``` text
Actions
 -> Accept request
```

Confirm.

The state should become:

``` text
active
```

A peering connection is not usable for traffic until it is active and
the appropriate routes are configured.

------------------------------------------------------------------------

# 18. Step 4: Configure VPC A Route Table

Open:

``` text
VPC
 -> Route Tables
```

Select the route table associated with the subnet containing the source
instance.

Choose:

``` text
Routes
 -> Edit routes
 -> Add route
```

Configure:

``` text
Destination:
10.1.0.0/16

Target:
Peering Connection
pcx-xxxxxxxx
```

Save.

------------------------------------------------------------------------

# 19. Step 5: Configure VPC B Route Table

Select the route table associated with the destination subnet.

Add:

``` text
Destination:
10.0.0.0/16

Target:
Peering Connection
pcx-xxxxxxxx
```

Save.

You now have bidirectional routing.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-routing.html

------------------------------------------------------------------------

# 20. Step 6: Configure Security Groups

Suppose:

``` text
EC2-A
10.0.1.10

EC2-B
10.1.1.10
```

For ICMP testing, allow ICMP in the destination security group.

For application testing, use the required application port.

Example:

``` text
TCP 8080
Source: 10.0.0.0/16
```

A better same-Region design can use the source security group where
supported.

Do not use:

``` text
0.0.0.0/0
```

unless there is a specific requirement.

------------------------------------------------------------------------

# 21. Step 7: Test Connectivity

From EC2-A:

``` bash
ping 10.1.1.10
```

If ICMP is permitted.

For an application port:

``` bash
nc -vz 10.1.1.10 8080
```

Or:

``` bash
curl http://10.1.1.10:8080
```

The exact test depends on the service running on the destination
instance.

------------------------------------------------------------------------

# 22. Optional DNS Configuration

By default, public DNS hostnames used across a peering connection
resolve according to the default peering DNS behavior.

You can enable DNS resolution support on the peering connection so that
public EC2 DNS hostnames resolve to private IP addresses across the
peering connection.

Requirements include:

-   Both VPCs have DNS hostnames enabled.
-   Both VPCs have DNS resolution enabled.
-   Peering connection is active.
-   DNS options are enabled on both sides as appropriate.

Console path:

``` text
VPC
 -> Peering connections
 -> Select PCX
 -> Actions
 -> Edit DNS settings
```

Enable:

``` text
Requester DNS resolution
Accepter DNS resolution
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-dns.html

------------------------------------------------------------------------

# 23. AWS CLI Implementation

## Step 1: Identify VPCs

``` bash
aws ec2 describe-vpcs \
  --query 'Vpcs[*].[VpcId,CidrBlock,Tags]'
```

Example:

``` text
vpc-aaaa1111   10.0.0.0/16
vpc-bbbb2222   10.1.0.0/16
```

------------------------------------------------------------------------

# 24. Step 2: Create Same-Account Peering

``` bash
aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-aaaa1111 \
  --peer-vpc-id vpc-bbbb2222 \
  --region ap-south-1
```

The response returns:

``` text
VpcPeeringConnectionId
pcx-xxxxxxxx
```

The initial state is typically:

``` text
pending-acceptance
```

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/ec2/create-vpc-peering-connection.html

------------------------------------------------------------------------

# 25. Step 3: Accept the Peering Request

``` bash
aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id pcx-xxxxxxxx \
  --region ap-south-1
```

Check status:

``` bash
aws ec2 describe-vpc-peering-connections \
  --vpc-peering-connection-ids pcx-xxxxxxxx
```

Look for:

``` text
Status.Code: active
```

AWS CLI reference:
https://docs.aws.amazon.com/cli/latest/reference/ec2/accept-vpc-peering-connection.html

------------------------------------------------------------------------

# 26. Step 4: Add Route in VPC A

``` bash
aws ec2 create-route \
  --route-table-id rtb-aaaa1111 \
  --destination-cidr-block 10.1.0.0/16 \
  --vpc-peering-connection-id pcx-xxxxxxxx
```

------------------------------------------------------------------------

# 27. Step 5: Add Route in VPC B

``` bash
aws ec2 create-route \
  --route-table-id rtb-bbbb2222 \
  --destination-cidr-block 10.0.0.0/16 \
  --vpc-peering-connection-id pcx-xxxxxxxx
```

AWS route documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-routing.html

------------------------------------------------------------------------

# 28. Step 6: Enable DNS Resolution

Modify requester-side DNS options:

``` bash
aws ec2 modify-vpc-peering-connection-options \
  --vpc-peering-connection-id pcx-xxxxxxxx \
  --requester-peering-connection-options AllowDnsResolutionFromRemoteVpc=true
```

For the accepter side, use:

``` bash
aws ec2 modify-vpc-peering-connection-options \
  --vpc-peering-connection-id pcx-xxxxxxxx \
  --accepter-peering-connection-options AllowDnsResolutionFromRemoteVpc=true
```

Check:

``` bash
aws ec2 describe-vpc-peering-connections \
  --vpc-peering-connection-ids pcx-xxxxxxxx
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-dns.html

------------------------------------------------------------------------

# 29. Cross-Account CLI Peering

Requester account:

``` bash
aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-aaaa1111 \
  --peer-vpc-id vpc-bbbb2222 \
  --peer-owner-id 123456789012 \
  --region ap-south-1
```

For an accepter in another Region:

``` bash
aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-aaaa1111 \
  --peer-vpc-id vpc-bbbb2222 \
  --peer-owner-id 123456789012 \
  --peer-region us-east-1 \
  --region ap-south-1
```

The accepter account must accept the request.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/create-vpc-peering-connection.html

------------------------------------------------------------------------

# 30. CLI Verification

Describe:

``` bash
aws ec2 describe-vpc-peering-connections \
  --vpc-peering-connection-ids pcx-xxxxxxxx
```

Check:

``` text
RequesterVpcInfo
AccepterVpcInfo
Status
PeeringOptions
```

Verify routes:

``` bash
aws ec2 describe-route-tables \
  --route-table-ids rtb-aaaa1111 rtb-bbbb2222
```

Look for:

``` text
Destination: 10.1.0.0/16
Target: pcx-xxxxxxxx
```

and:

``` text
Destination: 10.0.0.0/16
Target: pcx-xxxxxxxx
```

------------------------------------------------------------------------

# 31. CLI Delete Peering

Before deletion, identify the connection:

``` bash
aws ec2 describe-vpc-peering-connections
```

Delete:

``` bash
aws ec2 delete-vpc-peering-connection \
  --vpc-peering-connection-id pcx-xxxxxxxx
```

After deletion, remove obsolete routes if they remain in your
configuration.

------------------------------------------------------------------------

# 32. Terraform Implementation

Terraform's AWS provider provides:

``` hcl
aws_vpc_peering_connection
```

For cross-account or inter-Region acceptance, Terraform also provides:

``` hcl
aws_vpc_peering_connection_accepter
```

Official Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection

Accepter resource:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_accepter

------------------------------------------------------------------------

# 33. Terraform: Same-Account VPC Peering

Assume:

``` text
VPC A = 10.0.0.0/16
VPC B = 10.1.0.0/16
```

``` hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.61"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "a" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-a"
  }
}

resource "aws_vpc" "b" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "vpc-b"
  }
}

resource "aws_vpc_peering_connection" "a_to_b" {
  vpc_id      = aws_vpc.a.id
  peer_vpc_id = aws_vpc.b.id
  auto_accept = true

  tags = {
    Name = "vpc-a-to-vpc-b"
  }
}
```

For same-account, same-Region peering, `auto_accept = true` can
automatically accept the connection.

------------------------------------------------------------------------

# 34. Terraform: Routes Through Peering

Create routes on both sides.

``` hcl
resource "aws_route" "a_to_b" {
  route_table_id            = aws_vpc.a.main_route_table_id
  destination_cidr_block    = aws_vpc.b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id
}

resource "aws_route" "b_to_a" {
  route_table_id            = aws_vpc.b.main_route_table_id
  destination_cidr_block    = aws_vpc.a.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id
}
```

The important principle is:

``` text
VPC A route table
10.1.0.0/16 -> pcx

VPC B route table
10.0.0.0/16 -> pcx
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-routing.html

------------------------------------------------------------------------

# 35. Terraform: DNS Options

Terraform can manage VPC peering options.

Example:

``` hcl
resource "aws_vpc_peering_connection_options" "a_to_b" {
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}
```

This enables DNS resolution support for the peering connection.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-dns.html

Terraform resource:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_options

------------------------------------------------------------------------

# 36. Terraform: Cross-Account Peering

For cross-account architectures, the requester creates the peering
connection.

Requester account:

``` hcl
resource "aws_vpc_peering_connection" "requester" {
  provider = aws.requester

  vpc_id        = aws_vpc.requester.id
  peer_vpc_id   = var.accepter_vpc_id
  peer_owner_id = var.accepter_account_id
  peer_region   = var.accepter_region
  auto_accept   = false

  tags = {
    Name = "cross-account-peering"
  }
}
```

The accepter account can adopt/accept the connection using:

``` hcl
resource "aws_vpc_peering_connection_accepter" "accepter" {
  provider = aws.accepter

  vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
  auto_accept               = true

  tags = {
    Name = "cross-account-peering-accepter"
  }
}
```

Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_accepter

------------------------------------------------------------------------

# 37. Terraform Provider Aliases for Cross-Account Design

A common multi-account structure is:

``` hcl
provider "aws" {
  alias  = "requester"
  region = "ap-south-1"
}

provider "aws" {
  alias  = "accepter"
  region = "ap-south-1"
}
```

Then:

``` hcl
provider = aws.requester
```

or:

``` hcl
provider = aws.accepter
```

This lets Terraform manage resources in the appropriate AWS accounts
when the credentials and IAM configuration permit it.

------------------------------------------------------------------------

# 38. Terraform Workflow

Initialize:

``` bash
terraform init
```

Format:

``` bash
terraform fmt
```

Validate:

``` bash
terraform validate
```

Review:

``` bash
terraform plan
```

Apply:

``` bash
terraform apply
```

View resources:

``` bash
terraform state list
```

Expected:

``` text
aws_vpc.a
aws_vpc.b
aws_vpc_peering_connection.a_to_b
aws_route.a_to_b
aws_route.b_to_a
```

Destroy:

``` bash
terraform destroy
```

------------------------------------------------------------------------

# 39. Important Routing Rule

A peering connection being:

``` text
active
```

does not automatically create routes.

You must configure routes.

Example:

``` text
PCX active
     |
     +---- VPC A route table
     |       10.1.0.0/16 -> PCX
     |
     +---- VPC B route table
             10.0.0.0/16 -> PCX
```

This is one of the most important SAA-C03 troubleshooting points.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-routing.html

------------------------------------------------------------------------

# 40. Common Troubleshooting

## Problem 1: Peering connection cannot be created

Check CIDRs.

They must not overlap.

Example:

``` text
10.0.0.0/16
10.1.0.0/16
```

is valid.

``` text
10.0.0.0/16
10.0.1.0/24
```

is invalid.

------------------------------------------------------------------------

## Problem 2: Peering is active but instances cannot communicate

Check:

``` text
1. Source subnet route table
2. Destination subnet route table
3. Security groups
4. Network ACLs
5. Host firewall
6. Correct destination IP
7. Application listening port
```

The most common issue is a missing route on one side.

------------------------------------------------------------------------

## Problem 3: Route exists in only one VPC

You need return routing.

Example:

``` text
VPC A -> VPC B
```

requires:

``` text
VPC A:
10.1.0.0/16 -> PCX

VPC B:
10.0.0.0/16 -> PCX
```

------------------------------------------------------------------------

## Problem 4: DNS hostname resolves to a public IP

Check the peering DNS settings.

Console:

``` text
VPC
 -> Peering connections
 -> Select PCX
 -> Actions
 -> Edit DNS settings
```

Enable the appropriate requester and accepter DNS resolution options.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-dns.html

------------------------------------------------------------------------

## Problem 5: VPC B cannot use VPC A's NAT Gateway

This is not supported.

VPC peering does not provide edge-to-edge routing through another VPC's:

-   Internet Gateway
-   NAT Gateway
-   VPN
-   Direct Connect
-   Gateway endpoint

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html

------------------------------------------------------------------------

# 41. Important VPC Peering Limitations

  Limitation                                  VPC Peering
  ------------------------------------------- ---------------
  Overlapping CIDRs                           Not allowed
  Transitive routing                          Not supported
  Multiple PCX between same two VPCs          Not allowed
  Use peer VPC as Internet gateway            Not supported
  Use peer VPC NAT for Internet               Not supported
  Use peer VPC VPN for corporate network      Not supported
  Use peer VPC Direct Connect connection      Not supported
  Use peer VPC gateway endpoint               Not supported
  Directly query peer VPC Amazon DNS server   Not supported
  Route tables required                       Yes
  Security controls still apply               Yes

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html

------------------------------------------------------------------------

# 42. VPC Peering and AWS Services

VPC peering provides network connectivity between VPCs.

It does not automatically make every AWS service in one VPC available
through the other VPC.

For example, VPC B cannot automatically use:

``` text
VPC A's NAT Gateway
VPC A's Internet Gateway
VPC A's S3 Gateway Endpoint
```

as transit infrastructure.

This distinction is important in SAA-C03 architecture questions.

------------------------------------------------------------------------

# 43. VPC Peering Pricing

There is no charge simply for creating a VPC peering connection.

Data transfer charges can apply depending on the traffic path, including
traffic crossing Availability Zones or Regions.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html

Always verify current Amazon EC2/VPC pricing for the Region and
architecture before estimating production costs.

------------------------------------------------------------------------

# 44. Inter-Region VPC Peering

Inter-Region peering allows resources in different AWS Regions to
communicate using private IP addresses.

Example:

``` text
ap-south-1                         us-east-1

VPC A                              VPC B
10.0.0.0/16                        10.1.0.0/16
   |                                  |
   |                                  |
   +------- Inter-Region PCX --------+
```

Important SAA-C03 points:

-   No Internet Gateway required for the peering path.
-   No VPN required for the peering path.
-   Traffic uses AWS infrastructure.
-   Inter-Region traffic is encrypted before leaving AWS facilities.
-   CIDRs must not overlap.
-   Routes are still required on both sides.
-   DNS resolution support must be configured if private DNS resolution
    across the peering connection is required.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html

------------------------------------------------------------------------

# 45. VPC Peering vs Transit Gateway Decision

  Architecture                                    Preferred
  ----------------------------------------------- ----------------------
  Two VPCs need direct communication              VPC Peering
  Three VPCs with direct pairwise communication   VPC Peering can work
  Many VPCs with central routing                  Transit Gateway
  Hub-and-spoke architecture                      Transit Gateway
  Need transitive connectivity                    Transit Gateway
  Simple point-to-point connection                VPC Peering
  Need centralized route management               Transit Gateway

For three VPCs:

``` text
VPC A <-> VPC B
VPC A <-> VPC C
```

does not provide:

``` text
VPC B <-> VPC C
```

through VPC A.

You need another peering connection or a different architecture.

------------------------------------------------------------------------

# 46. SAA-C03 Scenario Questions

## Scenario 1

Two VPCs have:

``` text
VPC A = 10.0.0.0/16
VPC B = 10.1.0.0/16
```

They need private communication.

Recommended solution:

**VPC Peering.**

------------------------------------------------------------------------

## Scenario 2

Two VPCs have:

``` text
VPC A = 10.0.0.0/16
VPC B = 10.0.0.0/16
```

Can they be directly peered?

**No. The CIDR blocks overlap.**

------------------------------------------------------------------------

## Scenario 3

VPC A is peered with VPC B. VPC B is peered with VPC C. VPC A needs to
communicate with VPC C through VPC B.

Can VPC B act as the transit router?

**No. VPC peering is not transitive.**

------------------------------------------------------------------------

## Scenario 4

The peering connection is active, but EC2 instances cannot communicate.

What should you check first?

**Route tables on both sides, followed by security groups and network
ACLs.**

------------------------------------------------------------------------

## Scenario 5

A private subnet in VPC B needs to use VPC A's NAT Gateway.

Can VPC peering provide this?

**No. VPC peering does not support edge-to-edge routing through a NAT
Gateway.**

------------------------------------------------------------------------

## Scenario 6

A company has 50 VPCs and wants centralized connectivity with transitive
routing.

Recommended solution:

**AWS Transit Gateway.**

------------------------------------------------------------------------

# 47. Complete Architecture Example

``` text
                         AWS Region
                              |
            +-----------------+-----------------+
            |                                   |
       VPC A                               VPC B
     10.0.0.0/16                         10.1.0.0/16
            |                                   |
     +------+-------+                    +------+-------+
     |              |                    |              |
 Private Subnet A  Public             Private Subnet B Public
     |              |                    |              |
    EC2-A          NAT                  EC2-B          NAT
     |                                   |
     +------------- VPC Peering --------+
                    pcx-xxxx
                       |
              Private IP traffic
```

Required configuration:

``` text
VPC A route:
10.1.0.0/16 -> pcx-xxxx

VPC B route:
10.0.0.0/16 -> pcx-xxxx

Security groups:
Allow required application traffic

NACLs:
Allow required traffic

DNS:
Enable peering DNS options if required
```

------------------------------------------------------------------------

# 48. Professional Implementation Checklist

Before creating VPC peering:

``` text
[ ] Confirm both VPC CIDRs do not overlap
[ ] Identify requester VPC
[ ] Identify accepter VPC
[ ] Determine same-account or cross-account
[ ] Determine same-Region or inter-Region
[ ] Create the peering request
[ ] Accept the request
[ ] Confirm status = active
[ ] Add route to peer CIDR in VPC A
[ ] Add route to peer CIDR in VPC B
[ ] Configure security groups
[ ] Check NACLs
[ ] Check host firewall
[ ] Configure DNS options if required
[ ] Test connectivity
[ ] Verify routes
```

------------------------------------------------------------------------

# 49. Official AWS Documentation by Topic

  -------------------------------------------------------------------------------------------------------------------------------------------------
  Topic                               AWS Documentation
  ----------------------------------- -------------------------------------------------------------------------------------------------------------
  What is VPC Peering?                https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html

  How VPC Peering Works               https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html

  Create VPC Peering                  https://docs.aws.amazon.com/vpc/latest/peering/create-vpc-peering-connection.html

  Route Tables for Peering            https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-routing.html

  Peering DNS Resolution              https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-dns.html

  Common Peering Configurations       https://docs.aws.amazon.com/vpc/latest/peering/peering-configurations.html

  AWS CLI create peering              https://docs.aws.amazon.com/cli/latest/reference/ec2/create-vpc-peering-connection.html

  AWS CLI accept peering              https://docs.aws.amazon.com/cli/latest/reference/ec2/accept-vpc-peering-connection.html

  Route Table Concepts                https://docs.aws.amazon.com/vpc/latest/userguide/RouteTables.html

  Transit Gateway                     https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html

  Terraform VPC Peering               https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection

  Terraform Peering Accepter          https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_accepter

  Terraform Peering Options           https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_options
  -------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 50. Final SAA-C03 Summary

The core VPC Peering model is:

``` text
VPC A
10.0.0.0/16
    |
    | Route:
    | 10.1.0.0/16 -> PCX
    |
    v
VPC Peering Connection
    |
    v
VPC B
10.1.0.0/16
    |
    | Route:
    | 10.0.0.0/16 -> PCX
    |
    v
Private Resources
```

Remember these rules:

``` text
VPC Peering
= VPC-to-VPC private connectivity
= Same Region or Inter-Region
= Same account or cross-account
= Private IPv4/IPv6
= No public Internet path
= Requires routes on both sides
= CIDRs cannot overlap
= Not transitive
= Security groups/NACLs still apply
= Does not provide NAT/IGW/VPN transit
```

For SAA-C03 architecture decisions:

``` text
Direct VPC-to-VPC
        -> VPC Peering

Many VPCs + centralized/transitive routing
        -> Transit Gateway

Private service exposure
        -> AWS PrivateLink

On-premises-to-AWS
        -> Site-to-Site VPN / Direct Connect
```
