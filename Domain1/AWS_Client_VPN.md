# AWS Client VPN

## Professional AWS Solutions Architect Associate (SAA-C03) Documentation

**Scope:** AWS Client VPN concepts, architecture, authentication,
authorization, routing, security, manual Management Console
implementation, AWS CLI implementation, Terraform implementation, laptop
connectivity, verification, troubleshooting, design considerations, and
SAA-C03 exam points.

**AWS documentation basis:** This document follows the current AWS
Client VPN Administrator Guide, AWS Client VPN User Guide, AWS CLI
reference, and current HashiCorp AWS provider documentation.

------------------------------------------------------------------------

# 1. AWS Client VPN Overview

AWS Client VPN is a managed client-based VPN service that allows
individual users and devices to securely connect to AWS resources and
networks.

A laptop, desktop, or other supported client runs a VPN client
application. The client establishes an encrypted VPN session with an AWS
Client VPN endpoint. The endpoint then provides controlled access to
selected VPC networks, peered networks, on-premises networks, or other
reachable networks.

AWS describes the Client VPN endpoint as the termination point for
Client VPN sessions.

Typical use cases include:

-   Remote employees accessing private EC2 instances
-   Administrators connecting to private management servers
-   Developers accessing private application environments
-   Accessing private databases without exposing them to the Internet
-   Connecting users to multiple VPCs through Transit Gateway
-   Providing controlled access to on-premises networks reachable from
    AWS
-   Temporary remote access for operations teams

AWS Client VPN is different from AWS Site-to-Site VPN. Client VPN is
designed for individual client devices, while Site-to-Site VPN connects
an entire external network or customer gateway device to AWS.

------------------------------------------------------------------------

# 2. Basic Architecture

A simple VPC-based Client VPN architecture looks like this:

``` text
                         Internet
                            |
                            |
                    +----------------+
                    | User Laptop    |
                    | Windows/macOS  |
                    | AWS VPN Client |
                    +--------+-------+
                             |
                        Encrypted VPN
                             |
                             v
                  +-----------------------+
                  | AWS Client VPN        |
                  | Endpoint              |
                  | Authentication        |
                  | Authorization         |
                  | Route Table           |
                  +----------+------------+
                             |
                    Target Network
                    Association
                             |
              +--------------+--------------+
              |                             |
              v                             v
        Private Subnet A              Private Subnet B
              |                             |
          +---+----+                    +---+----+
          |  EC2   |                    |  RDS   |
          +--------+                    +--------+

                    AWS VPC
```

The important traffic path is:

``` text
Laptop
   |
   | VPN tunnel
   v
Client VPN Endpoint
   |
   | Client VPN route
   v
Target VPC Subnet
   |
   | VPC routing + Security Groups
   v
Private AWS Resource
```

The VPN endpoint is not itself an EC2 instance that you manage. AWS
manages the Client VPN service.

------------------------------------------------------------------------

# 3. Core Client VPN Components

  -----------------------------------------------------------------------
  Component                           Purpose
  ----------------------------------- -----------------------------------
  Client VPN Endpoint                 Managed VPN termination point

  Client CIDR                         IP address pool assigned to
                                      connected VPN clients

  Target Network                      VPC subnet associated with the
                                      Client VPN endpoint, or a Transit
                                      Gateway association

  Route Table                         Determines destination networks
                                      reachable through Client VPN

  Authorization Rule                  Determines which clients/groups can
                                      access a destination network

  Authentication                      Determines whether the user/device
                                      can establish a VPN session

  Security Group                      Controls traffic to/from resources
                                      and Client VPN network interfaces

  Server Certificate                  TLS certificate used by the Client
                                      VPN endpoint

  Client Certificate                  Used for mutual certificate
                                      authentication

  Active Directory                    Optional user-based authentication
                                      source

  SAML IdP                            Optional federated authentication
                                      source

  AWS VPN Client                      AWS-provided client application

  OpenVPN Client                      Alternative client for supported
                                      authentication configurations
  -----------------------------------------------------------------------

AWS documents the endpoint, target network, route, and authorization
rule as core Client VPN concepts.

------------------------------------------------------------------------

# 4. Client VPN Endpoint

The Client VPN endpoint is the AWS resource that terminates VPN
sessions.

An endpoint contains configuration such as:

-   Client IP address range
-   Authentication method
-   Server certificate
-   Security groups
-   Split-tunnel configuration
-   DNS servers
-   VPN port
-   Transport protocol
-   Connection logging
-   Session timeout
-   Client login banner
-   Target network associations
-   Authorization rules
-   Client VPN routes

The endpoint must be created in the same AWS account as the intended
target network.

------------------------------------------------------------------------

# 5. Client CIDR Block

The Client CIDR block is the private IP address range from which
connected VPN clients receive addresses.

Example:

``` text
Client VPN CIDR:
10.250.0.0/22
```

A connected laptop could receive an address such as:

``` text
10.250.0.10
```

Another client might receive:

``` text
10.250.0.11
```

The client CIDR must not overlap with:

-   VPC CIDR
-   Target network CIDR
-   Routes associated with the Client VPN endpoint
-   Relevant connected network ranges

AWS recommends a /22 for typical Client VPN configurations, and the
client CIDR cannot be changed after endpoint creation.

Example network plan:

  Network               CIDR
  --------------------- ---------------
  VPC                   10.0.0.0/16
  Private subnet        10.0.1.0/24
  Public subnet         10.0.2.0/24
  Client VPN pool       10.250.0.0/22
  On-premises network   172.16.0.0/16

------------------------------------------------------------------------

# 6. Authentication

Authentication answers:

> Is this client/user allowed to establish a VPN session?

AWS Client VPN supports:

1.  Active Directory authentication
2.  Mutual authentication using certificates
3.  SAML-based federated authentication
4.  Combinations of mutual authentication with user-based authentication

A server certificate in AWS Certificate Manager is required for a Client
VPN endpoint.

## 6.1 Mutual Authentication

Mutual authentication uses certificates.

The VPN server authenticates the client certificate, and the client
authenticates the server certificate.

Typical certificate structure:

``` text
Certificate Authority
        |
        +----------------+
        |                |
        v                v
 Server Certificate   Client Certificate
        |                |
        v                v
 AWS Client VPN       User Laptop
 Endpoint
```

AWS requires a server certificate and at least one client
certificate/key for mutual authentication.

A separate client certificate can be created for each user/device.

This is useful when you want certificate-based device authentication
without deploying Active Directory or SAML.

## 6.2 Active Directory Authentication

With Active Directory authentication:

``` text
Laptop
   |
   v
Client VPN
   |
   v
Active Directory
   |
   +--> Username/password
   +--> Optional MFA
```

Authorization rules can reference Active Directory groups.

## 6.3 SAML Authentication

SAML authentication integrates Client VPN with a SAML-based identity
provider.

Typical flow:

``` text
Laptop
   |
   v
AWS VPN Client
   |
   v
Browser
   |
   v
SAML Identity Provider
   |
   v
Authentication
   |
   v
Client VPN session
```

SAML is useful for centralized identity, SSO, and enterprise
authentication.

------------------------------------------------------------------------

# 7. Authentication vs Authorization

These two concepts must not be confused.

  Concept          Question
  ---------------- --------------------------------------------
  Authentication   Who are you?
  Authorization    What network are you allowed to access?
  Security Group   What traffic is allowed to/from resources?
  Route            Where should traffic go?

Example:

``` text
User authenticates successfully
             |
             v
       VPN session created
             |
             v
 Authorization rule checked
             |
             v
       Route selected
             |
             v
 Security Group evaluated
             |
             v
      AWS resource reached
```

A successful VPN login does not automatically mean that the user can
access every resource in the VPC.

------------------------------------------------------------------------

# 8. Target Network

A target network is the network associated with the Client VPN endpoint.

For a VPC-based endpoint, the target network is a subnet.

Example:

``` text
VPC: 10.0.0.0/16

Private Subnet A: 10.0.1.0/24
Private Subnet B: 10.0.2.0/24

Client VPN
    |
    +--> Associate Subnet A
    +--> Associate Subnet B
```

Associating the first subnet changes the endpoint to an available state
and creates the local route for the VPC.

AWS recommends associating additional subnets in different Availability
Zones when high availability is required.

One subnet association can provide access to the VPC when routing and
authorization are correctly configured. Additional associations provide
additional Availability Zone resilience.

------------------------------------------------------------------------

# 9. Client VPN Route Table

Each Client VPN endpoint has a route table.

Example:

``` text
Destination       Target
--------------------------------
10.0.0.0/16       Target subnet
10.20.0.0/16      Target subnet
172.16.0.0/16     Target subnet
0.0.0.0/0         Target subnet
```

A route tells Client VPN where traffic for a destination network should
be directed.

Examples:

  Destination     Purpose
  --------------- ------------------------------
  10.0.0.0/16     Access VPC
  10.20.0.0/16    Access peered VPC
  172.16.0.0/16   Access on-premises network
  0.0.0.0/0       Internet/full-tunnel routing

The VPC's local route is automatically added when the target subnet is
associated.

Additional routes are required for additional networks.

------------------------------------------------------------------------

# 10. Authorization Rules

Authorization rules control which users can access destination networks.

Example:

``` text
Destination:
10.0.0.0/16

Grant:
All users
```

Or:

``` text
Destination:
10.0.10.0/24

Grant:
Developers group
```

AWS describes authorization rules as network access rules. A rule is
required for each network that clients should be allowed to access.

Authorization can be:

-   All clients
-   Active Directory group
-   SAML identity provider group

AWS Client VPN uses longest-prefix matching when evaluating
authorization rules.

------------------------------------------------------------------------

# 11. Security Groups

Security groups are a separate control from Client VPN authorization
rules.

When a subnet is associated with Client VPN, AWS applies the VPC default
security group to the Client VPN network interfaces by default.

You can associate a different security group.

For example:

``` text
Client VPN Security Group
sg-clientvpn
       |
       | TCP 22
       v
EC2 Security Group
sg-private-ec2
```

The EC2 security group can allow traffic from the Client VPN security
group.

Example inbound rule:

``` text
Type: SSH
Protocol: TCP
Port: 22
Source: sg-clientvpn
```

This is generally preferable to opening SSH to the Client VPN client
CIDR when a security-group reference is appropriate.

------------------------------------------------------------------------

# 12. Split Tunnel vs Full Tunnel

Client VPN supports split-tunnel and full-tunnel configurations.

## Split Tunnel

Only traffic destined for networks configured through Client VPN routes
travels through the VPN.

Example:

``` text
Laptop
 |
 +---- Internet traffic ----> ISP
 |
 +---- 10.0.0.0/16 --------> Client VPN
```

Advantages:

-   Less VPN bandwidth usage
-   Normal Internet traffic remains local
-   Reduced VPN processing
-   Useful when only private AWS networks need access

## Full Tunnel

All IPv4 traffic is routed through the VPN.

Example:

``` text
Laptop
 |
 +---- 10.0.0.0/16 ----> AWS
 |
 +---- Internet --------> AWS
```

The Client VPN route table can contain:

``` text
0.0.0.0/0
```

The VPC subnet used for the route must then be configured to provide
Internet access, typically through an Internet Gateway and appropriate
routing/NAT architecture.

  -----------------------------------------------------------------------
  Feature                 Split Tunnel            Full Tunnel
  ----------------------- ----------------------- -----------------------
  AWS private traffic     VPN                     VPN

  Normal Internet traffic Local Internet          VPN

  VPN bandwidth           Lower                   Higher

  Centralized Internet    Not generally           Possible
  inspection                                      

  Client configuration    Simpler for AWS-only    Requires Internet
                          access                  routing

  Typical use             AWS resource access     Centralized traffic
                                                  control
  -----------------------------------------------------------------------

For a first VPC-access lab, split tunnel is usually simpler.

------------------------------------------------------------------------

# 13. Client VPN vs Site-to-Site VPN

  -------------------------------------------------------------------------
  Feature                 AWS Client VPN          AWS Site-to-Site VPN
  ----------------------- ----------------------- -------------------------
  Primary purpose         Individual              Network-to-network
                          users/devices           

  Client device           Laptop/desktop/mobile   Customer
                                                  gateway/router/firewall

  Typical user            Remote employee/admin   Network administrator

  VPN client software     Required                Not normally required for
                                                  users

  Authentication          AD, SAML, certificates  IKE/IPsec, customer
                                                  gateway

  Endpoint                Client VPN endpoint     VGW/TGW + customer
                                                  gateway

  User-based access       Yes                     No

  Remote user access      Yes                     Indirect

  On-premises network     Possible through AWS    Primary use case
  connection              routing                 

  SAA-C03 topic           Yes                     Yes
  -------------------------------------------------------------------------

------------------------------------------------------------------------

# 14. Client VPN vs Direct Connect

  -----------------------------------------------------------------------
  Feature                 Client VPN              AWS Direct Connect
  ----------------------- ----------------------- -----------------------
  Connectivity            Internet-based VPN      Dedicated network
                                                  connection

  Main purpose            Remote users            Private network
                                                  connectivity

  Encryption              VPN encryption          Direct Connect itself
                                                  is not encryption

  Client software         Required                Not required for
                                                  individual users

  Typical scale           Users/devices           Enterprise networks

  Setup complexity        Lower                   Higher

  Physical circuit        No                      Yes

  Internet dependency     Yes                     Dedicated connectivity

  User authentication     Yes                     Not user-oriented
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 15. Client VPN vs Site-to-Site VPN vs Direct Connect

  -----------------------------------------------------------------------
  Requirement       Client VPN        Site-to-Site VPN  Direct Connect
  ----------------- ----------------- ----------------- -----------------
  Remote laptop     Excellent fit     Not the normal    Not the normal
  access                              design            design

  Branch office to  Possible but not  Common            Common
  AWS               primary                             

  Dedicated circuit No                No                Yes

  User identity     Yes               No                No

  Encrypted tunnel  Yes               Yes               Not by default

  Internet required Yes               Yes               No for primary
                                                        connection

  Fast deployment   Yes               Yes               No

  Enterprise        Not primary       Yes               Yes
  private WAN                                           
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 16. End-to-End Laptop-to-VPC Architecture

For the implementation in this document, use mutual certificate
authentication.

``` text
                         Internet
                             |
                             |
                     +-------+-------+
                     | Windows       |
                     | Laptop        |
                     | AWS VPN Client|
                     +-------+-------+
                             |
                      TLS/OpenVPN
                      encrypted VPN
                             |
                             v
                  +----------------------+
                  | Client VPN Endpoint  |
                  | Client CIDR          |
                  | Authentication       |
                  | Authorization        |
                  | Route Table          |
                  +----------+-----------+
                             |
                       Target Subnet
                             |
                             v
                 +------------------------+
                 | VPC 10.0.0.0/16       |
                 |                        |
                 | +--------------------+ |
                 | | Private Subnet      | |
                 | | 10.0.1.0/24        | |
                 | |                    | |
                 | | EC2 10.0.1.10      | |
                 | +--------------------+ |
                 +------------------------+
```

------------------------------------------------------------------------

# 17. Lab Network Design

Use the following example values.

  Item              Example
  ----------------- -----------------------------------
  AWS Region        ap-south-1
  VPC               10.0.0.0/16
  Private subnet    10.0.1.0/24
  Client VPN CIDR   10.250.0.0/22
  Client VPN mode   Split tunnel
  Authentication    Mutual certificate authentication
  Protocol          OpenVPN
  Target            VPC subnet
  Test resource     EC2 instance
  Test protocol     SSH or application TCP port

Important: Do not use overlapping CIDRs.

------------------------------------------------------------------------

# 18. Prerequisites

Before creating the endpoint, prepare:

1.  An AWS account
2.  A VPC
3.  At least one subnet
4.  A security group
5.  A test EC2 instance or another private resource
6.  AWS Certificate Manager access
7.  Client VPN permissions
8.  A laptop with the AWS Client VPN application or a supported OpenVPN
    client
9.  Server and client certificates for mutual authentication

AWS Client VPN requires a server certificate in ACM regardless of the
authentication method.

------------------------------------------------------------------------

# 19. Generate Certificates for Mutual Authentication

AWS provides a procedure using OpenVPN Easy-RSA.

## Linux/macOS

Clone Easy-RSA:

``` bash
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3
```

Initialize PKI:

``` bash
./easyrsa init-pki
```

Create the CA:

``` bash
./easyrsa build-ca nopass
```

Generate the server certificate:

``` bash
./easyrsa --san=DNS:server build-server-full server nopass
```

Generate a client certificate:

``` bash
./easyrsa build-client-full client1.domain.tld nopass
```

The important files include:

``` text
pki/ca.crt
pki/issued/server.crt
pki/private/server.key
pki/issued/client1.domain.tld.crt
pki/private/client1.domain.tld.key
```

Keep the client private key secure.

Do not commit private keys to Git.

------------------------------------------------------------------------

# 20. Import Certificates into ACM

The server certificate and private key must be available in ACM in the
same AWS Region where the Client VPN endpoint will be created.

Example:

``` bash
aws acm import-certificate \
  --certificate fileb://server.crt \
  --private-key fileb://server.key \
  --certificate-chain fileb://ca.crt
```

If the client certificate is from a different CA, it must also be
imported into ACM.

If the client and server certificates are issued by the same CA, AWS
documentation allows the server certificate ARN to be used for the
client certificate chain configuration.

Example:

``` bash
aws acm list-certificates --region ap-south-1
```

Record:

``` text
Server Certificate ARN
```

You will need this ARN when creating the Client VPN endpoint.

------------------------------------------------------------------------

# 21. Management Console Implementation

## Step 1: Open VPC Console

Open:

https://console.aws.amazon.com/vpc/

Select the required Region.

Example:

``` text
Asia Pacific (Mumbai)
ap-south-1
```

Navigate to:

``` text
VPC
  -> Client VPN endpoints
```

Choose:

``` text
Create Client VPN endpoint
```

------------------------------------------------------------------------

# 22. Step 2: Configure Endpoint

Choose the standard/manual setup.

Set:

``` text
Name:
company-client-vpn

Client IPv4 CIDR:
10.250.0.0/22
```

The Client CIDR must not overlap with your VPC or other routed networks.

------------------------------------------------------------------------

# 23. Step 3: Configure Authentication

For this lab select:

``` text
Mutual authentication
```

Specify the server certificate ARN.

For the client certificate chain, use the appropriate ACM certificate/CA
configuration according to the certificate setup.

The endpoint requires a server certificate.

------------------------------------------------------------------------

# 24. Step 4: Configure Security Group

Choose a security group associated with the VPC.

For example:

``` text
sg-clientvpn
```

You can use a dedicated security group.

Example:

``` text
sg-clientvpn
```

Then configure the target EC2 security group to allow required traffic
from the Client VPN security group.

For SSH testing:

``` text
Inbound:
TCP 22
Source:
sg-clientvpn
```

Do not unnecessarily open:

``` text
0.0.0.0/0
```

for private management access.

------------------------------------------------------------------------

# 25. Step 5: Configure DNS

If your private resources use DNS names, specify appropriate DNS
servers.

For VPC DNS resolution, the Amazon-provided VPC resolver is commonly:

``` text
VPC CIDR + 2
```

For:

``` text
10.0.0.0/16
```

the VPC resolver is:

``` text
10.0.0.2
```

Use DNS settings appropriate to your environment.

------------------------------------------------------------------------

# 26. Step 6: Enable Split Tunnel

For a simple AWS private-resource access lab:

``` text
Split-tunnel:
Enable
```

This means only traffic for configured VPN destinations is sent through
Client VPN.

For example:

``` text
10.0.0.0/16 -> VPN
Internet     -> Local ISP
```

------------------------------------------------------------------------

# 27. Step 7: Create the Endpoint

Review the configuration.

Choose:

``` text
Create Client VPN endpoint
```

Initially, the endpoint may show a state such as:

``` text
pending-associate
```

This is expected because a target network has not yet been associated.

------------------------------------------------------------------------

# 28. Step 8: Associate a Target Network

Select the Client VPN endpoint.

Go to:

``` text
Target network associations
    -> Associate target network
```

Select:

``` text
VPC:
your VPC

Subnet:
private subnet
```

For example:

``` text
VPC:
vpc-0123456789

Subnet:
subnet-0123456789
```

Choose:

``` text
Associate target network
```

Wait until the association becomes:

``` text
associated
```

The Client VPN endpoint can now become:

``` text
available
```

AWS automatically adds the local route for the VPC.

------------------------------------------------------------------------

# 29. Step 9: Add Authorization Rule

Go to:

``` text
Authorization rules
    -> Add authorization rule
```

Set:

``` text
Destination network:
10.0.0.0/16
```

For a lab:

``` text
Grant access:
Allow access to all users
```

Choose:

``` text
Add authorization rule
```

For production, use appropriate AD or SAML group-based authorization
where applicable.

------------------------------------------------------------------------

# 30. Step 10: Verify Client VPN Route

Go to:

``` text
Route table
```

You should see a route similar to:

``` text
Destination:
10.0.0.0/16

Target:
Associated subnet
```

You do not normally need to manually add another route for the VPC local
network because AWS adds the local route when the target network is
associated.

------------------------------------------------------------------------

# 31. Step 11: Configure EC2 Security Group

Suppose the private EC2 instance has:

``` text
Private IP:
10.0.1.10
```

Its security group should allow the required protocol from the Client
VPN security group.

Example:

``` text
Inbound Rule

Type: SSH
Protocol: TCP
Port: 22
Source: sg-clientvpn
```

For an HTTP application:

``` text
Type: HTTP
Protocol: TCP
Port: 80
Source: sg-clientvpn
```

------------------------------------------------------------------------

# 32. Step 12: Export Client Configuration

Select:

``` text
Client VPN endpoint
    -> Download Client Configuration
```

AWS exports an OpenVPN configuration file:

``` text
client-config.ovpn
```

The configuration contains the endpoint information required by the VPN
client.

For mutual authentication, the client certificate and private key must
also be supplied in the configuration as required by AWS.

------------------------------------------------------------------------

# 33. Step 13: Add Client Certificate and Private Key

For mutual authentication, AWS requires the client certificate and
private key information in the `.ovpn` configuration.

One supported method is to add certificate/key paths:

``` text
<cert>
...
</cert>

<key>
...
</key>
```

or use the file/path method described by the AWS documentation.

Protect the private key.

Do not send it through insecure channels.

Do not upload it to GitHub.

------------------------------------------------------------------------

# 34. Step 14: Install AWS Client VPN on Windows

Install the AWS-provided VPN client for Windows.

AWS currently documents support for Windows x64 and Windows Arm64.

Open the AWS VPN Client application.

Choose:

``` text
Add Profile
```

Provide:

``` text
Display name:
AWS-Production-VPC

VPN Configuration File:
client-config.ovpn
```

Save the profile.

------------------------------------------------------------------------

# 35. Step 15: Connect from the Laptop

Select:

``` text
AWS-Production-VPC
```

Choose:

``` text
Connect
```

If mutual authentication is configured correctly, the client uses the
client certificate and private key.

The VPN client should show a connected state.

------------------------------------------------------------------------

# 36. Step 16: Verify the VPN Connection

On Windows:

``` powershell
ipconfig
```

Look for the VPN adapter.

You should see an address from the Client VPN CIDR.

For example:

``` text
10.250.x.x
```

Check the route:

``` powershell
route print
```

You should see the VPC route:

``` text
10.0.0.0/16
```

Test an EC2 private IP:

``` powershell
ping 10.0.1.10
```

If ICMP is not allowed, test the actual application port.

For SSH:

``` powershell
ssh ec2-user@10.0.1.10
```

For a web application:

``` powershell
curl http://10.0.1.10
```

------------------------------------------------------------------------

# 37. Important Point About Ping

A failed ping does not automatically mean Client VPN is broken.

ICMP must be allowed by the EC2 security group and operating system
firewall.

For example:

``` text
Client VPN connected
        |
        v
Route correct
        |
        v
Security group blocks ICMP
        |
        v
Ping fails
```

SSH or HTTP can still work.

Always test the actual application protocol.

------------------------------------------------------------------------

# 38. Accessing a Private EC2 Instance

Example:

``` text
VPC:
10.0.0.0/16

EC2:
10.0.1.10

Client:
10.250.0.10
```

Traffic:

``` text
Laptop
10.250.0.10
     |
     | VPN
     v
Client VPN
     |
     | 10.0.0.0/16
     v
EC2
10.0.1.10
```

The EC2 instance does not need a public IP for this private access
scenario.

------------------------------------------------------------------------

# 39. AWS CLI Implementation

The following CLI example uses mutual certificate authentication.

Set the Region:

``` bash
aws configure
```

Or:

``` bash
export AWS_DEFAULT_REGION=ap-south-1
```

Windows PowerShell:

``` powershell
$env:AWS_DEFAULT_REGION="ap-south-1"
```

------------------------------------------------------------------------

# 40. CLI Step 1: Create Client VPN Endpoint

Example:

``` bash
aws ec2 create-client-vpn-endpoint \
  --client-cidr-block 10.250.0.0/22 \
  --server-certificate-arn arn:aws:acm:ap-south-1:123456789012:certificate/xxxxxxxx \
  --authentication-options Type=certificate-authentication,MutualAuthentication={ClientRootCertificateChainArn=arn:aws:acm:ap-south-1:123456789012:certificate/yyyyyyyy} \
  --connection-log-options Enabled=false \
  --split-tunnel \
  --security-group-ids sg-0123456789abcdef0 \
  --description "AWS Client VPN"
```

The command creates the endpoint.

Record the returned:

``` text
ClientVpnEndpointId
```

Example:

``` text
cvpn-endpoint-0123456789abcdef0
```

------------------------------------------------------------------------

# 41. CLI Step 2: Associate Target Network

``` bash
aws ec2 associate-client-vpn-target-network \
  --client-vpn-endpoint-id cvpn-endpoint-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0
```

Check:

``` bash
aws ec2 describe-client-vpn-target-networks \
  --client-vpn-endpoint-id cvpn-endpoint-0123456789abcdef0
```

Wait until the association is available.

------------------------------------------------------------------------

# 42. CLI Step 3: Add Authorization Rule

``` bash
aws ec2 authorize-client-vpn-ingress \
  --client-vpn-endpoint-id cvpn-endpoint-0123456789abcdef0 \
  --target-network-cidr 10.0.0.0/16 \
  --authorize-all-groups
```

This allows all authenticated clients to access the VPC CIDR.

For production, configure the appropriate group-based authorization
instead.

------------------------------------------------------------------------

# 43. CLI Step 4: Add Additional Route

For the VPC local route, AWS automatically adds the route when the
target network is associated.

For another network, create an explicit route.

Example:

``` bash
aws ec2 create-client-vpn-route \
  --client-vpn-endpoint-id cvpn-endpoint-0123456789abcdef0 \
  --destination-cidr-block 10.20.0.0/16 \
  --target-vpc-subnet-id subnet-0123456789abcdef0
```

For Internet access:

``` bash
aws ec2 create-client-vpn-route \
  --client-vpn-endpoint-id cvpn-endpoint-0123456789abcdef0 \
  --destination-cidr-block 0.0.0.0/0 \
  --target-vpc-subnet-id subnet-0123456789abcdef0
```

Do not add `0.0.0.0/0` unless you intentionally want full-tunnel
Internet routing and have configured the VPC path appropriately.

------------------------------------------------------------------------

# 44. CLI Step 5: Export Client Configuration

``` bash
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id cvpn-endpoint-0123456789abcdef0 \
  --output text > client-config.ovpn
```

Then add the client certificate and private key information for mutual
authentication as described by AWS.

------------------------------------------------------------------------

# 45. CLI Step 6: Verify Endpoint

``` bash
aws ec2 describe-client-vpn-endpoints \
  --client-vpn-endpoint-ids cvpn-endpoint-0123456789abcdef0
```

Check:

``` text
Status
ClientCidrBlock
DnsName
SplitTunnel
SecurityGroups
TransportProtocol
VpnPort
```

------------------------------------------------------------------------

# 46. CLI Step 7: View Connections

``` bash
aws ec2 describe-client-vpn-connections \
  --client-vpn-endpoint-id cvpn-endpoint-0123456789abcdef0
```

This helps determine whether clients are connected.

------------------------------------------------------------------------

# 47. CLI Step 8: View Routes

``` bash
aws ec2 describe-client-vpn-routes \
  --client-vpn-endpoint-id cvpn-endpoint-0123456789abcdef0
```

Verify that the required destination exists.

------------------------------------------------------------------------

# 48. CLI Step 9: View Authorization Rules

``` bash
aws ec2 describe-client-vpn-authorization-rules \
  --client-vpn-endpoint-id cvpn-endpoint-0123456789abcdef0
```

Confirm that:

``` text
10.0.0.0/16
```

is authorized.

------------------------------------------------------------------------

# 49. Terraform Implementation

Terraform provides dedicated resources for Client VPN.

Important resources include:

  ------------------------------------------------------------------------------
  Terraform resource                         Purpose
  ------------------------------------------ -----------------------------------
  `aws_ec2_client_vpn_endpoint`              Creates Client VPN endpoint

  `aws_ec2_client_vpn_network_association`   Associates endpoint with subnet

  `aws_ec2_client_vpn_authorization_rule`    Creates authorization rule

  `aws_ec2_client_vpn_route`                 Creates additional Client VPN route
  ------------------------------------------------------------------------------

------------------------------------------------------------------------

# 50. Terraform Provider

Example:

``` hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.55"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-south-1"
}
```

Check the current AWS provider version before production deployment.

------------------------------------------------------------------------

# 51. Terraform Variables

``` hcl
variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "client_vpn_security_group_id" {
  type = string
}

variable "server_certificate_arn" {
  type = string
}

variable "client_root_certificate_chain_arn" {
  type = string
}
```

Example values:

``` text
vpc_id:
vpc-0123456789abcdef0

subnet_id:
subnet-0123456789abcdef0

client_vpn_security_group_id:
sg-0123456789abcdef0
```

------------------------------------------------------------------------

# 52. Terraform Client VPN Endpoint

``` hcl
resource "aws_ec2_client_vpn_endpoint" "main" {
  description            = "AWS Client VPN"
  client_cidr_block      = "10.250.0.0/22"
  server_certificate_arn = var.server_certificate_arn

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_root_certificate_chain_arn
  }

  split_tunnel = true

  transport_protocol = "udp"
  vpn_port            = 443

  security_group_ids = [
    var.client_vpn_security_group_id
  ]

  connection_log_options {
    enabled = false
  }

  tags = {
    Name = "client-vpn"
  }
}
```

The Terraform resource maps to the AWS Client VPN endpoint.

------------------------------------------------------------------------

# 53. Terraform Target Network Association

``` hcl
resource "aws_ec2_client_vpn_network_association" "private_subnet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  subnet_id              = var.subnet_id
}
```

For high availability, associate another subnet in another Availability
Zone:

``` hcl
resource "aws_ec2_client_vpn_network_association" "private_subnet_2" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  subnet_id              = var.subnet_id_2
}
```

------------------------------------------------------------------------

# 54. Terraform Authorization Rule

``` hcl
resource "aws_ec2_client_vpn_authorization_rule" "vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id

  target_network_cidr  = "10.0.0.0/16"
  authorize_all_groups = true

  description = "Allow clients to access VPC"
}
```

This grants access to the VPC CIDR.

For user/group-based authentication, use the appropriate
`access_group_id` configuration.

------------------------------------------------------------------------

# 55. Terraform Additional Route

For an additional network:

``` hcl
resource "aws_ec2_client_vpn_route" "peer_vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id

  destination_cidr_block = "10.20.0.0/16"

  target_vpc_subnet_id = aws_ec2_client_vpn_network_association.private_subnet.subnet_id

  description = "Route to peer VPC"
}
```

For Internet/full-tunnel:

``` hcl
resource "aws_ec2_client_vpn_route" "internet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id

  destination_cidr_block = "0.0.0.0/0"

  target_vpc_subnet_id = aws_ec2_client_vpn_network_association.private_subnet.subnet_id

  description = "Internet route"
}
```

Use the Internet route only when full-tunnel Internet access is
intentionally designed.

------------------------------------------------------------------------

# 56. Complete Terraform Example

``` hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.55"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-south-1"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "client_vpn_security_group_id" {
  type = string
}

variable "server_certificate_arn" {
  type = string
}

variable "client_root_certificate_chain_arn" {
  type = string
}

resource "aws_ec2_client_vpn_endpoint" "main" {
  description            = "AWS Client VPN"
  client_cidr_block      = "10.250.0.0/22"
  server_certificate_arn = var.server_certificate_arn

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_root_certificate_chain_arn
  }

  split_tunnel      = true
  transport_protocol = "udp"
  vpn_port           = 443

  security_group_ids = [
    var.client_vpn_security_group_id
  ]

  connection_log_options {
    enabled = false
  }

  tags = {
    Name = "client-vpn"
  }
}

resource "aws_ec2_client_vpn_network_association" "private_subnet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  subnet_id              = var.subnet_id
}

resource "aws_ec2_client_vpn_authorization_rule" "vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  target_network_cidr    = "10.0.0.0/16"
  authorize_all_groups   = true

  description = "Allow VPN clients to access VPC"
}

output "client_vpn_endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.main.id
}

output "client_vpn_dns_name" {
  value = aws_ec2_client_vpn_endpoint.main.dns_name
}
```

------------------------------------------------------------------------

# 57. Terraform Workflow

Initialize:

``` bash
terraform init
```

Validate:

``` bash
terraform validate
```

Format:

``` bash
terraform fmt
```

Review:

``` bash
terraform plan
```

Create:

``` bash
terraform apply
```

Confirm:

``` text
yes
```

Get endpoint ID:

``` bash
terraform output client_vpn_endpoint_id
```

Get DNS name:

``` bash
terraform output client_vpn_dns_name
```

------------------------------------------------------------------------

# 58. Important Terraform Security Consideration

Do not place private client keys directly into Terraform source code.

Avoid:

``` hcl
client_private_key = "-----BEGIN PRIVATE KEY-----..."
```

Private keys should be managed through a secure certificate/key
management process.

Terraform state may contain sensitive resource information depending on
configuration.

Use:

-   Encrypted remote state
-   Restricted state access
-   Appropriate IAM permissions
-   Secure CI/CD secret handling
-   No private keys in Git repositories

------------------------------------------------------------------------

# 59. Certificate Management

For a production architecture, consider how certificates are issued and
revoked.

Possible architecture:

``` text
AWS Private CA
       |
       +---- Server Certificate
       |
       +---- Client Certificate
       |
       v
     ACM
       |
       v
Client VPN
```

For a simple lab, certificates can be generated using Easy-RSA and
imported into ACM.

For enterprise environments, integrate certificate issuance and
lifecycle management with an appropriate PKI strategy.

------------------------------------------------------------------------

# 60. Client VPN Routing Model

A common mistake is to think:

``` text
VPN connected = access to everything
```

That is incorrect.

Access depends on multiple controls.

``` text
VPN Authentication
        |
        v
VPN Session
        |
        v
Authorization Rule
        |
        v
Client VPN Route
        |
        v
VPC Route
        |
        v
Security Group
        |
        v
Network ACL / OS Firewall
        |
        v
Application
```

Every relevant layer must permit the traffic.

------------------------------------------------------------------------

# 61. Example: Access Private EC2

Suppose:

``` text
VPC:
10.0.0.0/16

Private subnet:
10.0.1.0/24

EC2:
10.0.1.50

Client:
10.250.0.10
```

Required configuration:

### Client VPN

``` text
Client CIDR:
10.250.0.0/22
```

### Authorization

``` text
10.0.0.0/16 -> Allow
```

### Client VPN Route

``` text
10.0.0.0/16 -> Target subnet
```

### EC2 Security Group

``` text
TCP 22
Source:
Client VPN security group
```

### Laptop

``` text
AWS VPN Client -> Connected
```

Then:

``` bash
ssh ec2-user@10.0.1.50
```

------------------------------------------------------------------------

# 62. Accessing a Private RDS Database

Suppose:

``` text
RDS:
10.0.3.20

Port:
5432
```

Configure:

``` text
Client VPN authorization:
10.0.0.0/16

Client VPN route:
10.0.0.0/16

RDS security group:
TCP 5432
Source: Client VPN security group
```

From the laptop:

``` bash
psql -h <private-rds-dns-name> -p 5432 -U dbuser
```

The RDS instance does not need a public endpoint for this architecture.

------------------------------------------------------------------------

# 63. Accessing a Peered VPC

Suppose:

``` text
VPC A:
10.0.0.0/16

VPC B:
10.20.0.0/16
```

VPC peering exists.

Client VPN is associated with VPC A.

To reach VPC B, configure:

1.  Client VPN route:

``` text
10.20.0.0/16
```

2.  Client VPN authorization rule:

``` text
10.20.0.0/16
```

3.  VPC A route table:

``` text
10.20.0.0/16 -> VPC Peering
```

4.  VPC B route table:

``` text
10.250.0.0/22 -> VPC Peering
```

5.  Security groups/NACLs must permit the traffic.

------------------------------------------------------------------------

# 64. Client VPN with Transit Gateway

Client VPN can also integrate with Transit Gateway.

Architecture:

``` text
Laptop
   |
Client VPN
   |
Transit Gateway
   |
   +---- VPC A
   |
   +---- VPC B
   |
   +---- VPC C
   |
   +---- On-Premises
```

This is useful when many VPCs must be reachable through a centralized
network architecture.

The endpoint can be configured with Transit Gateway integration instead
of only associating VPC subnets.

For SAA-C03, understand the design difference:

``` text
Client VPN -> VPC subnet
```

versus:

``` text
Client VPN -> Transit Gateway -> Multiple networks
```

------------------------------------------------------------------------

# 65. High Availability

A Client VPN endpoint can be associated with multiple target subnets.

Example:

``` text
             Client VPN
                 |
        +--------+--------+
        |                 |
        v                 v
      AZ-a              AZ-b
   Subnet A           Subnet B
        |                 |
       EC2               EC2
```

Multiple subnet associations improve availability.

AWS recommends using target networks in different Availability Zones for
higher resilience.

------------------------------------------------------------------------

# 66. Connection Logging

Client VPN supports connection logging.

Logs can be sent to Amazon CloudWatch Logs.

Architecture:

``` text
Client VPN
     |
     v
Connection Logs
     |
     v
CloudWatch Logs
```

Logging is useful for:

-   Connection troubleshooting
-   Authentication investigation
-   Operational monitoring
-   Security analysis
-   Audit requirements

Enable connection logging when the operational requirement justifies it.

------------------------------------------------------------------------

# 67. DNS Resolution

Private AWS applications frequently depend on DNS.

Example:

``` text
db.internal.example.com
```

If the laptop cannot resolve the private hostname, the VPN may be
connected while the application still fails.

Check:

``` powershell
nslookup db.internal.example.com
```

Confirm that the Client VPN DNS configuration can reach the required
resolver.

------------------------------------------------------------------------

# 68. Troubleshooting

## Problem 1: Endpoint is not available

Check:

``` text
Target network association
```

The endpoint must have an associated target network.

------------------------------------------------------------------------

## Problem 2: VPN connects but EC2 cannot be reached

Check:

1.  Client VPN authorization rule
2.  Client VPN route
3.  Target subnet
4.  EC2 security group
5.  Network ACL
6.  EC2 operating system firewall
7.  Application listening port
8.  Route-table configuration

------------------------------------------------------------------------

## Problem 3: Authentication fails

For mutual authentication, verify:

``` text
Server certificate
Client certificate
Private key
Certificate chain
Certificate CN
Certificate validity
ACM Region
.ovpn configuration
```

For AD/SAML, verify the identity provider configuration and user/group
authorization.

------------------------------------------------------------------------

## Problem 4: Route exists but application does not work

Example:

``` text
10.0.0.0/16
```

exists in the Client VPN route table.

But:

``` text
TCP 22
```

is blocked by the EC2 security group.

The route alone does not grant access.

------------------------------------------------------------------------

## Problem 5: Internet stops working

This often occurs when full-tunnel routing is configured.

Check:

``` text
Client VPN route:
0.0.0.0/0
```

Then verify the target subnet's VPC route table and Internet/NAT
architecture.

If only AWS private access is required, split tunnel is usually simpler.

------------------------------------------------------------------------

## Problem 6: DNS names do not resolve

Check:

``` text
Client VPN DNS servers
VPC DNS support
VPC DNS hostnames
Private hosted zones
Route 53 Resolver
```

Test:

``` powershell
nslookup <private-dns-name>
```

------------------------------------------------------------------------

# 69. Common Design Mistakes

  Mistake                                      Result
  -------------------------------------------- -------------------------------------------
  Client CIDR overlaps VPC                     Routing/connectivity problems
  No target network association                Clients cannot access VPC
  No authorization rule                        VPN connects but network access is denied
  No Client VPN route for additional network   Destination unreachable
  EC2 SG blocks traffic                        Connection fails
  Private key exposed                          Security risk
  0.0.0.0/0 added unnecessarily                All Internet traffic enters VPN
  Only one AZ used                             Lower resilience
  No DNS configuration                         Private hostnames fail
  Testing only with ping                       False diagnosis if ICMP is blocked
  Publicly exposing private services           Unnecessary attack surface

------------------------------------------------------------------------

# 70. Security Best Practices

1.  Use a dedicated Client VPN security group.
2.  Avoid overlapping CIDR ranges.
3.  Use group-based authorization for enterprise access.
4.  Prefer SAML or Active Directory when centralized user identity is
    required.
5.  Use unique client certificates when using mutual authentication.
6.  Protect private keys.
7.  Never store private keys in Git.
8.  Enable connection logging where required.
9.  Use split tunnel when only private AWS access is required.
10. Use full tunnel only when centralized traffic inspection or Internet
    routing is required.
11. Associate multiple subnets in different Availability Zones for
    resilience.
12. Restrict security-group ports to required applications.
13. Do not expose private resources publicly just to make remote access
    easier.
14. Use CloudWatch logging and monitoring where operationally
    appropriate.
15. Review authorization rules regularly.

------------------------------------------------------------------------

# 71. Important SAA-C03 Concepts

For the Solutions Architect Associate exam, remember the following
relationships.

## Client VPN

``` text
Individual users/devices
        |
        v
AWS Client VPN
        |
        v
Private AWS resources
```

## Site-to-Site VPN

``` text
On-premises network
        |
        v
Customer Gateway
        |
     IPsec VPN
        |
        v
AWS VPC / TGW
```

## Direct Connect

``` text
Customer network
        |
Dedicated connection
        |
        v
AWS
```

------------------------------------------------------------------------

# 72. SAA-C03 Comparison Table

  -----------------------------------------------------------------------
  Requirement                         Appropriate service/design
  ----------------------------------- -----------------------------------
  Employee laptop needs private EC2   Client VPN
  access                              

  Developer needs private RDS access  Client VPN

  Branch office connects to VPC       Site-to-Site VPN

  Many VPCs need centralized routing  Transit Gateway

  Dedicated private network           Direct Connect
  connection                          

  Global private application access   Evaluate Cloud WAN/TGW/other
                                      architecture

  User-based SSO for VPN              Client VPN + SAML

  Certificate-based device VPN access Client VPN + mutual authentication

  Connect multiple VPCs through       Client VPN + Transit Gateway
  central hub                         

  Only private AWS traffic should use Split tunnel
  VPN                                 

  All client traffic should traverse  Full tunnel
  AWS                                 
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 73. SAA-C03 Scenario Questions

## Scenario 1

A company wants employees to access private EC2 instances from home
laptops without exposing the instances to the Internet.

Recommended architecture:

``` text
Employee laptop
       |
Client VPN
       |
Private VPC
       |
Private EC2
```

------------------------------------------------------------------------

## Scenario 2

A company wants employees to authenticate using corporate SSO.

Relevant Client VPN authentication option:

``` text
SAML-based federated authentication
```

------------------------------------------------------------------------

## Scenario 3

A company wants certificate-based authentication for managed devices.

Relevant option:

``` text
Mutual authentication
```

------------------------------------------------------------------------

## Scenario 4

Only AWS private resources should use the VPN. Normal Internet traffic
should remain local.

Relevant configuration:

``` text
Split tunnel
```

------------------------------------------------------------------------

## Scenario 5

All employee Internet traffic must traverse AWS for centralized
inspection.

Relevant Client VPN design:

``` text
Full tunnel
+
0.0.0.0/0 route
+
appropriate VPC Internet/NAT/security architecture
```

------------------------------------------------------------------------

## Scenario 6

Employees must access several VPCs connected through a central routing
hub.

Relevant architecture:

``` text
Client VPN
     |
Transit Gateway
     |
Multiple VPCs
```

------------------------------------------------------------------------

# 74. Console vs CLI vs Terraform

  -------------------------------------------------------------------------------
  Capability        Management Console     AWS CLI              Terraform
  ----------------- ---------------------- -------------------- -----------------
  Create endpoint   Yes                    Yes                  Yes

  Configure         Yes                    Yes                  Yes
  authentication                                                

  Associate subnet  Yes                    Yes                  Yes

  Authorization     Yes                    Yes                  Yes
  rule                                                          

  Route             Yes                    Yes                  Yes

  Export            Yes                    Yes                  Yes
  configuration                                                 

  Repeatable        Limited                Scriptable           Excellent
  deployment                                                    

  Version           No                     Scripts              Yes
  controlled                                                    

  Infrastructure    Limited                Limited              Strong
  drift control                                                 

  Best use          Learning/interactive   Automation/scripts   Infrastructure as
                    operations                                  code
  -------------------------------------------------------------------------------

------------------------------------------------------------------------

# 75. Operational Verification Checklist

After implementation, verify:

``` text
[ ] VPC exists
[ ] Target subnet exists
[ ] Client CIDR does not overlap
[ ] Server certificate exists in ACM
[ ] Client certificate exists/CA is configured
[ ] Client VPN endpoint is available
[ ] Target network association is available
[ ] Authorization rule exists
[ ] Required route exists
[ ] Client VPN security group is correct
[ ] EC2 security group allows required traffic
[ ] DNS configuration is correct
[ ] .ovpn configuration is current
[ ] Laptop VPN client is installed
[ ] Laptop receives VPN IP
[ ] VPC route appears on laptop
[ ] Private application port is reachable
```

------------------------------------------------------------------------

# 76. Cleanup

If the environment was created for testing, remove resources after
validation.

Terraform:

``` bash
terraform destroy
```

Console:

``` text
Client VPN endpoint
    -> Delete
```

Also remove:

-   Target network associations
-   Authorization rules if no longer required
-   Additional routes
-   Imported test certificates if appropriate
-   Test EC2 resources
-   Test security groups
-   Test VPC resources

Be careful not to delete shared production resources.

------------------------------------------------------------------------

# 77. Official AWS Documentation

## AWS Client VPN Documentation

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/what-is.html

## AWS Client VPN Administrator Guide

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/

## How AWS Client VPN Works

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/how-it-works.html

## Get Started with AWS Client VPN

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-getting-started.html

## Create Client VPN Endpoint

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-working-endpoint-create.html

## Client Authentication

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/client-authentication.html

## Mutual Authentication

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/mutual.html

## Enable Mutual Authentication

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/client-auth-mutual-enable.html

## Client Authorization

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/client-authorization.html

## Authorization Rules

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-working-rules.html

## Client VPN Routes

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-working-routes-create.html

## Export Client Configuration

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/export-client-config-file.html

## Client VPN Endpoint Configuration

https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-working-endpoint-export.html

## AWS Client VPN User Guide

https://docs.aws.amazon.com/vpn/latest/clientvpn-user/

## AWS Provided Client

https://docs.aws.amazon.com/vpn/latest/clientvpn-user/connect-aws-client-vpn-connect.html

## Windows Client

https://docs.aws.amazon.com/vpn/latest/clientvpn-user/client-vpn-connect-windows.html

## AWS CLI: create-client-vpn-endpoint

https://docs.aws.amazon.com/cli/latest/reference/ec2/create-client-vpn-endpoint.html

## AWS CLI: create-client-vpn-route

https://docs.aws.amazon.com/cli/latest/reference/ec2/create-client-vpn-route.html

## AWS CLI: export-client-vpn-client-configuration

https://docs.aws.amazon.com/cli/latest/reference/ec2/export-client-vpn-client-configuration.html

------------------------------------------------------------------------

# 78. Terraform Documentation

## Client VPN Endpoint

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_endpoint

## Client VPN Network Association

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_network_association

## Client VPN Authorization Rule

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_authorization_rule

## Client VPN Route

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_route

------------------------------------------------------------------------

# 79. Final Architecture Summary

The complete private-access model is:

``` text
                    Remote User
                        |
                        v
                 +-------------+
                 | Laptop      |
                 | VPN Client  |
                 +------+------+
                        |
                  Encrypted VPN
                        |
                        v
              +-------------------+
              | AWS Client VPN    |
              | Endpoint          |
              +---------+---------+
                        |
            +-----------+-----------+
            |                       |
      Authentication         Authorization
            |                       |
            +-----------+-----------+
                        |
                     Routes
                        |
                        v
                Target Network
                        |
                        v
                     VPC
                        |
              +---------+---------+
              |                   |
             EC2                 RDS
          Private IP          Private IP
```

The key SAA-C03 mental model is:

``` text
Client VPN
   =
Remote individual device access
        +
Authentication
        +
Authorization rules
        +
Client VPN routes
        +
VPC routing
        +
Security groups
```

A VPN connection being established is only the first step. Successful
application connectivity requires the authentication, authorization,
routing, security-group, DNS, and application layers to be correctly
configured.
