# AWS Site-to-Site VPN Between Two AWS Accounts Using an EC2-Based strongSwan Customer Gateway

## SAA-C03 Professional Implementation Guide

## 1. Objective

This lab demonstrates a real AWS Site-to-Site VPN connection between two
different AWS accounts without requiring a physical on-premises router
or firewall.

The remote/on-premises side is simulated by an Ubuntu EC2 instance
running **strongSwan**. AWS Site-to-Site VPN requires a customer gateway
device, which can be a physical or software appliance. AWS also
publishes example configurations for strongSwan on Ubuntu.

The lab uses:

-   **Account A**: AWS VPC that represents the AWS environment.
-   **Account B**: simulated remote site containing an Ubuntu EC2
    instance running strongSwan.
-   **Account A**: Virtual Private Gateway (VGW), Customer Gateway
    (CGW), and Site-to-Site VPN connection.
-   **Account B**: EC2-based customer gateway with an Elastic IP.
-   Two IPsec tunnels are created by AWS for redundancy.

> **Important architecture point:** AWS Site-to-Site VPN is not simply a
> direct VPC-to-VPC VPN feature. The AWS VPN endpoint connects AWS to a
> customer gateway device. In this lab, the customer gateway device is
> an EC2 instance running strongSwan in Account B.

------------------------------------------------------------------------

# 2. Architecture

``` text
                              INTERNET
                                  |
                 ================================
                 |                              |
                 |        IPsec / IKE           |
                 |       Two VPN tunnels        |
                 |                              |
        AWS Account A                    AWS Account B
   -------------------------        -------------------------
   |                       |        |                       |
   |       VPC-A           |        |       VPC-B           |
   |    10.10.0.0/16       |        |    10.20.0.0/16       |
   |                       |        |                       |
   |  Private EC2          |        |  Ubuntu EC2           |
   |  10.10.1.10           |        |  strongSwan            |
   |                       |        |  Customer Gateway     |
   |        |              |        |       |               |
   |       VGW             |        |   Elastic IP           |
   |        |              |        |       |               |
   -------------------------        -------------------------
            |                                  |
            +========== Site-to-Site VPN ======+
```

## Traffic path

``` text
EC2-A 10.10.1.10
      |
      | 10.20.0.0/16
      v
VPC-A Route Table
      |
      v
Virtual Private Gateway
      |
      | IPsec Tunnel 1 / Tunnel 2
      |
      v
strongSwan EC2 in Account B
      |
      v
VPC-B Route Table
      |
      v
Private application EC2 10.20.1.10
```

------------------------------------------------------------------------

# 3. Lab Address Plan

  -----------------------------------------------------------------------
  Component               Account                 CIDR / Address
  ----------------------- ----------------------- -----------------------
  AWS VPC-A               Account A               `10.10.0.0/16`

  Public subnet A         Account A               `10.10.1.0/24`

  Private subnet A        Account A               `10.10.2.0/24`

  AWS VPC-B               Account B               `10.20.0.0/16`

  Public subnet B         Account B               `10.20.1.0/24`

  Private subnet B        Account B               `10.20.2.0/24`

  VPN server private IP   Account B               `10.20.1.10` example

  Application EC2         Account A               `10.10.2.10` example

  Application EC2         Account B               `10.20.2.10` example

  AWS VGW ASN             Account A               Default or custom

  strongSwan ASN          Account B               `65000` if using BGP;
                                                  static routing is
                                                  simpler for this lab

  VPN inside tunnel CIDRs AWS-managed             Two `/30` networks from
                                                  `169.254.0.0/16`
  -----------------------------------------------------------------------

Do not use overlapping VPC CIDRs. AWS routing requires distinct address
ranges for the two networks.

------------------------------------------------------------------------

# 4. Prerequisites

## Account A

-   AWS account with permissions to manage VPC, EC2 and Site-to-Site
    VPN.
-   A VPC with CIDR `10.10.0.0/16`.
-   Internet Gateway if you need public access to an EC2 instance.
-   One or more subnets.
-   An EC2 instance for connectivity testing.

## Account B

-   AWS account with permissions to manage VPC and EC2.
-   VPC with CIDR `10.20.0.0/16`.
-   Ubuntu EC2 instance to act as the customer gateway.
-   Elastic IP associated with the strongSwan EC2 instance.
-   IP forwarding enabled on the strongSwan instance.
-   Source/destination checks disabled on the strongSwan instance.

## Local workstation

For CLI/Terraform implementation:

``` bash
aws --version
terraform version
```

Configure separate AWS CLI profiles, for example:

``` bash
aws configure --profile account-a
aws configure --profile account-b
```

Verify:

``` bash
aws sts get-caller-identity --profile account-a
aws sts get-caller-identity --profile account-b
```

------------------------------------------------------------------------

# 5. Why Account B Can Simulate On-Premises

A customer gateway device can be a physical or software appliance. The
AWS customer gateway resource only tells AWS about the customer gateway
device; it does not configure the device itself.

In this lab:

``` text
Real-world model

On-premises router/firewall
        |
        | IPsec
        |
AWS VPN
```

becomes:

``` text
Lab model

Ubuntu EC2 + strongSwan
        |
        | IPsec
        |
AWS VPN
```

The EC2 instance is therefore the **customer gateway device**, while the
AWS Customer Gateway resource represents that device inside AWS.

------------------------------------------------------------------------

# 6. Management Console Implementation

## Phase 1: Build Account A

## Step 1: Create VPC-A

In Account A:

1.  Open the Amazon VPC console.
2.  Choose **Your VPCs**.
3.  Choose **Create VPC**.
4.  Select **VPC only**.
5.  Enter:
    -   Name: `VPN-A-VPC`
    -   IPv4 CIDR: `10.10.0.0/16`
6.  Create the VPC.

Official AWS documentation:

https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc.html

## Step 2: Create subnets

Create:

  Subnet      CIDR             Purpose
  ----------- ---------------- -------------------------------
  A-Public    `10.10.1.0/24`   Optional management/test host
  A-Private   `10.10.2.0/24`   Application/test host

Use at least two Availability Zones if you want to demonstrate a more
production-oriented architecture.

## Step 3: Create Internet Gateway

1.  VPC console.
2.  **Internet Gateways**.
3.  Create Internet Gateway.
4.  Attach it to `VPN-A-VPC`.

## Step 4: Create test EC2 instance

Launch Ubuntu or Amazon Linux in the private subnet if you have another
management path, or in the public subnet for a simple demonstration.

Example test host:

``` text
10.10.2.10
```

Allow ICMP or TCP 80 from `10.20.0.0/16` as appropriate for your test.

------------------------------------------------------------------------

# 7. Create Virtual Private Gateway in Account A

1.  Open VPC console.
2.  Select **Virtual private gateways**.
3.  Choose **Create virtual private gateway**.
4.  Name:

``` text
VPN-A-VGW
```

5.  Use the Amazon default ASN for a static-routing lab.
6.  Create the gateway.
7.  Select the VGW.
8.  Choose **Actions \> Attach to VPC**.
9.  Select `VPN-A-VPC`.
10. Attach it.

The VGW is the AWS-side VPN endpoint for this design.

------------------------------------------------------------------------

# 8. Build Account B as the Simulated Remote Site

## Step 1: Create VPC-B

In Account B:

1.  Open VPC console.
2.  Create VPC.
3.  CIDR:

``` text
10.20.0.0/16
```

## Step 2: Create subnets

Create:

  Subnet         CIDR             Purpose
  -------------- ---------------- -----------------------
  B-VPN-Public   `10.20.1.0/24`   strongSwan EC2
  B-Private      `10.20.2.0/24`   Application/test host

## Step 3: Internet connectivity

Attach an Internet Gateway to VPC-B and configure the public subnet
route table:

``` text
0.0.0.0/0 -> Internet Gateway
```

------------------------------------------------------------------------

# 9. Launch the strongSwan EC2 Instance

Launch an Ubuntu EC2 instance in `B-VPN-Public`.

Recommended lab characteristics:

  Setting                    Value
  -------------------------- -----------------------------------------------------
  OS                         Ubuntu LTS
  Instance type              Small general-purpose instance suitable for lab use
  Subnet                     `B-VPN-Public`
  Public IPv4                Enabled
  Elastic IP                 Associate one
  Source/destination check   Disable
  Security Group             Allow required VPN and management traffic

The Elastic IP becomes the public IP of the simulated customer gateway.

### Disable source/destination checking

EC2 console:

1.  Select the strongSwan instance.
2.  Choose **Actions**.
3.  Choose **Networking**.
4.  Choose **Change source/destination check**.
5.  Disable it.

This is required because the instance is forwarding traffic that is not
addressed to the instance itself.

------------------------------------------------------------------------

# 10. Security Group for strongSwan

For a lab, allow:

  Protocol     Port Source                   Purpose
  ---------- ------ ------------------------ ---------------
  UDP           500 `0.0.0.0/0`              IKE
  UDP          4500 `0.0.0.0/0`              NAT-T / IPsec
  ICMP          All `10.10.0.0/16`           Testing
  SSH            22 Your administration IP   Management

Avoid exposing SSH to `0.0.0.0/0` in a real deployment.

------------------------------------------------------------------------

# 11. Install strongSwan

Connect to the Ubuntu instance:

``` bash
ssh -i key.pem ubuntu@<ELASTIC-IP>
```

Update packages:

``` bash
sudo apt update
sudo apt upgrade -y
```

Install strongSwan:

``` bash
sudo apt install -y strongswan
```

Verify:

``` bash
ipsec version
```

------------------------------------------------------------------------

# 12. Enable IP Forwarding on the strongSwan EC2

Edit:

``` bash
sudo nano /etc/sysctl.conf
```

Add or enable:

``` text
net.ipv4.ip_forward=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
```

Apply:

``` bash
sudo sysctl -p
```

Verify:

``` bash
sysctl net.ipv4.ip_forward
```

Expected:

``` text
net.ipv4.ip_forward = 1
```

------------------------------------------------------------------------

# 13. Configure the AWS Customer Gateway in Account A

The Elastic IP of the strongSwan EC2 is required.

Example:

``` text
Customer Gateway public IP = 203.0.113.10
```

In Account A:

1.  VPC console.
2.  **Customer gateways**.
3.  **Create customer gateway**.
4.  Name:

``` text
Account-B-strongSwan-CGW
```

5.  Routing:

``` text
Static
```

6.  BGP ASN: use a private ASN such as:

``` text
65000
```

7.  IP address: enter the **Elastic IP of the strongSwan EC2**.
8.  Create customer gateway.

AWS requires the customer gateway public address to be static for the
normal public-IP customer gateway configuration.

------------------------------------------------------------------------

# 14. Create the AWS Site-to-Site VPN Connection

In Account A:

1.  VPC console.
2.  Choose **Site-to-Site VPN connections**.
3.  Choose **Create VPN connection**.
4.  Name:

``` text
Account-A-to-Account-B-VPN
```

5.  Target gateway type:

``` text
Virtual private gateway
```

6.  Virtual private gateway:

``` text
VPN-A-VGW
```

7.  Customer gateway:

``` text
Existing
```

8.  Select:

``` text
Account-B-strongSwan-CGW
```

9.  Routing options:

``` text
Static
```

10. Static IP prefix:

``` text
10.20.0.0/16
```

11. Create the VPN connection.

AWS creates two VPN tunnels for redundancy.

------------------------------------------------------------------------

# 15. Download the AWS VPN Configuration

After the VPN connection is created:

1.  Select the VPN connection.
2.  Choose **Download configuration**.
3.  Select a vendor/software configuration if available.
4.  Select a generic configuration if necessary.
5.  Download the configuration.

AWS provides strongSwan configuration examples. Review the generated
values carefully before applying them.

The downloaded configuration contains important values such as:

-   AWS tunnel outside IP addresses
-   IKE settings
-   Pre-shared keys
-   Tunnel inside addresses
-   Encryption algorithms
-   Authentication algorithms
-   Dead Peer Detection settings
-   Remote networks

Never publish the generated PSKs.

------------------------------------------------------------------------

# 16. Configure strongSwan

The exact syntax depends on the AWS-generated configuration and
strongSwan version. Use the AWS-generated configuration as the
authoritative starting point.

A typical policy-based strongSwan configuration has this conceptual
structure:

``` text
conn aws-tunnel-1
    left=%defaultroute
    leftid=<STRONGSWAN_PUBLIC_IP>
    leftsubnet=10.20.0.0/16
    right=<AWS_TUNNEL_1_PUBLIC_IP>
    rightsubnet=10.10.0.0/16
    ike=<AWS_IKE_PARAMETERS>
    esp=<AWS_ESP_PARAMETERS>
    keyexchange=ikev2
    authby=psk
    auto=start

conn aws-tunnel-2
    left=%defaultroute
    leftid=<STRONGSWAN_PUBLIC_IP>
    leftsubnet=10.20.0.0/16
    right=<AWS_TUNNEL_2_PUBLIC_IP>
    rightsubnet=10.10.0.0/16
    ike=<AWS_IKE_PARAMETERS>
    esp=<AWS_ESP_PARAMETERS>
    keyexchange=ikev2
    authby=psk
    auto=start
```

Use the exact tunnel parameters and PSKs supplied by AWS rather than
inventing values.

For the PSKs, protect `/etc/ipsec.secrets`:

``` bash
sudo chmod 600 /etc/ipsec.secrets
```

Restart:

``` bash
sudo systemctl restart strongswan-starter
```

Depending on the Ubuntu/strongSwan package version, the service may be
exposed under a slightly different systemd unit. Verify with:

``` bash
systemctl status strongswan-starter
systemctl status strongswan
```

------------------------------------------------------------------------

# 17. Account B Route Table

The VPC-B route table needs a route back to Account A's network.

Add:

``` text
Destination: 10.10.0.0/16
Target: strongSwan EC2 instance / ENI
```

This tells VPC-B that traffic destined for Account A should be sent
through the VPN appliance.

The strongSwan instance then encrypts the traffic and sends it through
the IPsec tunnel.

------------------------------------------------------------------------

# 18. Account A Route Table

The subnet containing the Account A test EC2 needs:

``` text
Destination: 10.20.0.0/16
Target: VPN-A-VGW
```

This is the critical AWS-side route.

Conceptually:

``` text
10.20.0.0/16 -> vgw-xxxxxxxx
```

------------------------------------------------------------------------

# 19. Account B Application Server

Launch another EC2 instance in the private subnet:

``` text
10.20.2.10
```

Install a simple web server:

``` bash
sudo apt update
sudo apt install -y nginx
```

Test locally:

``` bash
curl http://localhost
```

Allow HTTP from Account A:

``` text
TCP 80
Source: 10.10.0.0/16
```

Do not expose this application publicly if the objective is to
demonstrate private VPN connectivity.

------------------------------------------------------------------------

# 20. Test the VPN

From the Account A test EC2:

``` bash
ping 10.20.2.10
```

Then:

``` bash
curl http://10.20.2.10
```

If the VPN is working, the request travels through the Site-to-Site VPN
rather than through the public Internet path to the application.

On the strongSwan server:

``` bash
sudo ipsec statusall
```

Look for an established IKE/IPsec security association.

On AWS:

``` text
VPC Console
  -> Site-to-Site VPN connections
  -> Tunnel details
```

Both tunnels should be monitored. A single tunnel can be active while
the second is available for redundancy depending on configuration and
state.

------------------------------------------------------------------------

# 21. AWS CLI Implementation

The CLI implementation uses Account A for AWS VPN resources and Account
B for the simulated customer gateway EC2.

## Configure profiles

``` bash
aws configure --profile account-a
aws configure --profile account-b
```

Verify:

``` bash
aws sts get-caller-identity --profile account-a
aws sts get-caller-identity --profile account-b
```

Set variables in your shell:

``` bash
REGION=ap-south-1
AWS_PROFILE=account-a
VPC_A=vpc-xxxxxxxx
SUBNET_A=subnet-xxxxxxxx
VGW_NAME=VPN-A-VGW
CGW_IP=<ACCOUNT_B_STRONGSWAN_ELASTIC_IP>
```

------------------------------------------------------------------------

# 22. CLI: Create Virtual Private Gateway

``` bash
aws ec2 create-vpn-gateway \
  --type ipsec.1 \
  --tag-specifications 'ResourceType=vpn-gateway,Tags=[{Key=Name,Value=VPN-A-VGW}]' \
  --profile account-a \
  --region ap-south-1
```

Capture the returned `VpnGatewayId`.

Attach it:

``` bash
aws ec2 attach-vpn-gateway \
  --vpn-gateway-id vgw-xxxxxxxx \
  --vpc-id vpc-xxxxxxxx \
  --profile account-a \
  --region ap-south-1
```

Check:

``` bash
aws ec2 describe-vpn-gateways \
  --vpn-gateway-ids vgw-xxxxxxxx \
  --profile account-a \
  --region ap-south-1
```

------------------------------------------------------------------------

# 23. CLI: Create Customer Gateway

In Account A:

``` bash
aws ec2 create-customer-gateway \
  --type ipsec.1 \
  --public-ip <ACCOUNT_B_STRONGSWAN_ELASTIC_IP> \
  --bgp-asn 65000 \
  --tag-specifications 'ResourceType=customer-gateway,Tags=[{Key=Name,Value=Account-B-strongSwan-CGW}]' \
  --profile account-a \
  --region ap-south-1
```

AWS CLI requires a customer gateway IP and routing ASN for this form of
customer gateway resource. The public IP must correspond to the
software/physical customer gateway device.

------------------------------------------------------------------------

# 24. CLI: Create VPN Connection

Use the Customer Gateway ID and Virtual Private Gateway ID:

``` bash
aws ec2 create-vpn-connection \
  --type ipsec.1 \
  --customer-gateway-id cgw-xxxxxxxx \
  --vpn-gateway-id vgw-xxxxxxxx \
  --options StaticRoutesOnly=true \
  --profile account-a \
  --region ap-south-1
```

The VPN connection response contains the customer gateway configuration.

Save it securely. It contains tunnel configuration and authentication
material.

------------------------------------------------------------------------

# 25. CLI: Add the Static VPN Route

Add the remote Account B network to the VPN connection:

``` bash
aws ec2 create-vpn-connection-route \
  --vpn-connection-id vpn-xxxxxxxx \
  --destination-cidr-block 10.20.0.0/16 \
  --profile account-a \
  --region ap-south-1
```

Verify:

``` bash
aws ec2 describe-vpn-connections \
  --vpn-connection-ids vpn-xxxxxxxx \
  --profile account-a \
  --region ap-south-1
```

------------------------------------------------------------------------

# 26. CLI: Update Account A Route Table

Find the route table associated with the Account A subnet.

Then create the VGW route:

``` bash
aws ec2 create-route \
  --route-table-id rtb-xxxxxxxx \
  --destination-cidr-block 10.20.0.0/16 \
  --gateway-id vgw-xxxxxxxx \
  --profile account-a \
  --region ap-south-1
```

------------------------------------------------------------------------

# 27. CLI: Account B VPN Appliance Configuration

The EC2 and VPC infrastructure can be created through CLI, but the IPsec
tunnel configuration still has to be applied to strongSwan.

The AWS-generated configuration can be retrieved from the VPN connection
information and used as the basis for `/etc/ipsec.conf` and
`/etc/ipsec.secrets`.

Check VPN status:

``` bash
sudo ipsec statusall
```

Check kernel forwarding:

``` bash
sysctl net.ipv4.ip_forward
```

Expected:

``` text
net.ipv4.ip_forward = 1
```

------------------------------------------------------------------------

# 28. CLI: Verify Tunnel State

``` bash
aws ec2 describe-vpn-connections \
  --vpn-connection-ids vpn-xxxxxxxx \
  --query 'VpnConnections[0].VgwTelemetry' \
  --output table \
  --profile account-a \
  --region ap-south-1
```

Useful fields include:

-   `Status`
-   `OutsideIpAddress`
-   `AcceptedRouteCount`
-   `LastStatusChange`

------------------------------------------------------------------------

# 29. Terraform Implementation

Terraform should be split conceptually between the two accounts.

``` text
terraform-account-a/
├── provider.tf
├── vpc.tf
├── vpn.tf
├── routes.tf
└── outputs.tf

terraform-account-b/
├── provider.tf
├── vpc.tf
├── strongswan.tf
├── security.tf
└── outputs.tf
```

The Terraform AWS provider exposes resources including
`aws_customer_gateway`, `aws_vpn_gateway`, and `aws_vpn_connection`.

------------------------------------------------------------------------

# 30. Terraform Account A Provider

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
  alias   = "account_a"
  region  = "ap-south-1"
  profile = "account-a"
}
```

------------------------------------------------------------------------

# 31. Terraform Account A VGW

``` hcl
resource "aws_vpn_gateway" "account_a" {
  provider = aws.account_a

  vpc_id = aws_vpc.account_a.id

  tags = {
    Name = "VPN-A-VGW"
  }
}
```

If the VPC is already created outside Terraform, replace the reference
with the existing VPC ID through a variable.

------------------------------------------------------------------------

# 32. Terraform Account B strongSwan EC2

The strongSwan instance requires:

-   Ubuntu AMI
-   Public subnet
-   Public IP or Elastic IP
-   Security group allowing UDP 500 and UDP 4500
-   Disabled source/destination checking
-   IP forwarding

Example security group:

``` hcl
resource "aws_security_group" "strongswan" {
  provider = aws.account_b

  name   = "strongswan-vpn"
  vpc_id = aws_vpc.account_b.id

  ingress {
    description = "IKE"
    protocol    = "udp"
    from_port   = 500
    to_port     = 500
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "IPsec NAT-T"
    protocol    = "udp"
    from_port   = 4500
    to_port     = 4500
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH administration"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["YOUR_ADMIN_PUBLIC_IP/32"]
  }

  ingress {
    description = "ICMP from Account A"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

------------------------------------------------------------------------

# 33. Terraform Customer Gateway in Account A

Use the Elastic IP of the strongSwan instance:

``` hcl
resource "aws_customer_gateway" "account_b" {
  provider = aws.account_a

  bgp_asn    = 65000
  ip_address = var.strongswan_public_ip
  type       = "ipsec.1"

  tags = {
    Name = "Account-B-strongSwan-CGW"
  }
}
```

The `ip_address` must correspond to the public address of the customer
gateway device.

------------------------------------------------------------------------

# 34. Terraform VPN Connection

``` hcl
resource "aws_vpn_connection" "account_a_to_b" {
  provider = aws.account_a

  customer_gateway_id = aws_customer_gateway.account_b.id
  vpn_gateway_id      = aws_vpn_gateway.account_a.id

  type = "ipsec.1"

  static_routes_only = true

  local_ipv4_networks  = ["10.10.0.0/16"]
  remote_ipv4_networks = ["10.20.0.0/16"]

  tags = {
    Name = "Account-A-to-Account-B-VPN"
  }
}
```

Depending on the provider version and desired security configuration,
tunnel-specific options can be added. Treat the provider documentation
and generated AWS configuration as authoritative for supported
arguments.

------------------------------------------------------------------------

# 35. Terraform Static VPN Route

``` hcl
resource "aws_vpn_connection_route" "account_b" {
  provider = aws.account_a

  destination_cidr_block = "10.20.0.0/16"
  vpn_connection_id      = aws_vpn_connection.account_a_to_b.id
}
```

------------------------------------------------------------------------

# 36. Terraform Account A VPC Route

``` hcl
resource "aws_route" "to_account_b" {
  provider = aws.account_a

  route_table_id         = var.account_a_route_table_id
  destination_cidr_block = "10.20.0.0/16"
  gateway_id             = aws_vpn_gateway.account_a.id
}
```

------------------------------------------------------------------------

# 37. Terraform strongSwan Instance

Conceptually:

``` hcl
resource "aws_instance" "strongswan" {
  provider = aws.account_b

  ami                         = var.ubuntu_ami
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.vpn_public.id
  vpc_security_group_ids     = [aws_security_group.strongswan.id]
  associate_public_ip_address = true

  source_dest_check = false

  user_data = <<-EOF
              #!/bin/bash
              set -e
              apt-get update
              DEBIAN_FRONTEND=noninteractive apt-get install -y strongswan
              sysctl -w net.ipv4.ip_forward=1
              echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
              EOF

  tags = {
    Name = "Account-B-strongSwan"
  }
}
```

In a production-quality Terraform module, avoid embedding sensitive PSKs
directly in `user_data` or Terraform state. Use Secrets Manager or
another secure secret workflow where appropriate.

------------------------------------------------------------------------

# 38. Terraform Provider Configuration for Two Accounts

A common pattern is:

``` hcl
provider "aws" {
  alias   = "account_a"
  region  = "ap-south-1"
  profile = "account-a"
}

provider "aws" {
  alias   = "account_b"
  region  = "ap-south-1"
  profile = "account-b"
}
```

Then resources explicitly select their account:

``` hcl
provider = aws.account_a
```

or:

``` hcl
provider = aws.account_b
```

This is an important Terraform technique when building multi-account AWS
labs.

------------------------------------------------------------------------

# 39. Terraform Workflow

Account B first:

``` bash
terraform init
terraform validate
terraform plan
terraform apply
```

Obtain the strongSwan Elastic IP:

``` bash
terraform output strongswan_public_ip
```

Then provide that value to the Account A Terraform configuration:

``` bash
terraform plan
terraform apply
```

After AWS creates the VPN connection, retrieve the generated VPN
configuration and apply the strongSwan tunnel configuration.

Then validate:

``` bash
terraform output
```

and on strongSwan:

``` bash
sudo ipsec statusall
```

------------------------------------------------------------------------

# 40. Console vs CLI vs Terraform

  ---------------------------------------------------------------------------------------------------
  Area              Management Console   AWS CLI                         Terraform
  ----------------- -------------------- ------------------------------- ----------------------------
  VPC creation      Visual               Commands                        HCL

  VGW               Point and click      `create-vpn-gateway`            `aws_vpn_gateway`

  Customer Gateway  Point and click      `create-customer-gateway`       `aws_customer_gateway`

  VPN connection    Point and click      `create-vpn-connection`         `aws_vpn_connection`

  Static VPN route  Console route        `create-vpn-connection-route`   `aws_vpn_connection_route`
                    configuration                                        

  VPC route         Route table UI       `create-route`                  `aws_route`

  strongSwan        EC2 + SSH            EC2/SSM + shell                 EC2 + user data/modules

  Tunnel            Download from        Retrieve configuration/API      Retrieve output and
  configuration     console                                              configure appliance

  Repeatability     Low                  Medium                          High

  State management  AWS                  AWS                             Terraform state

  Best for          Learning/debugging   Automation/scripts              Repeatable infrastructure
  ---------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 41. Site-to-Site VPN vs VPC Peering vs Transit Gateway

  -----------------------------------------------------------------------
  Feature           Site-to-Site VPN  VPC Peering       Transit Gateway
  ----------------- ----------------- ----------------- -----------------
  Primary purpose   Hybrid/private    Direct VPC-to-VPC Central network
                    IPsec                               hub
                    connectivity                        

  IPsec encryption  Yes               No                Only when VPN
                                                        attachment is
                                                        used

  Customer gateway  Yes               No                No for VPC
  required                                              attachments

  Physical          No, software      No                No
  appliance         appliance can be                    
  required          used                                

  Cross-account     Possible          Yes               Yes

  Many VPCs         Not ideal as a    Many peering      Designed for many
                    VPC-to-VPC        relationships     networks
                    pattern                             

  AWS RAM           Not required for  Not required      Commonly used for
                    basic VGW VPN                       cross-account TGW
                                                        sharing

  Dynamic routing   Supported         No                Supported with
                                                        VPN/BGP

  SAA-C03 relevance High              High              High
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 42. Site-to-Site VPN vs Client VPN

  ---------------------------------------------------------------------------
  Feature                 Site-to-Site VPN           Client VPN
  ----------------------- -------------------------- ------------------------
  Main connection         Network-to-network         User/device-to-network

  Typical peer            Router/firewall/software   Laptop/desktop VPN
                          appliance                  client

  IPsec                   Yes                        OpenVPN-based client
                                                     connectivity is commonly
                                                     used

  Customer gateway        Required                   Not the same model

  On-premises network     Common                     Not required

  Individual remote users Not the primary use case   Primary use case
  ---------------------------------------------------------------------------

For a laptop connecting directly into a VPC, AWS Client VPN is generally
the appropriate service. This lab is specifically demonstrating
Site-to-Site VPN by using an EC2-based software customer gateway.

------------------------------------------------------------------------

# 43. Troubleshooting

## Problem 1: Tunnel is DOWN

Check:

``` bash
sudo ipsec statusall
```

Then verify:

-   Elastic IP is correct.
-   UDP 500 is allowed.
-   UDP 4500 is allowed.
-   strongSwan is running.
-   PSKs match.
-   IKE version matches.
-   Encryption and authentication parameters match.
-   AWS tunnel endpoint addresses are correct.

AWS VPN:

``` bash
aws ec2 describe-vpn-connections \
  --vpn-connection-ids vpn-xxxxxxxx \
  --profile account-a
```

## Problem 2: Tunnel UP but ping fails

Check routing.

Account A:

``` text
10.20.0.0/16 -> VGW
```

Account B:

``` text
10.10.0.0/16 -> strongSwan EC2
```

Check Linux routes:

``` bash
ip route
```

Check forwarding:

``` bash
sysctl net.ipv4.ip_forward
```

Check EC2 source/destination check:

``` text
Disabled
```

## Problem 3: Request reaches Account B but return traffic fails

Check the B-side VPC route table. The route back to `10.10.0.0/16` must
point to the VPN appliance.

Check the application security group:

``` text
Source: 10.10.0.0/16
```

## Problem 4: strongSwan cannot establish the tunnel

Review:

``` bash
sudo journalctl -u strongswan-starter
```

and:

``` bash
sudo ipsec statusall
```

Also verify that the AWS-generated configuration is compatible with the
installed strongSwan version.

------------------------------------------------------------------------

# 44. Security Considerations

Do not expose the strongSwan management interface unnecessarily.

Recommended controls:

-   Restrict SSH to a trusted administrator IP.
-   Allow UDP 500 and UDP 4500 for VPN operation.
-   Disable unnecessary ports.
-   Use strong authentication and AWS-provided tunnel configuration.
-   Protect PSKs.
-   Do not commit PSKs to Git.
-   Do not put PSKs in public Terraform repositories.
-   Use encrypted Terraform state storage for collaborative
    environments.
-   Use Secrets Manager or an equivalent secret-management approach when
    appropriate.
-   Remove the lab after training to avoid ongoing AWS charges.

------------------------------------------------------------------------

# 45. Cleanup

## Account A

Delete resources in this general order:

1.  Test EC2.
2.  VPN connection.
3.  VPN connection routes.
4.  Customer Gateway.
5.  Detach Virtual Private Gateway.
6.  Delete Virtual Private Gateway.
7.  Delete VPC resources.

CLI:

``` bash
aws ec2 delete-vpn-connection \
  --vpn-connection-id vpn-xxxxxxxx \
  --profile account-a
```

## Account B

1.  Stop/delete application EC2.
2.  Delete strongSwan EC2.
3.  Release Elastic IP.
4.  Delete security groups.
5.  Delete subnets.
6.  Delete route tables.
7.  Detach/delete Internet Gateway.
8.  Delete VPC.

If Terraform created the resources:

``` bash
terraform destroy
```

Review the plan carefully before confirming destruction.

------------------------------------------------------------------------

# 46. SAA-C03 Exam Concepts

## Customer Gateway

The customer gateway represents the physical or software appliance on
the customer side.

## Customer Gateway Device

The actual router, firewall, or software VPN appliance that terminates
the IPsec connection.

In this lab:

``` text
Customer Gateway Device = Ubuntu EC2 + strongSwan
```

## Virtual Private Gateway

The AWS-side VPN gateway attached to a VPC.

## VPN Connection

The AWS-managed IPsec connection between the AWS VPN endpoint and
customer gateway.

## Two VPN tunnels

AWS Site-to-Site VPN provides two tunnels for high availability.
Configure the customer gateway to support both tunnels.

## Static routing

Static routing explicitly defines the remote network prefix.

For this lab:

``` text
10.20.0.0/16
```

## Dynamic routing

Dynamic routing uses BGP to exchange routes. It is useful when the
network is larger or routes change frequently.

------------------------------------------------------------------------

# 47. SAA-C03 Architecture Decision Table

  -----------------------------------------------------------------------
  Scenario                            Appropriate architecture
  ----------------------------------- -----------------------------------
  Corporate office to AWS VPC         Site-to-Site VPN

  Corporate office has no hardware    Software VPN appliance such as
  router                              strongSwan

  Laptop user needs private access to Client VPN
  VPC                                 

  Two VPCs need direct AWS            VPC Peering or Transit Gateway
  connectivity                        

  Many VPCs across accounts           Transit Gateway + AWS RAM

  Need encrypted hybrid connectivity  Site-to-Site VPN
  over Internet                       

  Need dedicated private connectivity Direct Connect

  Need VPN plus multiple network      Transit Gateway + Site-to-Site VPN
  attachments                         
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 48. Important Lab Limitation

This implementation is excellent for learning and demonstrating AWS
Site-to-Site VPN, but the strongSwan EC2 is a **simulated
customer/on-premises device**.

The architecture is therefore:

``` text
AWS Account A
      |
      | AWS Site-to-Site VPN
      |
      v
Software Customer Gateway
      |
      v
AWS Account B EC2 network
```

It should not be described as AWS directly creating a Site-to-Site VPN
between two VPCs.

For a production multi-account AWS-only network, evaluate Transit
Gateway with AWS RAM instead.

------------------------------------------------------------------------

# 49. Official AWS Documentation

## AWS Site-to-Site VPN

https://docs.aws.amazon.com/vpn/latest/s2svpn/

## Get started with AWS Site-to-Site VPN

https://docs.aws.amazon.com/vpn/latest/s2svpn/SetUpVPNConnections.html

## Create a Site-to-Site VPN connection

https://docs.aws.amazon.com/vpn/latest/s2svpn/create-vpn-connection.html

## Customer gateway devices

https://docs.aws.amazon.com/vpn/latest/s2svpn/your-cgw.html

## Customer gateway requirements

https://docs.aws.amazon.com/vpn/latest/s2svpn/CGRequirements.html

## AWS VPN configuration files

https://docs.aws.amazon.com/vpn/latest/s2svpn/example-configuration-files.html

## AWS CLI: create-customer-gateway

https://docs.aws.amazon.com/cli/latest/reference/ec2/create-customer-gateway.html

## AWS CLI: create-vpn-connection

https://docs.aws.amazon.com/cli/latest/reference/ec2/create-vpn-connection.html

## AWS CLI: EC2 Site-to-Site VPN commands

https://docs.aws.amazon.com/cli/latest/reference/ec2/

## AWS Virtual Private Gateway

https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html

------------------------------------------------------------------------

# 50. Terraform Documentation

## AWS VPN Connection

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection

## AWS Customer Gateway

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway

## AWS VPN Gateway

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway

## AWS VPN Connection Route

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection_route

------------------------------------------------------------------------

# 51. Final SAA-C03 Mental Model

``` text
                         AWS ACCOUNT A

                  ┌───────────────────────┐
                  │        VPC-A          │
                  │     10.10.0.0/16      │
                  │                       │
                  │       EC2-A           │
                  └───────────┬───────────┘
                              │
                              │ Route
                              │ 10.20.0.0/16
                              ▼
                       Virtual Private
                          Gateway
                              │
                       AWS VPN Service
                              │
                       IPsec Tunnel 1
                       IPsec Tunnel 2
                              │
                              ▼
                  ┌───────────────────────┐
                  │     AWS ACCOUNT B     │
                  │                       │
                  │  Ubuntu EC2           │
                  │  strongSwan           │
                  │  Customer Gateway     │
                  │                       │
                  │  10.20.1.10           │
                  └───────────┬───────────┘
                              │
                              │ Route
                              │ 10.10.0.0/16
                              ▼
                  ┌───────────────────────┐
                  │        VPC-B          │
                  │     10.20.0.0/16      │
                  │                       │
                  │       EC2-B           │
                  └───────────────────────┘
```

The core SAA-C03 relationship is:

``` text
Customer network/device
        |
Customer Gateway Device
        |
Customer Gateway resource
        |
IPsec Site-to-Site VPN
        |
Virtual Private Gateway / Transit Gateway
        |
AWS VPC
```

For this two-account demonstration, Account B's **Ubuntu + strongSwan
EC2** takes the role of the customer gateway device. Account A's **VGW +
Site-to-Site VPN** provides the AWS-side VPN endpoint.
