# AWS Transit Gateway

## Concepts, Architecture, Management Console, AWS CLI and Terraform

## 1. Overview

AWS Transit Gateway is a network transit hub that connects Amazon VPCs
and on-premises networks. It provides a centralized Layer 3 routing
point for traffic between attached networks.

Instead of creating many individual VPC peering connections, multiple
VPCs can attach to one Transit Gateway.

``` text
                  AWS Transit Gateway
                         |
        +----------------+----------------+
        |                |                |
      VPC A            VPC B            VPC C
   10.0.0.0/16      10.1.0.0/16      10.2.0.0/16
        |                |                |
       EC2              EC2              EC2
```

AWS describes Transit Gateway as a regional virtual router. Routing
operates at Layer 3 using destination IP addresses and Transit Gateway
route tables. citeturn0search0

Official AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html

------------------------------------------------------------------------

# 2. Why Transit Gateway Is Used

VPC peering is point-to-point.

For example, with four VPCs, direct full-mesh peering requires:

``` text
VPC A <-> VPC B
VPC A <-> VPC C
VPC A <-> VPC D
VPC B <-> VPC C
VPC B <-> VPC D
VPC C <-> VPC D
```

Transit Gateway changes the design:

``` text
                 Transit Gateway
              /       |       |       \
            VPC A    VPC B    VPC C    VPC D
```

This gives a centralized routing architecture.

Transit Gateway can also connect:

-   VPCs
-   Site-to-Site VPN connections
-   Direct Connect gateways
-   Transit Gateway peering attachments
-   Connect attachments
-   Client VPN attachments
-   Other supported attachment types

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html

------------------------------------------------------------------------

# 3. Transit Gateway Core Concepts

  -----------------------------------------------------------------------
  Concept                             Description
  ----------------------------------- -----------------------------------
  Transit Gateway                     Regional network transit hub

  Attachment                          Connection between Transit Gateway
                                      and a network/resource

  VPC Attachment                      Connects a VPC to Transit Gateway

  Transit Gateway Route Table         Determines next hop between
                                      attachments

  Association                         Associates an attachment with one
                                      Transit Gateway route table

  Propagation                         Installs routes learned from an
                                      attachment into one or more TGW
                                      route tables

  Static Route                        Manually configured route in a TGW
                                      route table

  Blackhole Route                     Route that intentionally drops
                                      matching traffic

  Appliance Mode                      Keeps a flow on the same
                                      Availability Zone when routing
                                      through a stateful appliance

  Transit Gateway Peering             Connects two Transit Gateways

  AWS RAM                             Allows sharing a Transit Gateway
                                      across AWS accounts
  -----------------------------------------------------------------------

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-transit-gateways.html

------------------------------------------------------------------------

# 4. Transit Gateway Architecture

A basic architecture:

``` text
                           AWS Region
                                |
                    +-----------+-----------+
                    |   Transit Gateway    |
                    |      tgw-xxxx        |
                    +-----------+-----------+
                                |
             +------------------+------------------+
             |                  |                  |
             v                  v                  v
         VPC A              VPC B              VPC C
      10.0.0.0/16        10.1.0.0/16        10.2.0.0/16
             |                  |                  |
          EC2-A              EC2-B              EC2-C
```

The VPCs are attached to the Transit Gateway.

The Transit Gateway route table determines where packets are sent.

The VPC route tables must also contain routes that send appropriate
traffic to the Transit Gateway.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/how-transit-gateways-work.html

------------------------------------------------------------------------

# 5. How Transit Gateway Routing Works

Assume:

``` text
VPC A = 10.0.0.0/16
VPC B = 10.1.0.0/16
VPC C = 10.2.0.0/16
```

Traffic from VPC A to VPC B:

``` text
EC2-A
  |
  v
VPC A Route Table
10.1.0.0/16 -> Transit Gateway
  |
  v
Transit Gateway
  |
  v
TGW Route Table
10.1.0.0/16 -> VPC B Attachment
  |
  v
VPC B
  |
  v
EC2-B
```

The return traffic requires an appropriate route back through the
Transit Gateway.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/how-transit-gateways-work.html

------------------------------------------------------------------------

# 6. Transit Gateway Route Tables

A Transit Gateway can have one or more route tables.

Each attachment is associated with exactly one Transit Gateway route
table.

An attachment can propagate routes to one or more Transit Gateway route
tables.

``` text
                 Transit Gateway
                        |
          +-------------+-------------+
          |                           |
   TGW Route Table A           TGW Route Table B
          |                           |
      Production                  Shared Services
```

This allows network segmentation.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-route-tables.html

------------------------------------------------------------------------

# 7. Association vs Propagation

This is one of the most important Transit Gateway concepts.

## Association

Association answers:

> Which Transit Gateway route table should this attachment use for
> routing?

Each attachment is associated with one TGW route table.

``` text
VPC A Attachment
       |
       | association
       v
TGW Route Table A
```

## Propagation

Propagation answers:

> Which TGW route tables should receive routes from this attachment?

An attachment can propagate routes into one or more TGW route tables.

``` text
VPC A Attachment
       |
       +------ propagation ------> TGW Route Table A
       |
       +------ propagation ------> TGW Route Table B
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-route-tables.html

------------------------------------------------------------------------

# 8. Static vs Propagated Routes

  -------------------------------------------------------------------------------
  Feature                 Static Route                    Propagated Route
  ----------------------- ------------------------------- -----------------------
  Created manually        Yes                             No, learned from
                                                          attachment

  Common use              Custom routing                  VPC/VPN/DX learned
                                                          routes

  Can be blackhole        Yes                             No

  Peering attachment      Static routes required          Not supported for
                                                          peering

  Route management        Explicit                        Dynamic based on
                                                          attachment

  Example                 `0.0.0.0/0 -> VPN attachment`   VPC CIDR propagated
                                                          from VPC attachment
  -------------------------------------------------------------------------------

AWS states that Transit Gateway supports static and propagated routes.
For Transit Gateway peering attachments, only static routes are
supported. citeturn0search0

------------------------------------------------------------------------

# 9. Default Transit Gateway Route Table

When a Transit Gateway is created, AWS normally creates a default
Transit Gateway route table and uses it as the default association and
propagation route table.

This behavior can be disabled during creation.

The default model is convenient for a simple architecture:

``` text
VPC A Attachment
       |
       v
Default TGW Route Table
       ^
       |
VPC B Attachment
```

Routes from attached VPCs can propagate into the default route table.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/create-tgw.html

------------------------------------------------------------------------

# 10. VPC Route Table vs Transit Gateway Route Table

There are two different routing layers.

  -----------------------------------------------------------------------
  Layer                   Route table             Purpose
  ----------------------- ----------------------- -----------------------
  VPC                     VPC route table         Sends traffic from a
                                                  subnet toward the
                                                  Transit Gateway

  Transit Gateway         TGW route table         Determines which
                                                  attachment receives the
                                                  traffic
  -----------------------------------------------------------------------

Example:

``` text
EC2
 |
 v
VPC Route Table
10.1.0.0/16 -> tgw-xxxx
 |
 v
Transit Gateway
 |
 v
TGW Route Table
10.1.0.0/16 -> VPC-B Attachment
 |
 v
VPC B
```

A common configuration error is configuring only one of these routing
layers.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/how-transit-gateways-work.html

------------------------------------------------------------------------

# 11. Transit Gateway Attachments

Transit Gateway supports multiple attachment types.

  Attachment                    Purpose
  ----------------------------- ---------------------------------------
  VPC                           Connect VPC
  VPN                           Connect Site-to-Site VPN
  Direct Connect Gateway        Connect Direct Connect infrastructure
  Transit Gateway Peering       Connect another Transit Gateway
  Connect                       SD-WAN/third-party appliances
  Client VPN                    Connect Client VPN
  Multicast-related resources   Multicast architectures

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-transit-gateways.html

For SAA-C03, concentrate primarily on:

``` text
VPC
VPN
Direct Connect
Transit Gateway Peering
```

------------------------------------------------------------------------

# 12. VPC Attachment

When you create a VPC attachment, you select subnets in the VPC.

AWS creates Transit Gateway network interfaces in those subnets.

Important requirements:

-   At least one subnet must be selected.
-   Only one subnet can be selected per Availability Zone.
-   AWS recommends using subnets in multiple Availability Zones for
    availability.
-   Resources in an Availability Zone can reach the Transit Gateway
    through the attachment only when that AZ has an attachment subnet.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/create-vpc-attachment.html

------------------------------------------------------------------------

# 13. Transit Gateway and High Availability

Recommended architecture:

``` text
VPC
|
+-- AZ-a
|    |
|    +-- TGW attachment subnet
|
+-- AZ-b
     |
     +-- TGW attachment subnet
```

For a multi-AZ workload:

``` text
             Transit Gateway
              /           \
             /             \
          AZ-a             AZ-b
           |                 |
      Attachment A      Attachment B
           |                 |
        EC2-A             EC2-B
```

AWS documentation recommends selecting a subnet for each Availability
Zone used by the Transit Gateway.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/create-vpc-attachment.html

------------------------------------------------------------------------

# 14. Transit Gateway vs VPC Peering

  -----------------------------------------------------------------------
  Feature                 Transit Gateway         VPC Peering
  ----------------------- ----------------------- -----------------------
  Architecture            Hub                     Point-to-point

  Transitive routing      Yes                     No

  Large number of VPCs    Excellent               Complex

  Centralized routing     Yes                     No

  Route tables            TGW route tables + VPC  VPC route tables
                          route tables            

  VPC attachment          Yes                     Peering connection

  VPN integration         Yes                     No

  Direct Connect          Yes                     No
  integration                                     

  Inter-Region            TGW peering             VPC peering
  connectivity                                    

  Network segmentation    Strong                  Limited

  Best for                Large network           Simple direct VPC
                                                  connection
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 15. Transit Gateway vs NAT Gateway

  Feature                        Transit Gateway                   NAT Gateway
  ------------------------------ --------------------------------- --------------------------------
  Primary purpose                Network transit                   Outbound Internet access
  Connect VPCs                   Yes                               No
  Connect on-premises            Yes, through VPN/DX attachments   No
  Internet access                Not by itself                     Yes
  Routing hub                    Yes                               No
  Private network connectivity   Yes                               Provides outbound translation
  Typical use                    Multi-VPC network                 Private subnet Internet access

A Transit Gateway does not automatically provide Internet access.

------------------------------------------------------------------------

# 16. Transit Gateway vs Internet Gateway

  Feature                 Transit Gateway                     Internet Gateway
  ----------------------- ----------------------------------- ----------------------------------
  VPC-to-VPC routing      Yes                                 No
  VPC-to-on-premises      Yes through supported attachments   No
  Internet connectivity   Not by itself                       Yes
  Central routing         Yes                                 No
  Public IP translation   No                                  Supports public Internet routing
  Main role               Network transit                     Internet gateway

------------------------------------------------------------------------

# 17. Transit Gateway vs AWS PrivateLink

  -----------------------------------------------------------------------
  Feature                 Transit Gateway         PrivateLink
  ----------------------- ----------------------- -----------------------
  Main purpose            Network connectivity    Private service
                                                  connectivity

  Connectivity model      Network-to-network      Consumer-to-service

  Access entire routed    Yes, subject to routes  No
  network                                         

  Endpoint ENI            VPC attachment ENIs     Interface endpoint ENIs

  Transitive routing      Yes through TGW routing Not a general routing
                                                  mechanism

  Common use              Multi-VPC network       Private service
                                                  exposure

  Service provider model  No                      Yes
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 18. Transit Gateway vs Site-to-Site VPN

  Feature                Transit Gateway              Site-to-Site VPN
  ---------------------- ---------------------------- -----------------------------------------------
  Network hub            Yes                          No
  Encrypts VPN traffic   Through VPN attachment       Yes
  Connects VPCs          Yes                          Only when routed through TGW/VGW architecture
  Connects on-premises   Yes through VPN attachment   Yes
  BGP support            Through VPN/DX attachments   Yes
  Main role              Central transit              Encrypted network tunnel

------------------------------------------------------------------------

# 19. Management Console Implementation

The following lab creates:

``` text
VPC A: 10.0.0.0/16
VPC B: 10.1.0.0/16

             Transit Gateway
                /       \
             VPC A      VPC B
```

Assume each VPC already contains:

-   A subnet
-   A route table
-   An EC2 instance
-   Appropriate security groups

The VPC CIDRs must not overlap.

AWS's official tutorial uses two VPCs and walks through Transit Gateway
creation, VPC attachments, route configuration, testing, and deletion.
citeturn1search3

------------------------------------------------------------------------

# 20. Step 1: Open the VPC Console

Open:

https://console.aws.amazon.com/vpc/

Select the Region containing the VPCs.

Navigate to:

``` text
VPC
 -> Transit Gateways
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/create-tgw.html

------------------------------------------------------------------------

# 21. Step 2: Create the Transit Gateway

Choose:

``` text
Create transit gateway
```

Configure:

``` text
Name tag:
central-transit-gateway

Description:
Central network transit hub
```

For ASN, use the default unless your architecture requires a specific
value.

Example:

``` text
Amazon side ASN:
64512
```

For a simple lab, keep the default route-table behavior enabled.

Create the Transit Gateway.

The initial state will be similar to:

``` text
pending
```

Wait until:

``` text
available
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/create-tgw.html

------------------------------------------------------------------------

# 22. Step 3: Create VPC Attachment for VPC A

Navigate to:

``` text
VPC
 -> Transit Gateway Attachments
 -> Create transit gateway attachment
```

Configure:

``` text
Name:
tgw-attachment-vpc-a

Transit Gateway:
tgw-xxxxxxxx

Attachment type:
VPC

VPC:
VPC-A
```

Select one subnet in each Availability Zone that should provide Transit
Gateway connectivity.

Example:

``` text
AZ-a:
subnet-tgw-a

AZ-b:
subnet-tgw-b
```

Enable as appropriate:

``` text
DNS support
```

For a basic IPv4 lab, IPv6 can remain disabled.

Choose:

``` text
Create transit gateway attachment
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/create-vpc-attachment.html

------------------------------------------------------------------------

# 23. Step 4: Create VPC Attachment for VPC B

Repeat:

``` text
VPC
 -> Transit Gateway Attachments
 -> Create transit gateway attachment
```

Configure:

``` text
Name:
tgw-attachment-vpc-b

Transit Gateway:
tgw-xxxxxxxx

Attachment type:
VPC

VPC:
VPC-B
```

Select one subnet per required Availability Zone.

Create the attachment.

Wait until both attachments are:

``` text
available
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/create-vpc-attachment.html

------------------------------------------------------------------------

# 24. Step 5: Verify TGW Route Table

Navigate to:

``` text
VPC
 -> Transit Gateway Route Tables
```

Open the route table associated with the attachments.

If default propagation is enabled, you should see propagated routes
similar to:

``` text
Destination       Target                  Type
10.0.0.0/16       VPC-A attachment        propagated
10.1.0.0/16       VPC-B attachment        propagated
```

AWS documents that VPC CIDRs can propagate into Transit Gateway route
tables. citeturn0search0

------------------------------------------------------------------------

# 25. Step 6: Configure VPC A Route Table

Open:

``` text
VPC
 -> Route Tables
```

Select the route table used by the source subnet in VPC A.

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
Transit Gateway
tgw-xxxxxxxx
```

Save.

------------------------------------------------------------------------

# 26. Step 7: Configure VPC B Route Table

Select the route table used by the destination subnet in VPC B.

Add:

``` text
Destination:
10.0.0.0/16

Target:
Transit Gateway
tgw-xxxxxxxx
```

Save.

The final design is:

``` text
VPC A Route Table
10.1.0.0/16 -> tgw-xxxx


Transit Gateway Route Table
10.0.0.0/16 -> VPC-A attachment
10.1.0.0/16 -> VPC-B attachment


VPC B Route Table
10.0.0.0/16 -> tgw-xxxx
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/how-transit-gateways-work.html

------------------------------------------------------------------------

# 27. Step 8: Configure Security Groups

For testing with ICMP, allow ICMP in the destination security group.

For an application, allow only the required port.

Example:

``` text
Protocol:
TCP

Port:
8080

Source:
10.0.0.0/16
```

Do not automatically allow:

``` text
0.0.0.0/0
```

Security groups remain part of the traffic path.

------------------------------------------------------------------------

# 28. Step 9: Test Connectivity

From an EC2 instance in VPC A:

``` bash
ping 10.1.1.10
```

if ICMP is allowed.

For an application:

``` bash
curl http://10.1.1.10:8080
```

Or:

``` bash
nc -vz 10.1.1.10 8080
```

If communication fails, check:

``` text
VPC A route table
VPC B route table
TGW route table
TGW attachment state
Security groups
Network ACLs
Host firewall
Application port
```

------------------------------------------------------------------------

# 29. Step 10: Delete the Lab

The dependency order is:

``` text
VPC Routes
     |
     v
VPC Attachments
     |
     v
Transit Gateway
```

You cannot delete a Transit Gateway while resource attachments remain.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-getting-started-console.html

------------------------------------------------------------------------

# 30. AWS CLI Implementation

## Step 1: Create Transit Gateway

``` bash
aws ec2 create-transit-gateway \
  --description "Central Transit Gateway"
```

The response contains:

``` text
TransitGatewayId
```

Example:

``` text
tgw-xxxxxxxx
```

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/ec2/create-transit-gateway.html

------------------------------------------------------------------------

# 31. Step 2: Check Transit Gateway State

``` bash
aws ec2 describe-transit-gateways \
  --transit-gateway-ids tgw-xxxxxxxx
```

Wait until:

``` text
State: available
```

------------------------------------------------------------------------

# 32. Step 3: Create VPC Attachment

For VPC A:

``` bash
aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id tgw-xxxxxxxx \
  --vpc-id vpc-aaaaaaaa \
  --subnet-ids subnet-aaaaaaaa subnet-bbbbbbbb
```

The attachment starts in:

``` text
pending
```

and should transition to:

``` text
available
```

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/ec2/create-transit-gateway-vpc-attachment.html

------------------------------------------------------------------------

# 33. Step 4: Create VPC B Attachment

``` bash
aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id tgw-xxxxxxxx \
  --vpc-id vpc-bbbbbbbb \
  --subnet-ids subnet-cccccccc subnet-dddddddd
```

AWS recommends multiple Availability Zone subnets for better
availability.

------------------------------------------------------------------------

# 34. Step 5: Verify Attachments

``` bash
aws ec2 describe-transit-gateway-vpc-attachments \
  --transit-gateway-ids tgw-xxxxxxxx
```

Check:

``` text
TransitGatewayAttachmentId
TransitGatewayId
VpcId
SubnetIds
State
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/view-vpc-attachment.html

------------------------------------------------------------------------

# 35. Step 6: Inspect Transit Gateway Route Tables

List:

``` bash
aws ec2 describe-transit-gateway-route-tables \
  --transit-gateway-id tgw-xxxxxxxx
```

Then:

``` bash
aws ec2 search-transit-gateway-routes \
  --transit-gateway-route-table-id tgw-rtb-xxxxxxxx \
  --filters Name=state,Values=active
```

You should find routes similar to:

``` text
10.0.0.0/16 -> VPC A attachment
10.1.0.0/16 -> VPC B attachment
```

------------------------------------------------------------------------

# 36. Step 7: Add VPC Route

VPC A:

``` bash
aws ec2 create-route \
  --route-table-id rtb-aaaaaaaa \
  --destination-cidr-block 10.1.0.0/16 \
  --transit-gateway-id tgw-xxxxxxxx
```

VPC B:

``` bash
aws ec2 create-route \
  --route-table-id rtb-bbbbbbbb \
  --destination-cidr-block 10.0.0.0/16 \
  --transit-gateway-id tgw-xxxxxxxx
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-getting-started-cli.html

------------------------------------------------------------------------

# 37. Step 8: Verify VPC Routes

``` bash
aws ec2 describe-route-tables \
  --route-table-ids rtb-aaaaaaaa rtb-bbbbbbbb
```

Expected:

``` text
VPC A:
10.1.0.0/16 -> tgw-xxxxxxxx

VPC B:
10.0.0.0/16 -> tgw-xxxxxxxx
```

------------------------------------------------------------------------

# 38. CLI: Create a Dedicated TGW Route Table

For more controlled architectures:

``` bash
aws ec2 create-transit-gateway-route-table \
  --transit-gateway-id tgw-xxxxxxxx
```

AWS CLI reference:
https://docs.aws.amazon.com/cli/latest/reference/ec2/create-transit-gateway-route-table.html

Then associate an attachment:

``` bash
aws ec2 associate-transit-gateway-route-table \
  --transit-gateway-route-table-id tgw-rtb-xxxxxxxx \
  --transit-gateway-attachment-id tgw-attach-xxxxxxxx
```

AWS CLI:
https://docs.aws.amazon.com/cli/latest/reference/ec2/associate-transit-gateway-route-table.html

------------------------------------------------------------------------

# 39. CLI: Enable Route Propagation

``` bash
aws ec2 enable-transit-gateway-route-table-propagation \
  --transit-gateway-route-table-id tgw-rtb-xxxxxxxx \
  --transit-gateway-attachment-id tgw-attach-xxxxxxxx
```

This causes routes from the attachment to be propagated into the
specified TGW route table.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-route-tables.html

------------------------------------------------------------------------

# 40. CLI: Create Static TGW Route

``` bash
aws ec2 create-transit-gateway-route \
  --transit-gateway-route-table-id tgw-rtb-xxxxxxxx \
  --destination-cidr-block 10.2.0.0/16 \
  --transit-gateway-attachment-id tgw-attach-xxxxxxxx
```

For a blackhole route:

``` bash
aws ec2 create-transit-gateway-route \
  --transit-gateway-route-table-id tgw-rtb-xxxxxxxx \
  --destination-cidr-block 10.3.0.0/16 \
  --blackhole
```

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-route-tables.html

------------------------------------------------------------------------

# 41. Terraform Implementation

Terraform provides AWS resources for:

``` text
aws_ec2_transit_gateway
aws_ec2_transit_gateway_vpc_attachment
aws_ec2_transit_gateway_route_table
aws_ec2_transit_gateway_route_table_association
aws_ec2_transit_gateway_route_table_propagation
aws_ec2_transit_gateway_route
```

Official Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway

------------------------------------------------------------------------

# 42. Terraform: Create Transit Gateway

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

resource "aws_ec2_transit_gateway" "main" {
  description = "Central Transit Gateway"

  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  dns_support = "enable"

  tags = {
    Name = "central-transit-gateway"
  }
}
```

AWS provider documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway

------------------------------------------------------------------------

# 43. Terraform: VPC Attachment

``` hcl
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_a" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.a.id

  subnet_ids = [
    aws_subnet.tgw_a.id,
    aws_subnet.tgw_b.id
  ]

  dns_support = "enable"

  tags = {
    Name = "tgw-vpc-a"
  }
}
```

The attachment uses one subnet per Availability Zone.

Terraform resource:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment

------------------------------------------------------------------------

# 44. Terraform: VPC B Attachment

``` hcl
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_b" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.b.id

  subnet_ids = [
    aws_subnet.tgw_c.id,
    aws_subnet.tgw_d.id
  ]

  dns_support = "enable"

  tags = {
    Name = "tgw-vpc-b"
  }
}
```

------------------------------------------------------------------------

# 45. Terraform: VPC Route Tables

Traffic from VPC A to VPC B:

``` hcl
resource "aws_route" "vpc_a_to_vpc_b" {
  route_table_id         = aws_route_table.vpc_a.id
  destination_cidr_block = aws_vpc.b.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}
```

Traffic from VPC B to VPC A:

``` hcl
resource "aws_route" "vpc_b_to_vpc_a" {
  route_table_id         = aws_route_table.vpc_b.id
  destination_cidr_block = aws_vpc.a.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}
```

------------------------------------------------------------------------

# 46. Terraform: Dedicated TGW Route Table

``` hcl
resource "aws_ec2_transit_gateway_route_table" "main" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "central-tgw-route-table"
  }
}
```

Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table

------------------------------------------------------------------------

# 47. Terraform: Route Table Association

``` hcl
resource "aws_ec2_transit_gateway_route_table_association" "vpc_a" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_a.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_association" "vpc_b" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_b.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}
```

Remember:

``` text
One attachment
      |
      v
One TGW route table association
```

------------------------------------------------------------------------

# 48. Terraform: Route Propagation

``` hcl
resource "aws_ec2_transit_gateway_route_table_propagation" "vpc_a" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_a.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpc_b" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_b.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}
```

Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation

------------------------------------------------------------------------

# 49. Terraform: Static Route

``` hcl
resource "aws_ec2_transit_gateway_route" "to_vpc_b" {
  destination_cidr_block         = aws_vpc.b.cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc_b.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}
```

Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route

------------------------------------------------------------------------

# 50. Terraform Workflow

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

Plan:

``` bash
terraform plan
```

Apply:

``` bash
terraform apply
```

Inspect state:

``` bash
terraform state list
```

Expected resources:

``` text
aws_ec2_transit_gateway.main
aws_ec2_transit_gateway_vpc_attachment.vpc_a
aws_ec2_transit_gateway_vpc_attachment.vpc_b
aws_ec2_transit_gateway_route_table.main
aws_ec2_transit_gateway_route_table_association.vpc_a
aws_ec2_transit_gateway_route_table_association.vpc_b
aws_ec2_transit_gateway_route_table_propagation.vpc_a
aws_ec2_transit_gateway_route_table_propagation.vpc_b
aws_route.vpc_a_to_vpc_b
aws_route.vpc_b_to_vpc_a
```

Destroy:

``` bash
terraform destroy
```

------------------------------------------------------------------------

# 51. Network Segmentation with Multiple TGW Route Tables

Transit Gateway can be used to isolate networks.

Example:

``` text
                    Transit Gateway
                           |
             +-------------+-------------+
             |                           |
       Production RT              Development RT
             |                           |
        Prod VPCs                    Dev VPCs
```

Production attachments can be associated with the production route
table.

Development attachments can be associated with the development route
table.

Only the routes that are propagated or statically configured into a
route table are reachable through that route table.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-route-tables.html

------------------------------------------------------------------------

# 52. Shared Services Architecture

A common enterprise architecture is:

``` text
                    Transit Gateway
             __________|____________
            |          |            |
            v          v            v
          VPC A      VPC B       Shared Services
          Prod       Dev         VPC
                                  |
                                  +-- DNS
                                  +-- Monitoring
                                  +-- Security
                                  +-- Directory
```

Separate TGW route tables can control which environments can access
shared services.

AWS documents isolated-router and shared-services patterns for Transit
Gateway. citeturn0search0

------------------------------------------------------------------------

# 53. Centralized Inspection

Transit Gateway can route traffic through a security appliance in a
dedicated inspection VPC.

Example:

``` text
VPC A
  |
  v
Transit Gateway
  |
  v
Inspection VPC
  |
  v
Firewall / Appliance
  |
  v
Transit Gateway
  |
  v
VPC B
```

For stateful appliances, Transit Gateway supports appliance mode on the
relevant VPC attachment. This helps keep the same Availability Zone for
the lifetime of a flow.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/how-transit-gateways-work.html

------------------------------------------------------------------------

# 54. Transit Gateway and VPN

Transit Gateway can act as a central hub for multiple VPN connections.

``` text
On-Premises A
      |
     VPN
      |
      v
Transit Gateway
   /       \
 VPC A    VPC B

On-Premises B
      |
     VPN
      |
      +----> Transit Gateway
```

VPN routes can be dynamically propagated using BGP.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/create-vpn-attachment.html

------------------------------------------------------------------------

# 55. Transit Gateway and Direct Connect

A Direct Connect gateway can attach to Transit Gateway.

Architecture:

``` text
Corporate Network
       |
       |
Direct Connect
       |
       v
Direct Connect Gateway
       |
       v
Transit Gateway
     /    \
   VPC A  VPC B
```

This provides a scalable architecture for connecting on-premises
networks to multiple VPCs.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-dcg-attachments.html

------------------------------------------------------------------------

# 56. Transit Gateway Peering

Two Transit Gateways can be connected using a Transit Gateway peering
attachment.

``` text
Region A                         Region B

Transit Gateway A <----------> Transit Gateway B
       |                              |
     VPCs                           VPCs
```

Transit Gateway peering supports both intra-Region and inter-Region
peering.

Important:

**Transit Gateway peering uses static routes.**

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-peering.html

------------------------------------------------------------------------

# 57. AWS RAM and Transit Gateway Sharing

A Transit Gateway can be shared with other AWS accounts using AWS
Resource Access Manager (AWS RAM).

Example:

``` text
AWS Account A
     |
 Transit Gateway
     |
     +------------------+
     |                  |
 Account B           Account C
 VPC attachment      VPC attachment
```

This is useful in AWS Organizations and multi-account architectures.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/tgw-transit-gateways.html

------------------------------------------------------------------------

# 58. Important Limitations and Design Considerations

  -----------------------------------------------------------------------
  Consideration                       Transit Gateway
  ----------------------------------- -----------------------------------
  CIDR overlap                        Overlapping VPC CIDRs create
                                      routing limitations and propagation
                                      conflicts

  Transitive routing                  Supported through TGW route tables

  Route tables                        One or more

  Attachment association              Exactly one TGW route table per
                                      attachment

  Propagation                         One attachment can propagate to
                                      multiple route tables

  Peering route type                  Static

  Internet access                     Not automatic

  NAT                                 Not provided automatically

  Security groups                     Still apply

  NACLs                               Still apply

  VPC route configuration             Required

  Multi-AZ attachment                 Recommended

  Cross-account                       Supported

  Cross-Region                        Supported through TGW peering
  -----------------------------------------------------------------------

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/how-transit-gateways-work.html

------------------------------------------------------------------------

# 59. Common Troubleshooting

## Problem 1: Attachment is not available

Check:

``` text
VPC
Subnets
Transit Gateway state
Account permissions
Cross-account acceptance
CIDR conflicts
```

------------------------------------------------------------------------

## Problem 2: TGW attachment is available but traffic fails

Check both routing layers:

``` text
VPC route table
        +
TGW route table
```

Then check:

``` text
Security groups
NACLs
Host firewall
Application port
```

------------------------------------------------------------------------

## Problem 3: VPC CIDR does not appear in TGW route table

Check:

``` text
Route table association
Route propagation
Existing overlapping route
Attachment state
```

AWS notes that a newly attached VPC with an overlapping CIDR may not
have its CIDR propagated to the default propagation route table.
citeturn1search4

------------------------------------------------------------------------

## Problem 4: One AZ works but another does not

Check whether the Transit Gateway attachment includes a subnet in the
Availability Zone containing the resource.

AWS requires at least one attachment subnet and permits only one
selected subnet per Availability Zone.

AWS documentation:
https://docs.aws.amazon.com/vpc/latest/tgw/create-vpc-attachment.html

------------------------------------------------------------------------

## Problem 5: Internet access through Transit Gateway does not work

Transit Gateway is a transit router, not an Internet Gateway.

If centralized Internet egress is required, the architecture needs an
appropriate egress VPC containing the required Internet Gateway/NAT
Gateway and corresponding TGW/VPC routes.

------------------------------------------------------------------------

# 60. SAA-C03 Exam Points

Memorize these concepts:

1.  **Transit Gateway is a regional network transit hub.**
2.  **It connects multiple VPCs and on-premises networks.**
3.  **It provides transitive routing.**
4.  **VPC peering does not provide transitive routing.**
5.  **Each VPC attachment is associated with exactly one TGW route
    table.**
6.  **An attachment can propagate routes to multiple TGW route tables.**
7.  **TGW route tables support static and propagated routes.**
8.  **Transit Gateway peering uses static routes.**
9.  **VPC route tables still need routes pointing to the Transit
    Gateway.**
10. **A Transit Gateway does not automatically provide Internet
    access.**
11. **VPN and Direct Connect can integrate with Transit Gateway.**
12. **Transit Gateway can be shared across AWS accounts using AWS RAM.**
13. **Transit Gateway can connect across Regions through Transit Gateway
    peering.**
14. **Use multiple AZ subnets for VPC attachments for availability.**
15. **Route-table segmentation can isolate groups of VPCs.**
16. **Blackhole routes can intentionally drop traffic.**
17. **Appliance mode supports stateful network appliance designs.**

------------------------------------------------------------------------

# 61. SAA-C03 Scenario Questions

## Scenario 1

A company has 30 VPCs and needs centralized connectivity.

**Answer: AWS Transit Gateway.**

------------------------------------------------------------------------

## Scenario 2

A company has:

``` text
VPC A <-> VPC B
```

Only two VPCs need connectivity.

**Answer: VPC Peering can be simpler.**

------------------------------------------------------------------------

## Scenario 3

A company wants:

``` text
VPC A -> VPC B -> VPC C
```

with transitive routing.

**Answer: Transit Gateway.**

------------------------------------------------------------------------

## Scenario 4

Private EC2 instances in several VPCs need centralized Internet egress.

**Answer:** Transit Gateway can route traffic to a centralized egress
VPC, where NAT Gateway/Internet Gateway provide Internet access.

------------------------------------------------------------------------

## Scenario 5

Several VPCs need access to a centralized inspection firewall.

**Answer:** Use Transit Gateway with an inspection/shared-services VPC
and appropriate TGW route tables. Appliance mode may be required for
stateful inspection.

------------------------------------------------------------------------

## Scenario 6

A company needs to connect many on-premises networks and VPCs.

**Answer:** Transit Gateway with VPN and/or Direct Connect attachments.

------------------------------------------------------------------------

## Scenario 7

Two Transit Gateways in different Regions need connectivity.

**Answer:** Transit Gateway peering with static routes.

------------------------------------------------------------------------

## Scenario 8

A VPC attachment is available, but no route to another VPC exists in the
TGW route table.

**Answer:** Configure propagation or a static TGW route as appropriate.

------------------------------------------------------------------------

# 62. Architecture Decision Table

  Requirement                              Recommended Architecture
  ---------------------------------------- ----------------------------------
  Two VPCs direct communication            VPC Peering
  Many VPCs                                Transit Gateway
  Transitive VPC connectivity              Transit Gateway
  Centralized network routing              Transit Gateway
  VPC + VPN hub                            Transit Gateway
  VPC + Direct Connect hub                 Transit Gateway
  Cross-Region TGW connectivity            Transit Gateway Peering
  Private service access                   PrivateLink
  S3/DynamoDB private access               VPC Gateway Endpoint
  General private subnet Internet access   NAT Gateway
  Centralized firewall inspection          Transit Gateway + Inspection VPC

------------------------------------------------------------------------

# 63. Complete Lab Architecture

``` text
                         AWS Region
                              |
                    +---------+---------+
                    |   Transit Gateway |
                    |     tgw-xxxx      |
                    +----+--------+-----+
                         |        |
                         |        |
                VPC A    |        |    VPC B
             10.0.0.0/16 |        | 10.1.0.0/16
                         |        |
                    +----+--+  +--+----+
                    | EC2-A |  | EC2-B |
                    +-------+  +-------+

VPC A Route Table:
10.1.0.0/16 -> TGW

VPC B Route Table:
10.0.0.0/16 -> TGW

TGW Route Table:
10.0.0.0/16 -> VPC A attachment
10.1.0.0/16 -> VPC B attachment
```

------------------------------------------------------------------------

# 64. Professional Implementation Checklist

Before deployment:

``` text
[ ] Plan non-overlapping VPC CIDRs
[ ] Determine required VPCs
[ ] Determine required on-premises networks
[ ] Create Transit Gateway
[ ] Wait for TGW = available
[ ] Create VPC attachments
[ ] Select attachment subnet in each required AZ
[ ] Confirm attachment = available
[ ] Confirm TGW route table
[ ] Configure attachment association
[ ] Configure route propagation or static routes
[ ] Add VPC routes pointing to TGW
[ ] Configure security groups
[ ] Configure NACLs
[ ] Test connectivity
[ ] Review TGW route tables
[ ] Review logs/monitoring where required
[ ] Remove lab resources after testing
```

------------------------------------------------------------------------

# 65. Official AWS Documentation by Topic

  -------------------------------------------------------------------------------------------------------------------------------------------------------------
  Topic                               AWS Documentation
  ----------------------------------- -------------------------------------------------------------------------------------------------------------------------
  What is Transit Gateway?            https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html

  How Transit Gateway Works           https://docs.aws.amazon.com/vpc/latest/tgw/how-transit-gateways-work.html

  Transit Gateway Concepts            https://docs.aws.amazon.com/vpc/latest/tgw/tgw-transit-gateways.html

  Create Transit Gateway              https://docs.aws.amazon.com/vpc/latest/tgw/create-tgw.html

  Console Tutorial                    https://docs.aws.amazon.com/vpc/latest/tgw/tgw-getting-started-console.html

  Create VPC Attachment               https://docs.aws.amazon.com/vpc/latest/tgw/create-vpc-attachment.html

  TGW Route Tables                    https://docs.aws.amazon.com/vpc/latest/tgw/tgw-route-tables.html

  CLI Tutorial                        https://docs.aws.amazon.com/vpc/latest/tgw/tgw-getting-started-cli.html

  CLI create Transit Gateway          https://docs.aws.amazon.com/cli/latest/reference/ec2/create-transit-gateway.html

  CLI VPC Attachment                  https://docs.aws.amazon.com/cli/latest/reference/ec2/create-transit-gateway-vpc-attachment.html

  Transit Gateway Peering             https://docs.aws.amazon.com/vpc/latest/tgw/tgw-peering.html

  Transit Gateway VPN Attachment      https://docs.aws.amazon.com/vpc/latest/tgw/create-vpn-attachment.html

  Terraform Transit Gateway           https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway

  Terraform VPC Attachment            https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment

  Terraform TGW Route Table           https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table

  Terraform Association               https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_association

  Terraform Propagation               https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route_table_propagation

  Terraform TGW Route                 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_route
  -------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 66. Final SAA-C03 Summary

The fundamental Transit Gateway architecture is:

``` text
                       Transit Gateway
                              |
          +-------------------+-------------------+
          |                   |                   |
        VPC A               VPC B               VPC C
          |                   |                   |
       10.0/16             10.1/16             10.2/16
```

The routing model is:

``` text
SOURCE
  |
  v
VPC Route Table
  |
  | Destination CIDR -> TGW
  v
Transit Gateway
  |
  v
TGW Route Table
  |
  | Destination CIDR -> Attachment
  v
DESTINATION VPC
```

The most important distinctions are:

``` text
VPC Peering
= Point-to-point
= No transitive routing

Transit Gateway
= Central transit hub
= Transitive routing
= Multiple VPCs
= VPN / Direct Connect integration
= TGW route tables
= Route-table segmentation

PrivateLink
= Private service connectivity

VPC Endpoint
= Private access to supported AWS services
```

For SAA-C03, the strongest decision rule is:

**Use VPC Peering for simple direct VPC-to-VPC connectivity. Use Transit
Gateway when the architecture requires centralized, scalable, or
transitive connectivity among multiple VPCs and/or on-premises
networks.**
