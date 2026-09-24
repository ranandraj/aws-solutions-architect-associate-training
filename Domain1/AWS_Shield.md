# AWS Shield

## Professional AWS Solutions Architect Associate (SAA-C03) Documentation

**Scope:** AWS Shield Standard and Shield Advanced, DDoS protection,
Layers 3/4/7, protected resources, AWS WAF integration,
application-layer automatic mitigation, health-based detection, Shield
Response Team, proactive engagement, Management Console, AWS CLI,
Terraform, laptop testing, troubleshooting, comparisons, SAA-C03 exam
points, and official AWS documentation.

> **Important:** AWS Shield does not create a VPN connection from a
> laptop into a VPC. For private laptop-to-VPC network access use AWS
> Client VPN. In this document the laptop is an Internet client testing
> a public application protected by Shield Advanced.

------------------------------------------------------------------------

# 1. What Is AWS Shield?

AWS Shield is a managed DDoS protection service. AWS Shield Standard and
Shield Advanced provide protection at network and transport layers
(Layers 3 and 4) and application layer (Layer 7). Shield Standard is
automatically included with AWS at no additional charge. Shield Advanced
is a paid subscription with expanded protection, visibility, response,
and application-layer capabilities. [AWS Shield
documentation](https://docs.aws.amazon.com/shield/)

``` text
Internet
   |
   v
CloudFront / ALB / Route 53 / Global Accelerator / EIP
   |
 AWS Shield
   |
   v
Application
```

------------------------------------------------------------------------

# 2. Shield Standard

Shield Standard automatically protects AWS applications against common
DDoS attacks, especially common network and transport-layer attacks such
as TCP SYN floods and UDP reflection attacks. AWS notes particular
benefit for Route 53 hosted zones, CloudFront distributions, and Global
Accelerator standard accelerators. [Shield
Standard](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-standard-summary.html)

There is no separate resource-level Shield Standard protection object to
create for ordinary use.

------------------------------------------------------------------------

# 3. Shield Advanced

Shield Advanced provides expanded DDoS protection for supported
resources and additional operational features including:

-   Advanced DDoS event visibility
-   Application-layer protection through AWS WAF
-   Automatic application-layer DDoS mitigation
-   Health-based detection
-   Shield Response Team support
-   Proactive engagement
-   DDoS cost protection, subject to AWS terms
-   AWS Firewall Manager integration

Shield Advanced requires a subscription. AWS recommends configuring
protection before an attack occurs. [Setting up Shield
Advanced](https://docs.aws.amazon.com/waf/latest/developerguide/getting-started-ddos.html)

------------------------------------------------------------------------

# 4. Shield Standard vs Shield Advanced

  Feature                                   Shield Standard           Shield Advanced
  ----------------------------------------- ------------------------- -----------------------
  Automatic DDoS protection                 Yes                       Yes
  Extra subscription                        No                        Yes
  Network/transport DDoS                    Yes                       Yes
  Advanced event visibility                 No                        Yes
  Automatic application-layer mitigation    No                        Yes
  Health-based detection                    Limited by architecture   Yes
  Shield Response Team                      No                        Yes
  Proactive engagement                      No                        Yes
  DDoS cost protection                      No                        Yes, subject to terms
  Resource-specific Advanced protection     No                        Yes
  Firewall Manager Shield Advanced policy   No                        Yes

AWS documents the distinction between the two protection levels. [How
Shield and Shield Advanced
work](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-overview.html)

------------------------------------------------------------------------

# 5. Protected Resources

Shield Advanced can protect:

-   CloudFront distributions
-   Route 53 hosted zones
-   AWS Global Accelerator standard accelerators
-   EC2 Elastic IP addresses
-   EC2 instances through protected Elastic IPs
-   Application Load Balancers
-   Classic Load Balancers
-   Network Load Balancers through protected Elastic IPs

Shield Advanced protects only resources explicitly added to Shield
Advanced or covered by a Firewall Manager Shield Advanced policy.
[Protected
resources](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-protections-by-resource-type.html)

  Resource                                  Shield Advanced
  ----------------------------------------- -------------------------------------------------
  CloudFront                                Direct
  Route 53 hosted zone                      Direct
  Global Accelerator standard accelerator   Direct
  EC2 Elastic IP                            Direct
  EC2 instance                              Through protected EIP
  Application Load Balancer                 Direct
  Classic Load Balancer                     Direct
  Network Load Balancer                     Through protected EIP
  NAT Gateway                               Not a Shield inbound protection target
  RDS                                       Not a direct Shield Advanced protected resource

------------------------------------------------------------------------

# 6. Shield and AWS WAF

Shield and WAF solve different problems.

``` text
Internet
   |
   v
CloudFront / ALB
   |
   +---- Shield Advanced --> DDoS protection
   |
   +---- AWS WAF ---------> HTTP/HTTPS filtering
   |
   v
Application
```

AWS documents Shield Advanced + WAF as the application-layer DDoS
protection model. A protected application-layer resource uses a WAF Web
ACL, including a rate-based rule, and Shield Advanced can automatically
manage mitigation rules when automatic application-layer DDoS mitigation
is enabled. [Shield +
WAF](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-app-layer-protections.html)

  -----------------------------------------------------------------------
  Feature                 Shield                  WAF
  ----------------------- ----------------------- -----------------------
  DDoS protection         Primary purpose         Defensive application
                                                  layer control

  Layer 3/4 DDoS          Yes                     No

  HTTP request filtering  No                      Yes

  SQL injection           No                      Yes

  XSS                     No                      Yes

  Rate-based web rules    Advanced integrates     Yes
                          with WAF                

  Web ACL                 Uses WAF                Core object

  SRT                     Advanced                No
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 7. Shield vs Other AWS Security Services

  Service                Main purpose
  ---------------------- ----------------------------------------
  AWS Shield             DDoS protection
  AWS WAF                HTTP/HTTPS web request filtering
  Security Group         Stateful network access control
  Network ACL            Stateless subnet traffic filtering
  AWS Network Firewall   VPC/network traffic inspection
  AWS Firewall Manager   Centralized security policy management
  Client VPN             Remote user VPN connectivity
  Site-to-Site VPN       Network-to-network VPN
  Direct Connect         Dedicated network connectivity

------------------------------------------------------------------------

# 8. DDoS Protection Layers

## Layer 3: Network

Examples include network-level volumetric attacks and protocol abuse.

## Layer 4: Transport

Examples include TCP SYN floods and UDP floods.

## Layer 7: Application

Examples include HTTP request floods and application request-rate
anomalies.

Shield Advanced can combine with AWS WAF for Layer 7 protections.
[Shield
overview](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-overview.html)

------------------------------------------------------------------------

# 9. Shield Advanced Application-Layer Mitigation

Shield Advanced can learn normal traffic patterns over time. When an
anomaly indicates a possible application-layer DDoS event, automatic
mitigation can use AWS WAF rules.

``` text
Normal application traffic
          |
          v
     Traffic baseline
          |
          v
      Anomaly detected
          |
          v
   Shield Advanced event
          |
          v
 Automatic WAF mitigation
```

AWS documents this baseline and automatic mitigation model.
[Application-layer
protection](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-app-layer-protections.html)

------------------------------------------------------------------------

# 10. Health-Based Detection

Shield Advanced can use application health information to improve
detection. A typical architecture is:

``` text
Application
    |
Route 53 health check
    |
    v
Shield Advanced
```

Use health checks that represent real application availability. AWS
includes health-based detection in its Shield Advanced setup guidance.
[Getting
started](https://docs.aws.amazon.com/waf/latest/developerguide/getting-started-ddos.html)

------------------------------------------------------------------------

# 11. Shield Response Team and Proactive Engagement

Shield Advanced includes access to the AWS Shield Response Team for
appropriate DDoS incidents. Proactive engagement can allow AWS to
contact configured emergency contacts when escalation is appropriate.

Keep emergency contacts, phone numbers, and incident procedures current.
AWS documents DRT/SRT role association and proactive engagement as part
of Shield Advanced operations. [AWS CLI Shield
examples](https://docs.aws.amazon.com/cli/latest/userguide/cli_shield_code_examples.html)

------------------------------------------------------------------------

# 12. DDoS Cost Protection

Shield Advanced includes DDoS cost protection for eligible scenarios,
subject to current AWS terms and conditions. Review the current pricing
and eligibility before designing around this feature.

AWS Shield pricing: https://aws.amazon.com/shield/pricing/

------------------------------------------------------------------------

# 13. Management Console Lab Architecture

The laptop is an Internet client, not a VPN endpoint.

``` text
                     Internet
                        |
                        v
                 Laptop / Browser
                        |
                      HTTPS
                        |
                        v
                +---------------+
                | Internet ALB  |
                +-------+-------+
                        |
              +---------+---------+
              |                   |
       Shield Advanced         AWS WAF
              |                   |
              +---------+---------+
                        |
                        v
                 Private EC2
                        |
                 Web application
```

For an actual private laptop-to-VPC connection, use Client VPN instead.

------------------------------------------------------------------------

# 14. Lab Network

  Resource           Example
  ------------------ ---------------------
  Region             ap-south-1
  VPC                10.0.0.0/16
  Public subnet A    10.0.1.0/24
  Public subnet B    10.0.2.0/24
  Private subnet A   10.0.11.0/24
  Private subnet B   10.0.12.0/24
  Application        EC2 web server
  Entry point        Internet-facing ALB
  Shield             Advanced
  WAF                Regional Web ACL

------------------------------------------------------------------------

# 15. Console Prerequisites

Prepare:

1.  AWS account
2.  VPC
3.  Two public subnets in different Availability Zones
4.  Private subnet for EC2
5.  Internet Gateway
6.  EC2 instance
7.  EC2 security group
8.  ALB security group
9.  Target group
10. Application Load Balancer
11. Application running on EC2
12. AWS WAF permissions
13. Shield Advanced subscription if Advanced features are required

------------------------------------------------------------------------

# 16. Console Step 1: Create or Select VPC

Open:

https://console.aws.amazon.com/vpc/

Example:

``` text
VPC: 10.0.0.0/16
```

Use two public subnets in different Availability Zones for the ALB and
private subnets for the application.

------------------------------------------------------------------------

# 17. Console Step 2: Create EC2 Security Group

Create:

``` text
sg-web-ec2
```

Allow:

``` text
HTTP TCP 80
Source: ALB security group
```

Do not expose the private application directly to the Internet when the
ALB is the intended entry point.

------------------------------------------------------------------------

# 18. Console Step 3: Launch EC2

Launch EC2 into a private subnet.

Example:

``` text
Private IP: 10.0.11.10
```

Install Apache on Amazon Linux:

``` bash
sudo dnf install -y httpd
sudo systemctl enable --now httpd
echo "AWS Shield Test Application" | sudo tee /var/www/html/index.html
```

Verify:

``` bash
curl http://localhost
```

------------------------------------------------------------------------

# 19. Console Step 4: Create Target Group

Go to:

``` text
EC2 -> Target Groups -> Create target group
```

Use:

``` text
Target type: Instances
Protocol: HTTP
Port: 80
```

Register the EC2 instance and use an HTTP `/` health check.

Verify the target becomes:

``` text
Healthy
```

------------------------------------------------------------------------

# 20. Console Step 5: Create Application Load Balancer

Go to:

``` text
EC2 -> Load Balancers -> Create Load Balancer
```

Select:

``` text
Application Load Balancer
Scheme: Internet-facing
```

Select two public subnets in different Availability Zones.

Create an HTTP listener on port 80 and forward to the target group.

For production, use HTTPS with an ACM certificate.

------------------------------------------------------------------------

# 21. Console Step 6: Test Before Shield

From the laptop:

``` text
http://<ALB-DNS-NAME>
```

Expected:

``` text
AWS Shield Test Application
```

At this point the path is:

``` text
Laptop -> ALB -> EC2
```

------------------------------------------------------------------------

# 22. Console Step 7: Open AWS WAF & Shield

Open:

https://console.aws.amazon.com/wafv2/

The current AWS setup documentation uses the AWS WAF & Shield console
for Shield Advanced configuration. [AWS setup
guide](https://docs.aws.amazon.com/waf/latest/developerguide/getting-started-ddos.html)

------------------------------------------------------------------------

# 23. Console Step 8: Subscribe to Shield Advanced

In the Shield section choose the Shield Advanced subscription option.

Review:

-   Current price
-   Subscription commitment
-   Auto-renewal
-   Resource protection charges
-   Current AWS terms

Shield Advanced is not a free disposable lab service. AWS documents the
subscription requirement. [Shield Advanced
setup](https://docs.aws.amazon.com/waf/latest/developerguide/getting-started-ddos.html)

------------------------------------------------------------------------

# 24. Console Step 9: Add the ALB to Protected Resources

Go to:

``` text
Shield Advanced
 -> Protected resources
 -> Add resources to protect
```

Select:

``` text
Application Load Balancer
```

Select the ALB and create the protection.

AWS supports direct Shield Advanced protection for Application Load
Balancers. [Protected
resources](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-protections-by-resource-type.html)

------------------------------------------------------------------------

# 25. Console Step 10: Verify Protection

Open:

``` text
Shield Advanced
 -> Protected resources
```

Verify:

``` text
Resource: your ALB
Protection: active
```

Adding one resource does not automatically protect unrelated resources.

------------------------------------------------------------------------

# 26. Console Step 11: Configure WAF Application-Layer Protection

Create or select a regional Web ACL for the ALB.

Recommended conceptual design:

``` text
Shield Advanced
       |
       v
AWS WAF Web ACL
       |
       +-- Rate-based rule
       +-- Managed rules
       +-- Application-specific rules
```

AWS documents WAF Web ACL integration as part of Shield Advanced
application-layer protection. [Shield +
WAF](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-app-layer-web-ACL-and-rbr.html)

------------------------------------------------------------------------

# 27. Console Step 12: Configure a Rate-Based Rule

Create a WAF rate-based rule.

Example design:

``` text
Rule: RateLimit-Web
Aggregate key: IP address
Action: BLOCK
```

Use a threshold based on normal traffic. Do not copy a test threshold
into production without analyzing application traffic.

------------------------------------------------------------------------

# 28. Console Step 13: Enable Automatic Application-Layer Mitigation

In the Shield Advanced protection settings, configure automatic
application-layer DDoS mitigation where appropriate.

Shield Advanced can automatically create/manage WAF rules in response to
application-layer DDoS events. [Application-layer
mitigation](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-app-layer-protections.html)

Review the WAF rule interactions before enabling enforcement.

------------------------------------------------------------------------

# 29. Console Step 14: Configure Health-Based Detection

Create an appropriate Route 53 health check and associate it with the
Shield protection where required.

The objective is to provide Shield with application health information
that represents actual service availability.

------------------------------------------------------------------------

# 30. Console Step 15: Configure Notifications

A useful monitoring architecture is:

``` text
Shield Event
    |
CloudWatch
    |
SNS
    |
Email / Incident System
```

Also monitor:

-   ALB health
-   Application metrics
-   WAF blocked/count requests
-   CloudFront/Route 53/Global Accelerator metrics where applicable

------------------------------------------------------------------------

# 31. Console Step 16: Configure Proactive Engagement

For critical applications configure emergency contacts.

Provide:

``` text
Contact name
Email
Phone
Notes
```

Keep the contact information current.

------------------------------------------------------------------------

# 32. Console Step 17: Configure SRT/DRT Access

If SRT assistance is required, configure the IAM role and access
according to current Shield Advanced documentation.

AWS CLI supports:

``` bash
aws shield associate-drt-role --role-arn <ROLE-ARN>
```

[AWS Shield CLI
examples](https://docs.aws.amazon.com/cli/latest/userguide/cli_shield_code_examples.html)

------------------------------------------------------------------------

# 33. Console Step 18: Verify Normal Laptop Traffic

From Windows PowerShell:

``` powershell
curl.exe -i http://<ALB-DNS-NAME>/
```

Expected:

``` text
HTTP/1.1 200 OK
```

Do not generate a real DDoS attack to test Shield. Validate
configuration, monitoring, health checks, and normal application traffic
instead.

------------------------------------------------------------------------

# 34. AWS CLI Prerequisites

Configure credentials:

``` bash
aws configure
```

Set the region:

``` bash
export AWS_DEFAULT_REGION=ap-south-1
```

PowerShell:

``` powershell
$env:AWS_DEFAULT_REGION="ap-south-1"
```

------------------------------------------------------------------------

# 35. CLI: Check Shield Advanced Subscription

``` bash
aws shield describe-subscription
```

Shield Advanced must be subscribed to before using its Advanced
protection features.

------------------------------------------------------------------------

# 36. CLI: Subscribe to Shield Advanced

AWS CLI provides:

``` bash
aws shield create-subscription
```

This is a billing/subscription operation. Do not execute it in a
temporary environment without reviewing the current Shield Advanced
subscription commitment and pricing.

[AWS CLI Shield
examples](https://docs.aws.amazon.com/cli/latest/userguide/cli_shield_code_examples.html)

------------------------------------------------------------------------

# 37. CLI: Find ALB ARN

``` bash
aws elbv2 describe-load-balancers \
  --names my-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text
```

Example:

``` text
arn:aws:elasticloadbalancing:ap-south-1:123456789012:loadbalancer/app/my-alb/1234567890abcdef
```

------------------------------------------------------------------------

# 38. CLI: Create Shield Advanced Protection

``` bash
aws shield create-protection \
  --name "production-alb-shield" \
  --resource-arn "arn:aws:elasticloadbalancing:ap-south-1:123456789012:loadbalancer/app/my-alb/1234567890abcdef"
```

The command returns a ProtectionId.

AWS documents `create-protection` for supported resources including
Application Load Balancers, CloudFront distributions, Route 53 hosted
zones, Global Accelerator standard accelerators, Elastic IP addresses,
and Classic Load Balancers. [CLI
create-protection](https://docs.aws.amazon.com/cli/latest/reference/shield/create-protection.html)

------------------------------------------------------------------------

# 39. CLI: List Protections

``` bash
aws shield list-protections
```

------------------------------------------------------------------------

# 40. CLI: Describe Protection

``` bash
aws shield describe-protection \
  --protection-id <PROTECTION-ID>
```

Verify the resource ARN and protection ID.

------------------------------------------------------------------------

# 41. CLI: Delete a Protection

``` bash
aws shield delete-protection \
  --protection-id <PROTECTION-ID>
```

This removes the resource protection object. It does not mean that a
Shield Advanced subscription is immediately cancelled.

------------------------------------------------------------------------

# 42. CLI: Associate DRT Role

``` bash
aws shield associate-drt-role \
  --role-arn arn:aws:iam::123456789012:role/service-role/DrtRole
```

This associates the appropriate response role with Shield.

------------------------------------------------------------------------

# 43. CLI: Protection Groups

List:

``` bash
aws shield list-protection-groups
```

Describe:

``` bash
aws shield describe-protection-group \
  --protection-group-id <GROUP-ID>
```

Protection groups can aggregate protected resources for detection,
mitigation, and reporting. AWS documents Sum, Mean, and Max aggregation
options. [Protection
groups](https://docs.aws.amazon.com/waf/latest/developerguide/protection-group-creating.html)

------------------------------------------------------------------------

# 44. Terraform Resources

Current HashiCorp AWS provider documentation includes:

  ---------------------------------------------------------------------------------------
  Resource                                            Purpose
  --------------------------------------------------- -----------------------------------
  `aws_shield_subscription`                           Shield Advanced subscription

  `aws_shield_protection`                             Resource protection

  `aws_shield_protection_group`                       Protection grouping

  `aws_shield_protection_health_check_association`    Health check association

  `aws_shield_proactive_engagement`                   Proactive engagement

  `aws_shield_drt_access_role_arn_association`        Response role association

  `aws_shield_application_layer_automatic_response`   Automatic application-layer
                                                      response
  ---------------------------------------------------------------------------------------

Terraform Registry:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_protection

------------------------------------------------------------------------

# 45. Terraform Provider

Example:

``` hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.53"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-south-1"
}
```

Check the current provider release before production use.

------------------------------------------------------------------------

# 46. Terraform Shield Advanced Subscription

``` hcl
resource "aws_shield_subscription" "advanced" {
  auto_renew = "ENABLED"
}
```

**Important:** Shield Advanced is a subscription with a one-year
commitment and monthly fee according to the current Terraform Registry
documentation. Destroying this Terraform resource changes auto-renewal
behavior; it is not equivalent to deleting an ordinary temporary AWS
resource. [Terraform Shield
subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_subscription)

------------------------------------------------------------------------

# 47. Terraform Shield Protection for ALB

If the ALB already exists in Terraform:

``` hcl
resource "aws_shield_protection" "alb" {
  name         = "production-alb-shield"
  resource_arn = aws_lb.web.arn

  tags = {
    Environment = "production"
  }
}
```

The current provider supports Shield protection for Application Load
Balancers and other supported resources. [Terraform Shield
protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_protection)

------------------------------------------------------------------------

# 48. Terraform Protection for an Elastic IP

``` hcl
resource "aws_shield_protection" "eip" {
  name         = "ec2-eip-shield"
  resource_arn = aws_eip.web.arn
}
```

EC2 instances and NLBs can be protected through associated Elastic IP
addresses. [EC2/NLB Shield
protection](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-protections-ec2-nlb.html)

------------------------------------------------------------------------

# 49. Terraform Proactive Engagement

Example structure:

``` hcl
resource "aws_shield_proactive_engagement" "main" {
  enabled = true

  emergency_contact {
    contact_notes = "Primary production contact"
    email_address = "security@example.com"
    phone_number  = "+91XXXXXXXXXX"
  }
}
```

Do not store real emergency contact information in public repositories.

Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_proactive_engagement

------------------------------------------------------------------------

# 50. Terraform Automatic Application-Layer Response

The current provider supports an automatic application-layer response
resource for supported CloudFront distributions and ALBs:

``` hcl
resource "aws_shield_application_layer_automatic_response" "alb" {
  resource_arn = aws_lb.web.arn
  action       = "COUNT"
}
```

The documented actions are `COUNT` and `BLOCK`. Carefully test
application behavior before using `BLOCK`. [Terraform automatic
response](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_application_layer_automatic_response)

------------------------------------------------------------------------

# 51. Terraform Health Check Association

Conceptual configuration:

``` hcl
resource "aws_shield_protection_health_check_association" "web" {
  protection_id    = aws_shield_protection.alb.id
  health_check_arn = aws_route53_health_check.web.arn
}
```

Check the current provider schema before applying because argument
availability can change between provider versions.

------------------------------------------------------------------------

# 52. Terraform Workflow

``` bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Verify:

``` bash
terraform state list
```

Do not casually run:

``` bash
terraform destroy
```

against the Shield Advanced subscription resource. Review the
subscription lifecycle first.

------------------------------------------------------------------------

# 53. CloudFront + Shield Architecture

A common global application design is:

``` text
Users
  |
  v
Route 53
  |
  v
CloudFront
  |
  +---- Shield Advanced
  +---- AWS WAF
  |
  v
ALB
  |
  v
Private EC2 / ECS
```

CloudFront provides global distribution, Shield provides DDoS
protection, WAF provides HTTP/HTTPS filtering, and the ALB distributes
traffic to application targets.

------------------------------------------------------------------------

# 54. Global Accelerator + Shield

``` text
Users
  |
  v
Global Accelerator
  |
Shield Advanced
  |
  v
ALB / NLB
  |
  v
Application
```

Shield Advanced supports standard Global Accelerator accelerators.
[Protected
resources](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-protections-by-resource-type.html)

------------------------------------------------------------------------

# 55. Route 53 + Shield

Shield Advanced can protect Route 53 hosted zones.

This is DNS-layer protection and is different from WAF HTTP request
filtering.

``` text
User
 |
DNS query
 |
v
Route 53
 |
Shield Advanced
 |
v
Application endpoint
```

------------------------------------------------------------------------

# 56. Monitoring Architecture

``` text
Shield Advanced
      |
      +---- DDoS Events
      |
      v
CloudWatch
      |
      v
SNS
      |
      +---- Email
      +---- Incident system
```

Also monitor:

-   ALB target health
-   EC2/application metrics
-   WAF metrics
-   WAF logs
-   CloudFront metrics where applicable
-   Route 53 health checks

------------------------------------------------------------------------

# 57. Safe Testing

Do not generate a real DDoS attack to test Shield.

Instead verify:

``` text
[ ] Shield Advanced subscription
[ ] Protected resource
[ ] Protection status
[ ] WAF Web ACL
[ ] Rate-based rule
[ ] Automatic mitigation configuration
[ ] Health check
[ ] CloudWatch metrics
[ ] SNS notifications
[ ] Normal laptop requests
[ ] Application health
```

------------------------------------------------------------------------

# 58. Troubleshooting

## Resource is not protected

Check:

``` text
Shield Advanced subscription
Resource ARN
Protected resources
Protection status
Account
Region
```

Shield Advanced does not automatically protect every AWS resource.
[Protected
resources](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-protections-by-resource-type.html)

## ALB works but Shield shows no protection

Run:

``` bash
aws shield list-protections
```

Confirm the ALB ARN.

## WAF blocks legitimate requests

Check:

``` text
Web ACL
Managed rules
Rule priority
Rate rules
WAF logs
Rule overrides
```

## Application is unavailable during traffic increase

Check:

``` text
Shield events
WAF events
ALB target health
EC2 capacity
Auto Scaling
CloudWatch
Application logs
```

A traffic increase is not automatically a DDoS event.

## CloudFront protection issue

Check:

``` text
CloudFront distribution
Shield protection
WAF scope
WAF association
DNS
Origin
```

------------------------------------------------------------------------

# 59. Best Practices

1.  Use Shield Standard as the baseline protection automatically
    provided by AWS.
2.  Evaluate Shield Advanced for critical or high-visibility
    applications.
3.  Configure Advanced protection before an attack occurs.
4.  Use CloudFront for appropriate globally distributed applications.
5.  Use AWS WAF for application-layer request controls.
6.  Use WAF rate-based rules with Shield Advanced for application-layer
    DDoS protection.
7.  Deploy across multiple Availability Zones.
8.  Keep backend resources private where appropriate.
9.  Restrict backend Security Groups to expected sources.
10. Configure health checks.
11. Configure CloudWatch and SNS monitoring.
12. Maintain proactive engagement contacts.
13. Review Shield Advanced pricing and subscription terms before
    activation.
14. Use Firewall Manager for centralized multi-account policy
    management.
15. Never perform an actual DDoS attack as a test.
16. Maintain an incident-response procedure.

------------------------------------------------------------------------

# 60. Console vs CLI vs Terraform

  Capability                  Management Console   AWS CLI      Terraform
  --------------------------- -------------------- ------------ ------------------------
  Subscribe Shield Advanced   Yes                  Yes          Yes
  Protect ALB                 Yes                  Yes          Yes
  Protect CloudFront          Yes                  Yes          Yes
  Protect EIP                 Yes                  Yes          Yes
  Protection groups           Yes                  Yes          Yes
  Health check association    Yes                  Yes          Yes
  Proactive engagement        Yes                  Yes          Yes
  Response role association   Yes                  Yes          Yes
  Version controlled          No                   Scripts      Yes
  Repeatable                  Medium               High         High
  Subscription lifecycle      Manual               API/CLI      Terraform resource
  Best use                    Interactive setup    Automation   Infrastructure as Code

------------------------------------------------------------------------

# 61. SAA-C03 Architecture Decision Table

  Scenario                               Appropriate AWS service/design
  -------------------------------------- --------------------------------
  Basic automatic DDoS protection        Shield Standard
  Advanced DDoS protection               Shield Advanced
  Protect CloudFront                     Shield + CloudFront
  Protect ALB                            Shield Advanced
  Protect Route 53 hosted zone           Shield Advanced
  Protect Global Accelerator             Shield Advanced
  SQL injection filtering                AWS WAF
  HTTP request rate limiting             AWS WAF rate-based rule
  Remote laptop private VPC access       AWS Client VPN
  Branch-to-VPC connectivity             Site-to-Site VPN
  Dedicated connectivity                 Direct Connect
  VPC traffic inspection                 AWS Network Firewall
  Multi-account centralized protection   AWS Firewall Manager

------------------------------------------------------------------------

# 62. SAA-C03 Scenario Questions

## Scenario 1

A company has a public CloudFront application and needs DDoS protection.

**Relevant design:**

``` text
CloudFront + Shield
```

Add WAF for HTTP request filtering.

## Scenario 2

A company needs SQL injection protection.

**Relevant service:**

``` text
AWS WAF
```

## Scenario 3

A company needs advanced DDoS protection and AWS expert response.

**Relevant service:**

``` text
AWS Shield Advanced
```

## Scenario 4

Employees need private EC2 access from home laptops.

**Relevant service:**

``` text
AWS Client VPN
```

## Scenario 5

A company needs a dedicated connection from its data center to AWS.

**Relevant service:**

``` text
AWS Direct Connect
```

## Scenario 6

An organization wants centralized Shield Advanced policies across
accounts.

**Relevant service:**

``` text
AWS Firewall Manager
```

------------------------------------------------------------------------

# 63. Official AWS Documentation

  -----------------------------------------------------------------------------------------------------------------------------------
  Topic                               AWS documentation
  ----------------------------------- -----------------------------------------------------------------------------------------------
  AWS Shield                          https://docs.aws.amazon.com/shield/

  Shield Developer Guide              https://docs.aws.amazon.com/waf/latest/developerguide/shield-chapter.html

  How Shield works                    https://docs.aws.amazon.com/waf/latest/developerguide/ddos-overview.html

  Shield Standard                     https://docs.aws.amazon.com/waf/latest/developerguide/ddos-standard-summary.html

  Shield Advanced overview            https://docs.aws.amazon.com/waf/latest/developerguide/ddos-advanced-summary.html

  Shield Advanced capabilities        https://docs.aws.amazon.com/waf/latest/developerguide/ddos-advanced-summary-capabilities.html

  Setting up Shield Advanced          https://docs.aws.amazon.com/waf/latest/developerguide/getting-started-ddos.html

  Protected resources                 https://docs.aws.amazon.com/waf/latest/developerguide/ddos-protections-by-resource-type.html

  EC2/NLB protection                  https://docs.aws.amazon.com/waf/latest/developerguide/ddos-protections-ec2-nlb.html

  Shield + WAF                        https://docs.aws.amazon.com/waf/latest/developerguide/ddos-app-layer-protections.html

  Shield + WAF Web ACL/rate rule      https://docs.aws.amazon.com/waf/latest/developerguide/ddos-app-layer-web-ACL-and-rbr.html

  Protection groups                   https://docs.aws.amazon.com/waf/latest/developerguide/protection-group-creating.html

  Shield API                          https://docs.aws.amazon.com/waf/latest/APIReference/

  Shield CLI examples                 https://docs.aws.amazon.com/cli/latest/userguide/cli_shield_code_examples.html

  create-protection                   https://docs.aws.amazon.com/cli/latest/reference/shield/create-protection.html

  Shield pricing                      https://aws.amazon.com/shield/pricing/
  -----------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 64. Terraform Documentation

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Terraform resource                                  Documentation
  --------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------
  `aws_shield_subscription`                           https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_subscription

  `aws_shield_protection`                             https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_protection

  `aws_shield_protection_group`                       https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_protection_group

  `aws_shield_protection_health_check_association`    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_protection_health_check_association

  `aws_shield_proactive_engagement`                   https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_proactive_engagement

  `aws_shield_application_layer_automatic_response`   https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_application_layer_automatic_response
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 65. Final SAA-C03 Mental Model

``` text
Shield Standard
    |
    +--> Automatic baseline DDoS protection

Shield Advanced
    |
    +--> Expanded DDoS protection
    +--> Advanced event visibility
    +--> WAF integration
    +--> Automatic application-layer mitigation
    +--> Health-based detection
    +--> SRT support
    +--> Proactive engagement
    +--> DDoS cost protection
```

For a public web application:

``` text
                         INTERNET
                            |
                            v
                     Laptop / Users
                            |
                           HTTPS
                            |
                            v
                    CloudFront / ALB
                            |
                    +-------+-------+
                    |               |
              Shield Advanced      WAF
                    |               |
                    +-------+-------+
                            |
                            v
                       Application
                            |
                            v
                           VPC
                            |
                       Private EC2
```

The key SAA-C03 distinction is:

``` text
AWS Shield
    = DDoS protection

AWS WAF
    = HTTP/HTTPS web request filtering

AWS Client VPN
    = Remote laptop/private network connectivity

Site-to-Site VPN
    = Network-to-network VPN

Direct Connect
    = Dedicated connectivity

AWS Network Firewall
    = VPC/network traffic inspection

AWS Firewall Manager
    = Centralized security policy management
```

AWS Shield protects applications from DDoS attacks; it does not provide
laptop-to-VPC VPN connectivity. For private laptop access to a VPC, use
Client VPN. For a laptop accessing a public web application, Shield can
protect the application entry point such as an ALB or CloudFront
distribution.
