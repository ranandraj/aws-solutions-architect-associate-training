# AWS WAF

## Professional AWS Solutions Architect Associate (SAA-C03) Documentation

**Scope:** AWS WAF concepts, Web ACLs, rules, managed rule groups, IP
sets, rate limiting, SQL injection/XSS protection, CAPTCHA/Challenge,
rule priority, scope, logging, metrics, Management Console
implementation, laptop testing, AWS CLI, Terraform, troubleshooting,
security design, and SAA-C03 exam points.

> **Important:** AWS WAF is a web application firewall. It does **not**
> create a VPN connection from a laptop into a VPC. A laptop can access
> a web application protected by WAF, but private network access from a
> laptop requires AWS Client VPN or another network connectivity
> service.

------------------------------------------------------------------------

# 1. AWS WAF Overview

AWS WAF is a managed web application firewall that lets you inspect
HTTP/HTTPS requests and control whether they are allowed to reach
supported AWS resources.

AWS WAF can protect resources including:

-   Amazon CloudFront
-   Application Load Balancer
-   Amazon API Gateway REST APIs
-   AWS AppSync
-   Amazon Cognito user pools
-   AWS App Runner
-   AWS Amplify
-   AWS Verified Access
-   Amazon Bedrock AgentCore Gateway

AWS WAF can inspect characteristics such as:

-   Source IP
-   Country
-   URI path
-   Query string
-   HTTP method
-   Headers
-   Cookies
-   Request body
-   Regular expressions
-   String matches
-   SQL injection patterns
-   Cross-site scripting patterns
-   Request rate
-   Labels

A Web ACL contains rules that inspect requests and apply actions such as
Allow, Block, Count, CAPTCHA, or Challenge.

**AWS documentation:**\
https://docs.aws.amazon.com/waf/

------------------------------------------------------------------------

# 2. AWS WAF Architecture

``` text
                         Internet
                            |
                            v
                    +---------------+
                    | Laptop/Client |
                    +-------+-------+
                            |
                          HTTPS
                            |
                            v
                  +-------------------+
                  | CloudFront / ALB  |
                  +---------+---------+
                            |
                       AWS WAF
                       Web ACL
                            |
                 +----------+----------+
                 |                     |
               BLOCK                 ALLOW
                 |                     |
                 v                     v
              HTTP 403             Application
                                        |
                                        v
                                      VPC
                                        |
                                  +-----+-----+
                                  |           |
                                 EC2         RDS
```

The request processing model is:

``` text
Client
  |
  v
Protected AWS resource
  |
  v
AWS WAF Web ACL
  |
  +--> Rule match --> Action
  |
  +--> No terminating match
            |
            v
       Default action
```

AWS WAF is primarily an application-layer security control. It does not
replace Security Groups, Network ACLs, AWS Network Firewall, AWS Shield,
or Client VPN.

**How AWS WAF works:**\
https://docs.aws.amazon.com/waf/latest/developerguide/how-aws-waf-works.html

------------------------------------------------------------------------

# 3. WAF and Laptop-to-VPC Connectivity

The phrase "connect a laptop to AWS VPC using WAF" represents two
different requirements.

## Requirement A: Laptop accesses a web application

``` text
Laptop
   |
 HTTPS
   v
ALB / CloudFront / API Gateway
   |
 AWS WAF
   |
   v
Application in AWS
```

AWS WAF is appropriate here.

## Requirement B: Laptop needs private IP/network access

``` text
Laptop
   |
Client VPN
   |
AWS VPC
   |
Private EC2 / RDS
```

AWS Client VPN is appropriate here.

  Requirement                WAF               Client VPN
  -------------------------- ----------------- ------------
  Web request filtering      Yes               No
  SQL injection protection   Yes               No
  XSS protection             Yes               No
  HTTP rate limiting         Yes               No
  Laptop VPN tunnel          No                Yes
  Private IP access          Not its purpose   Yes
  Protect ALB                Yes               No
  Protect API Gateway        Yes               No

For this WAF implementation, the laptop will access an application
through an internet-facing Application Load Balancer. WAF will inspect
the HTTP/HTTPS requests.

------------------------------------------------------------------------

# 4. Core AWS WAF Components

  Component                  Purpose
  -------------------------- -------------------------------------------------
  Web ACL                    Main WAF policy
  Rule                       Defines what to inspect and what action to take
  Rule Statement             Defines the matching condition
  Rule Group                 Reusable collection of rules
  Managed Rule Group         Rules maintained by AWS or another provider
  IP Set                     Collection of IP/CIDR addresses
  Regex Pattern Set          Reusable regex patterns
  Rule Action                Allow, Block, Count, CAPTCHA, Challenge
  Default Action             Action when no terminating rule matches
  Scope                      REGIONAL or CLOUDFRONT
  WCU                        Capacity measurement for WAF rules
  Visibility Configuration   Metrics and sampled requests
  Logging                    Detailed WAF request records

------------------------------------------------------------------------

# 5. Web ACL

A Web ACL is the main AWS WAF policy object.

Example:

``` text
production-web-acl

Rules
  |
  +-- Block malicious IPs
  +-- AWS Managed Rules
  +-- SQL injection protection
  +-- XSS protection
  +-- Login rate limit

Default action
  |
  +-- Allow
```

A Web ACL is associated with the AWS resource being protected.

AWS documentation:\
https://docs.aws.amazon.com/waf/latest/developerguide/web-acl.html

------------------------------------------------------------------------

# 6. Web ACL Scope

AWS WAF uses two scopes:

``` text
REGIONAL
CLOUDFRONT
```

## REGIONAL

Used for regional resources such as:

-   Application Load Balancer
-   API Gateway REST API
-   AppSync
-   Cognito user pool
-   App Runner
-   Amplify
-   Verified Access

## CLOUDFRONT

Used for:

-   CloudFront distributions

CloudFront-scoped WAF resources are configured through the US East (N.
Virginia) Region.

  Feature                   REGIONAL          CLOUDFRONT
  ------------------------- ----------------- ------------------
  ALB                       Yes               No
  API Gateway REST API      Yes               No
  CloudFront                No                Yes
  AppSync                   Yes               No
  Cognito                   Yes               No
  WAF management location   Resource Region   us-east-1
  Common architecture       ALB + WAF         CloudFront + WAF

------------------------------------------------------------------------

# 7. Rules and Rule Statements

A rule contains:

1.  A name
2.  A priority
3.  A statement
4.  An action
5.  Visibility configuration

Example:

``` text
Rule:
BlockBadIP

Statement:
Source IP belongs to blocked IP set

Action:
BLOCK
```

A rule statement defines what AWS WAF inspects.

Common statement types include:

-   IP set match
-   Geo match
-   Byte match
-   Regex pattern set
-   Size constraint
-   SQL injection match
-   XSS match
-   Rate-based
-   Managed rule group
-   Label match
-   AND
-   OR
-   NOT

**Rules:**\
https://docs.aws.amazon.com/waf/latest/developerguide/waf-rules.html

------------------------------------------------------------------------

# 8. Rule Priority

AWS WAF evaluates rules by numeric priority.

Lower number is evaluated first.

Example:

    Priority Rule
  ---------- ----------------------------
           0 Allow trusted source
          10 Block malicious IP
          20 AWS Managed Rules
          30 Rate limit login
          40 Application-specific rules

Evaluation proceeds from the lowest priority number upward until a
terminating action occurs or all rules finish.

**AWS documentation:**\
https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-processing-order.html

------------------------------------------------------------------------

# 9. Rule Actions

  Action      Result                        Evaluation
  ----------- ----------------------------- ------------------
  Allow       Request proceeds              Terminating
  Block       Request is blocked            Terminating
  Count       Request is counted            Non-terminating
  CAPTCHA     Human verification            Depends on token
  Challenge   Browser/client verification   Depends on token

Allow and Block normally terminate WAF evaluation.

Count continues evaluation.

CAPTCHA and Challenge can behave as terminating or non-terminating
depending on token state.

**AWS documentation:**\
https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-action.html

------------------------------------------------------------------------

# 10. Default Action

Every Web ACL has a default action.

The common choices are:

``` text
ALLOW
BLOCK
```

Example:

``` text
Default:
ALLOW

Rules:
  Block malicious IP
  SQL injection rule
  Rate limit
```

This means requests that do not match a terminating rule are allowed.

A restricted application can instead use:

``` text
Default:
BLOCK
```

and explicitly allow trusted requests.

  Design                   Default   Typical use
  ------------------------ --------- -----------------------------
  Public website           Allow     Block specific bad traffic
  Restricted application   Block     Allow known/trusted traffic

**AWS documentation:**\
https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-default-action.html

------------------------------------------------------------------------

# 11. IP Sets

An IP set is a reusable list of IP addresses or CIDR ranges.

Example:

``` text
BlockedIPs

203.0.113.10/32
198.51.100.0/24
```

A rule can reference the IP set:

``` text
IP Set
  |
  v
IP Match Statement
  |
  v
BLOCK
```

Typical uses:

-   Known malicious IPs
-   Corporate allowlists
-   Partner networks
-   Administrative access restrictions

**AWS documentation:**\
https://docs.aws.amazon.com/waf/latest/developerguide/waf-ip-set-managing.html

------------------------------------------------------------------------

# 12. Geo Match

AWS WAF can match requests according to geographic origin associated
with the source IP.

Example:

``` text
Allow:
IN
US
SG
```

or:

``` text
Block selected countries
```

Geo rules should be used only when they match a real
application/security requirement.

------------------------------------------------------------------------

# 13. Byte Match and Regex

Byte match rules search for specified strings in request components.

Examples:

``` text
URI path
HTTP method
Header
Query string
Cookie
Body
```

Regex pattern sets provide reusable regular-expression matching.

Example:

``` text
^/admin/.*
```

This could be used to identify requests to administrative paths.

------------------------------------------------------------------------

# 14. SQL Injection Protection

AWS WAF has a SQL injection match statement designed to detect request
patterns associated with SQL injection.

Example:

``` text
GET /products?id=' OR 1=1
```

A SQL injection rule can inspect relevant request components and take an
action such as Block.

Use this as a defensive layer. Application code must still use secure
database access techniques such as parameterized queries.

**AWS documentation:**\
https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-sqli.html

------------------------------------------------------------------------

# 15. Cross-Site Scripting Protection

AWS WAF provides an XSS match statement for request patterns associated
with cross-site scripting.

Example:

``` text
<script>...</script>
```

A WAF XSS rule can block suspicious requests.

Application output encoding and secure application development remain
necessary.

**AWS documentation:**\
https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-xss.html

------------------------------------------------------------------------

# 16. Rate-Based Rules

A rate-based rule counts requests and applies its action when traffic
exceeds the configured limit.

Example:

``` text
Client IP
   |
   v
Requests
   |
   v
Rate threshold exceeded
   |
   v
BLOCK
```

Typical uses:

-   Login endpoint protection
-   API abuse control
-   Excessive request control
-   Scraping reduction
-   Application-layer flood control

A rate-based rule can use a scope-down statement to limit which requests
are counted.

**AWS documentation:**\
https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based.html

------------------------------------------------------------------------

# 17. Managed Rule Groups

AWS Managed Rules are preconfigured rule groups maintained by AWS.

They can provide protection against common web threats without requiring
every rule to be manually written.

Examples include protection related to:

-   Common web attacks
-   Known bad inputs
-   SQL injection
-   IP reputation
-   Anonymous IP sources
-   Bot-related activity

Managed rule groups can be combined with custom rules.

  Feature                      Managed Rule Group    Custom Rule
  ---------------------------- --------------------- ---------------------
  Maintained by                AWS/provider          You
  Setup                        Faster                More work
  Common threats               Good starting point   Depends on design
  Application-specific logic   Limited               Strong
  Maintenance                  Provider              Your responsibility

**AWS documentation:**\
https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups.html

------------------------------------------------------------------------

# 18. Rule Groups

A rule group is a reusable collection of rules.

Types include:

-   Your own rule groups
-   AWS Managed Rule Groups
-   AWS Marketplace managed rule groups
-   Rule groups managed by other AWS services

A rule group is not directly associated with an AWS resource. The Web
ACL containing the rule group is associated with the resource.

**AWS documentation:**\
https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-groups.html

------------------------------------------------------------------------

# 19. Scope-Down Statements

Scope-down statements restrict the requests evaluated by a rule or rule
group.

Example:

``` text
AWS Managed Rule Group
        |
        v
Scope-down:
URI starts with /api/
        |
        v
Only /api/ traffic evaluated
```

This is useful when a managed rule group should apply only to a specific
part of an application.

------------------------------------------------------------------------

# 20. Labels

AWS WAF can add labels to matching requests.

Example:

``` text
Rule 1
Detect suspicious API request
        |
        v
Label:
suspicious-api
        |
        v
Rule 2
Match label
        |
        v
BLOCK
```

Labels allow multi-stage request processing.

------------------------------------------------------------------------

# 21. Web ACL Capacity Units (WCUs)

AWS WAF uses Web ACL Capacity Units, or WCUs, to measure rule capacity.

Different statements consume different WCU amounts.

A Web ACL has a maximum capacity of:

``` text
5,000 WCUs
```

Complex Web ACLs should be designed with WCU usage in mind.

------------------------------------------------------------------------

# 22. AWS WAF vs Other Security Services

  Service                Main purpose
  ---------------------- -----------------------------------------------
  AWS WAF                HTTP/HTTPS web request filtering
  Security Group         Stateful instance/interface traffic filtering
  Network ACL            Stateless subnet traffic filtering
  AWS Network Firewall   VPC/network traffic inspection
  AWS Shield             DDoS protection
  AWS Firewall Manager   Centralized security policy management
  Client VPN             Remote user VPN
  Site-to-Site VPN       Network-to-network VPN
  Direct Connect         Dedicated network connectivity

------------------------------------------------------------------------

# 23. AWS WAF vs Security Group

  Feature           AWS WAF                  Security Group
  ----------------- ------------------------ ----------------
  Layer             Application              Network
  HTTP inspection   Yes                      No
  URI filtering     Yes                      No
  SQL injection     Yes                      No
  XSS               Yes                      No
  Port filtering    Not primary              Yes
  Stateful          Web request processing   Yes
  Example           Block `/admin`           Allow TCP 443

------------------------------------------------------------------------

# 24. AWS WAF vs Network Firewall

  Feature                      AWS WAF                         AWS Network Firewall
  ---------------------------- ------------------------------- ------------------------------------
  Primary layer                Web/application                 Network
  HTTP request rules           Yes                             Different network inspection model
  SQL injection/XSS controls   Yes                             Not the primary service
  VPC network traffic          Not its primary role            Yes
  Association                  Web ACL to supported resource   Firewall endpoints
  Typical use                  Public web/API protection       VPC network security

------------------------------------------------------------------------

# 25. AWS WAF vs Shield

  Feature                    AWS WAF                      AWS Shield
  -------------------------- ---------------------------- ----------------------
  Web request filtering      Yes                          No
  SQL injection/XSS          Yes                          No
  Custom application rules   Yes                          No
  DDoS protection            Application-layer controls   Primary DDoS service
  Advanced DDoS service      No                           Shield Advanced

WAF and Shield can be used together.

**AWS WAF documentation:**\
https://docs.aws.amazon.com/waf/

------------------------------------------------------------------------

# 26. AWS WAF vs Client VPN

  Requirement                       AWS WAF           AWS Client VPN
  --------------------------------- ----------------- ----------------
  Laptop VPN tunnel                 No                Yes
  Private VPC IP access             Not its purpose   Yes
  Web request filtering             Yes               No
  SQL injection                     Yes               No
  HTTP rate limiting                Yes               No
  Protect ALB                       Yes               No
  Remote employee private network   No                Yes

------------------------------------------------------------------------

# 27. Management Console Lab Architecture

The following implementation lets a laptop test WAF:

``` text
                     Internet
                         |
                         v
                 Laptop Browser
                         |
                       HTTPS
                         |
                         v
                +----------------+
                | Internet ALB   |
                +-------+--------+
                        |
                    AWS WAF
                    Web ACL
                        |
                 +------+------+
                 |             |
               BLOCK         ALLOW
                 |             |
                 v             v
              HTTP 403      Target Group
                               |
                               v
                          Private EC2
                               |
                               v
                          Web Server
```

The EC2 instance can remain private.

------------------------------------------------------------------------

# 28. Lab Network

Use an example architecture:

  Resource             Example
  -------------------- -----------------
  Region               ap-south-1
  VPC                  10.0.0.0/16
  Public subnet A      10.0.1.0/24
  Public subnet B      10.0.2.0/24
  Private subnet A     10.0.11.0/24
  Private subnet B     10.0.12.0/24
  ALB                  Internet-facing
  WAF scope            REGIONAL
  WAF resource         ALB
  EC2                  Private subnet
  Default WAF action   Allow

------------------------------------------------------------------------

# 29. Prerequisites

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

For HTTPS production deployments, use an ACM certificate and an HTTPS
listener.

------------------------------------------------------------------------

# 30. Console Step 1: Create/Select VPC

Open:

https://console.aws.amazon.com/vpc/

Use:

``` text
VPC CIDR:
10.0.0.0/16
```

Create/select:

``` text
Public Subnet A
Public Subnet B
Private Subnet A
Private Subnet B
```

Ensure public subnets have an Internet Gateway route.

------------------------------------------------------------------------

# 31. Console Step 2: EC2 Security Group

Create:

``` text
sg-web-ec2
```

Inbound:

``` text
HTTP TCP 80
Source:
ALB security group
```

Do not expose the EC2 web server directly to the Internet when the ALB
is the intended entry point.

------------------------------------------------------------------------

# 32. Console Step 3: Launch EC2

Launch an EC2 instance in a private subnet.

Example:

``` text
Private subnet:
10.0.11.0/24

Private IP:
10.0.11.10

Security group:
sg-web-ec2
```

Install a web server.

Amazon Linux example:

``` bash
sudo dnf install -y httpd
sudo systemctl enable --now httpd
echo "AWS WAF Test Application" | sudo tee /var/www/html/index.html
```

Verify:

``` bash
curl http://localhost
```

------------------------------------------------------------------------

# 33. Console Step 4: Create Target Group

Go to:

``` text
EC2
 -> Target Groups
 -> Create target group
```

Configure:

``` text
Target type:
Instances

Protocol:
HTTP

Port:
80

VPC:
your VPC
```

Register the EC2 instance.

Health check:

``` text
HTTP
/
```

Verify:

``` text
Target:
Healthy
```

------------------------------------------------------------------------

# 34. Console Step 5: Create Application Load Balancer

Go to:

``` text
EC2
 -> Load Balancers
 -> Create Load Balancer
```

Select:

``` text
Application Load Balancer
```

Set:

``` text
Scheme:
Internet-facing
```

Select two public subnets in different Availability Zones.

Listener:

``` text
HTTP : 80
```

Forward to:

``` text
web-target-group
```

For production:

``` text
HTTPS : 443
+
ACM certificate
```

------------------------------------------------------------------------

# 35. Console Step 6: Test Before WAF

Copy the ALB DNS name.

Example:

``` text
my-alb-123456.ap-south-1.elb.amazonaws.com
```

From your laptop:

``` text
http://my-alb-123456.ap-south-1.elb.amazonaws.com
```

Expected:

``` text
AWS WAF Test Application
```

At this point:

``` text
Laptop
  |
  v
ALB
  |
  v
EC2
```

No WAF rule is protecting the ALB yet.

------------------------------------------------------------------------

# 36. Console Step 7: Open AWS WAF

Open:

https://console.aws.amazon.com/wafv2/

Choose:

``` text
AWS WAF & Shield
 -> Web ACLs
 -> Create web ACL
```

------------------------------------------------------------------------

# 37. Console Step 8: Configure Web ACL

Choose:

``` text
Resource type:
Regional resources
```

Set:

``` text
Region:
ap-south-1

Name:
production-alb-waf
```

Associate it with:

``` text
Application Load Balancer
```

Select your ALB.

------------------------------------------------------------------------

# 38. Console Step 9: Default Action

Choose:

``` text
Allow
```

Meaning:

``` text
Request
   |
No terminating rule match
   |
ALLOW
```

Specific WAF rules can still block malicious requests.

------------------------------------------------------------------------

# 39. Console Step 10: Add Managed Rules

Choose:

``` text
Add managed rule groups
```

Select appropriate AWS Managed Rules for your application.

Review:

-   Included rules
-   WCU usage
-   Rule actions
-   Possible false positives
-   Pricing
-   Versioning

For an initial rollout, consider Count/overrides where appropriate so
that rules can be observed before blocking legitimate traffic.

------------------------------------------------------------------------

# 40. Console Step 11: Create an IP Set

Create an IP set:

``` text
blocked-test-ip-set
```

Add a test address that you control.

Do not block unrelated users.

Then create:

``` text
Rule:
Block-Test-IP

Statement:
IP address is in blocked-test-ip-set

Action:
BLOCK
```

------------------------------------------------------------------------

# 41. Console Step 12: Add Rate-Based Rule

Create:

``` text
RateLimit-Web
```

Select:

``` text
Rate-based rule
```

Use an appropriate threshold.

For example, for a controlled lab:

``` text
Aggregate key:
IP address
```

The production threshold should be based on normal traffic patterns.

------------------------------------------------------------------------

# 42. Console Step 13: Configure Visibility

Enable:

``` text
CloudWatch metrics
Sampled requests
```

Use meaningful metric names:

``` text
production-alb-waf
Block-Test-IP
RateLimit-Web
```

------------------------------------------------------------------------

# 43. Console Step 14: Enable Logging

AWS WAF logs can be sent to:

-   CloudWatch Logs
-   S3
-   Amazon Data Firehose

Logging provides detailed request and rule-match information.

Use WAF data protection/redaction and filtering where sensitive request
information requires protection.

**Logging:**\
https://docs.aws.amazon.com/waf/latest/developerguide/logging.html

------------------------------------------------------------------------

# 44. Console Step 15: Create Web ACL

Review:

``` text
Scope
Resource association
Default action
Rules
Rule priority
Managed rules
Metrics
Logging
```

Choose:

``` text
Create web ACL
```

Allow time for changes to propagate.

------------------------------------------------------------------------

# 45. Console Step 16: Verify Association

Open:

``` text
AWS WAF
 -> Web ACLs
 -> production-alb-waf
```

Confirm:

``` text
Associated resource:
Your ALB
```

Traffic now follows:

``` text
Laptop
   |
   v
ALB
   |
   v
AWS WAF
   |
   v
EC2
```

------------------------------------------------------------------------

# 46. Laptop Test: Normal Request

PowerShell:

``` powershell
curl http://my-alb-123456.ap-south-1.elb.amazonaws.com/
```

Expected:

``` text
AWS WAF Test Application
```

------------------------------------------------------------------------

# 47. Laptop Test: Blocked IP

If your current public test IP is deliberately included in the WAF IP
set:

``` powershell
curl.exe -i http://my-alb-123456.ap-south-1.elb.amazonaws.com/
```

Expected:

``` text
HTTP/1.1 403 Forbidden
```

Traffic path:

``` text
Laptop
   |
   v
ALB
   |
   v
WAF rule matches
   |
   X
BLOCK
```

The blocked request should not reach the application target.

------------------------------------------------------------------------

# 48. Laptop Test: Rate-Based Rule

Use controlled testing only.

Example PowerShell:

``` powershell
1..20 | ForEach-Object {
    curl.exe -s -o NUL -w "%{http_code}`n" http://my-alb-123456.ap-south-1.elb.amazonaws.com/
}
```

When the configured rate threshold is exceeded, the configured action
can be applied.

Do not perform aggressive traffic generation against production systems.

------------------------------------------------------------------------

# 49. CloudWatch Verification

Open:

``` text
CloudWatch
 -> Metrics
 -> AWS/WAFV2
```

Look for metrics such as:

``` text
AllowedRequests
BlockedRequests
CountedRequests
CaptchaRequests
ChallengeRequests
```

The exact metrics available depend on your rules and actions.

------------------------------------------------------------------------

# 50. AWS CLI Implementation

Set the Region:

``` bash
aws configure
```

Linux/macOS:

``` bash
export AWS_DEFAULT_REGION=ap-south-1
```

PowerShell:

``` powershell
$env:AWS_DEFAULT_REGION="ap-south-1"
```

------------------------------------------------------------------------

# 51. CLI: Create IP Set

``` bash
aws wafv2 create-ip-set   --name blocked-test-ip-set   --scope REGIONAL   --ip-address-version IPV4   --addresses 203.0.113.10/32   --region ap-south-1
```

Record the returned:

``` text
ARN
ID
LockToken
```

------------------------------------------------------------------------

# 52. CLI: Create Web ACL

Create `web-acl-rules.json`.

Example rule:

``` json
[
  {
    "Name": "BlockBadIP",
    "Priority": 0,
    "Statement": {
      "IPSetReferenceStatement": {
        "ARN": "arn:aws:wafv2:ap-south-1:123456789012:regional/ipset/blocked-test-ip-set/EXAMPLE-ID"
      }
    },
    "Action": {
      "Block": {}
    },
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "BlockBadIP"
    }
  }
]
```

Create:

``` bash
aws wafv2 create-web-acl   --name alb-waf   --scope REGIONAL   --default-action Allow={}   --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=alb-waf   --rules file://web-acl-rules.json   --region ap-south-1
```

Record the Web ACL ARN and ID.

**AWS CLI examples:**\
https://docs.aws.amazon.com/cli/latest/userguide/cli_wafv2_code_examples.html

------------------------------------------------------------------------

# 53. CLI: Associate Web ACL with ALB

For regional resources:

``` bash
aws wafv2 associate-web-acl   --web-acl-arn arn:aws:wafv2:ap-south-1:123456789012:regional/webacl/alb-waf/EXAMPLE-ID   --resource-arn arn:aws:elasticloadbalancing:ap-south-1:123456789012:loadbalancer/app/my-alb/EXAMPLE   --region ap-south-1
```

This command produces no output on success.

**AWS documentation:**\
https://docs.aws.amazon.com/cli/latest/reference/wafv2/associate-web-acl.html

------------------------------------------------------------------------

# 54. CLI: Verify Association

``` bash
aws wafv2 get-web-acl-for-resource   --resource-arn arn:aws:elasticloadbalancing:ap-south-1:123456789012:loadbalancer/app/my-alb/EXAMPLE   --region ap-south-1
```

------------------------------------------------------------------------

# 55. CLI: List Web ACLs

``` bash
aws wafv2 list-web-acls   --scope REGIONAL   --region ap-south-1
```

------------------------------------------------------------------------

# 56. CLI: List IP Sets

``` bash
aws wafv2 list-ip-sets   --scope REGIONAL   --region ap-south-1
```

------------------------------------------------------------------------

# 57. CLI: Get Web ACL

``` bash
aws wafv2 get-web-acl   --name alb-waf   --scope REGIONAL   --id WEB_ACL_ID   --region ap-south-1
```

Remember that update operations use the returned lock token.

------------------------------------------------------------------------

# 58. CLI: CloudWatch Metrics

``` bash
aws cloudwatch list-metrics   --namespace AWS/WAFV2   --region ap-south-1
```

------------------------------------------------------------------------

# 59. Terraform WAFv2 Resources

Important Terraform resources include:

  Terraform resource                          Purpose
  ------------------------------------------- -------------------------------
  `aws_wafv2_web_acl`                         Web ACL
  `aws_wafv2_web_acl_association`             Regional resource association
  `aws_wafv2_ip_set`                          IP set
  `aws_wafv2_regex_pattern_set`               Regex pattern set
  `aws_wafv2_rule_group`                      Reusable rule group
  `aws_wafv2_web_acl_logging_configuration`   WAF logging

For CloudFront, configure the Web ACL ARN directly on the CloudFront
distribution rather than using `aws_wafv2_web_acl_association`.

**Terraform Web ACL:**\
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl

**Terraform association:**\
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association

------------------------------------------------------------------------

# 60. Terraform Provider

Example:

``` hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.57"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-south-1"
}
```

Check the current provider version before production deployment.

------------------------------------------------------------------------

# 61. Terraform IP Set

``` hcl
resource "aws_wafv2_ip_set" "blocked" {
  name               = "blocked-test-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = [
    "203.0.113.10/32"
  ]

  description = "Test blocked IP addresses"
}
```

------------------------------------------------------------------------

# 62. Terraform Web ACL

``` hcl
resource "aws_wafv2_web_acl" "alb" {
  name  = "production-alb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "BlockBadIP"
    priority = 0

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blocked.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockBadIP"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "production-alb-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "production-alb-waf"
  }
}
```

------------------------------------------------------------------------

# 63. Terraform ALB Association

For a regional ALB:

``` hcl
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.web.arn
  web_acl_arn  = aws_wafv2_web_acl.alb.arn
}
```

------------------------------------------------------------------------

# 64. Terraform Rate-Based Rule

``` hcl
rule {
  name     = "RateLimit"
  priority = 10

  action {
    block {}
  }

  statement {
    rate_based_statement {
      limit              = 1000
      aggregate_key_type = "IP"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RateLimit"
    sampled_requests_enabled   = true
  }
}
```

Choose the limit from actual application traffic requirements.

------------------------------------------------------------------------

# 65. Terraform Managed Rule Group

Example structure:

``` hcl
rule {
  name     = "AWSManagedRulesCommonRuleSet"
  priority = 20

  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesCommonRuleSet"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "AWSManagedRulesCommonRuleSet"
    sampled_requests_enabled   = true
  }
}
```

Check the current AWS Managed Rules documentation before production
deployment because managed rule groups and rule behavior can change.

------------------------------------------------------------------------

# 66. Terraform SQL Injection Rule

Example:

``` hcl
statement {
  sqli_match_statement {
    field_to_match {
      body {}
    }

    text_transformation {
      priority = 0
      type     = "URL_DECODE"
    }
  }
}
```

Configure body inspection and oversize handling according to the current
AWS WAF and provider requirements.

------------------------------------------------------------------------

# 67. Terraform Workflow

``` bash
terraform init
```

``` bash
terraform fmt
```

``` bash
terraform validate
```

``` bash
terraform plan
```

``` bash
terraform apply
```

Verify:

``` bash
terraform state list
```

Cleanup:

``` bash
terraform destroy
```

------------------------------------------------------------------------

# 68. CloudFront + WAF

A common production architecture is:

``` text
Laptop
   |
   v
CloudFront
   |
AWS WAF
   |
   v
ALB
   |
   v
EC2 / ECS
```

For CloudFront:

``` text
WAF Scope:
CLOUDFRONT
```

The CloudFront Web ACL is configured in the US East (N. Virginia)
Region.

Terraform example:

``` hcl
resource "aws_cloudfront_distribution" "app" {
  # distribution configuration

  web_acl_id = aws_wafv2_web_acl.cloudfront.arn
}
```

Do not use `aws_wafv2_web_acl_association` for CloudFront.

------------------------------------------------------------------------

# 69. API Gateway + WAF

Architecture:

``` text
Laptop
   |
 HTTPS
   v
API Gateway
   |
AWS WAF
   |
   v
Backend
```

Useful WAF controls include:

-   Rate limiting
-   IP restrictions
-   SQL injection protection
-   XSS protection
-   Managed rule groups

------------------------------------------------------------------------

# 70. ALB + WAF

Common regional architecture:

``` text
Internet
   |
   v
ALB
   |
AWS WAF
   |
   v
Target Group
   |
   v
EC2 / ECS
```

The target resources can remain private.

------------------------------------------------------------------------

# 71. Security Group Design with WAF

A layered design is:

``` text
Internet
   |
 TCP 443
   |
   v
ALB Security Group
   |
   v
AWS WAF
   |
   v
Target Group
   |
   v
EC2 Security Group
```

The EC2 security group should generally allow the application port from
the ALB security group rather than directly from the Internet.

------------------------------------------------------------------------

# 72. Logging

AWS WAF logs can be delivered to:

``` text
CloudWatch Logs
S3
Amazon Data Firehose
```

Logs provide information about:

-   Request time
-   Request details
-   Matching rules
-   Rule actions
-   Source information
-   Labels
-   Terminating rules
-   Non-terminating matches

**AWS logging documentation:**\
https://docs.aws.amazon.com/waf/latest/developerguide/logging.html

------------------------------------------------------------------------

# 73. Metrics and Sampled Requests

CloudWatch metrics can include:

``` text
AllowedRequests
BlockedRequests
CountedRequests
CaptchaRequests
ChallengeRequests
```

Sampled requests are useful for rule tuning.

A good rollout process is:

``` text
Create rule
   |
   v
Count / observe
   |
   v
Review sampled requests and logs
   |
   v
Tune
   |
   v
Block
   |
   v
Monitor
```

------------------------------------------------------------------------

# 74. Troubleshooting

## WAF is not blocking

Check:

``` text
Web ACL scope
Resource association
Rule priority
Rule statement
Rule action
Default action
```

Verify:

``` bash
aws wafv2 get-web-acl-for-resource   --resource-arn <resource-arn>   --region ap-south-1
```

## Everything is blocked

Check:

``` text
Default action
Block rules
Allow rules
Rule priority
Managed rule overrides
```

If default action is Block, legitimate requests need appropriate Allow
logic.

## Managed rule blocks legitimate traffic

Use:

1.  WAF logs
2.  Sampled requests
3.  Rule identification
4.  Rule action overrides
5.  Narrow exceptions
6.  Retesting

Do not disable the complete managed rule group without understanding the
matching rule.

## Rate rule triggers unexpectedly

Check:

``` text
Normal traffic
Aggregation key
Evaluation scope
NAT/proxy behavior
Application traffic patterns
```

Many users can appear behind one public IP.

## CloudFront association fails

Check:

``` text
Scope = CLOUDFRONT
WAF management Region = us-east-1
CloudFront distribution configuration
```

## WAF is fine but application is unreachable

Check:

``` text
ALB listener
ALB security group
Target group
Target health
EC2 security group
EC2 application
VPC routes
```

------------------------------------------------------------------------

# 75. Security Best Practices

1.  Use AWS Managed Rules as a starting point for public applications.
2.  Add application-specific custom rules where required.
3.  Start new complex rules in Count mode where practical.
4.  Review sampled requests and WAF logs before enforcement.
5.  Use rate-based rules for appropriate high-risk endpoints.
6.  Keep WAF rules narrowly scoped.
7.  Avoid unnecessary global Block rules.
8.  Use IP sets for reusable source lists.
9.  Protect WAF logs and sensitive request data.
10. Enable CloudWatch metrics.
11. Use meaningful rule names and metric names.
12. Review WCU capacity.
13. Use separate Web ACLs where application requirements differ.
14. Use Firewall Manager for centralized multi-account policy
    management.
15. Combine WAF with Security Groups, secure application code, TLS, IAM,
    and appropriate network controls.

------------------------------------------------------------------------

# 76. AWS Firewall Manager and WAF

AWS Firewall Manager can centrally manage WAF policies across multiple
AWS accounts and resources.

Architecture:

``` text
AWS Organizations
       |
       v
Firewall Manager
       |
       +---- Account A
       |       |
       |      WAF
       |
       +---- Account B
       |       |
       |      WAF
       |
       +---- Account C
               |
              WAF
```

This is particularly relevant to multi-account enterprise architectures.

**AWS WAF/Firewall Manager documentation:**\
https://docs.aws.amazon.com/waf/

------------------------------------------------------------------------

# 77. Console vs CLI vs Terraform

  -----------------------------------------------------------------------
  Capability        Management        AWS CLI           Terraform
                    Console                             
  ----------------- ----------------- ----------------- -----------------
  Create Web ACL    Yes               Yes               Yes

  Create IP set     Yes               Yes               Yes

  Add custom rules  Yes               Yes               Yes

  Add managed rules Yes               Yes               Yes

  Associate with    Yes               Yes               Yes
  ALB                                                   

  CloudFront        Yes               CloudFront        CloudFront
  association                         configuration     resource

  Version           No                Scripts           Yes
  controlled                                            

  Repeatable        Medium            High              High

  Infrastructure    Limited           Limited           Strong
  drift management                                      

  Best use          Interactive setup Automation        Infrastructure as
                                                        Code
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 78. SAA-C03 Architecture Decision Table

  Scenario                          Service/design
  --------------------------------- -------------------------
  Block malicious HTTP requests     AWS WAF
  SQL injection protection          AWS WAF
  XSS protection                    AWS WAF
  Rate-limit web requests           AWS WAF rate-based rule
  Protect ALB                       AWS WAF
  Protect CloudFront                AWS WAF
  Protect API Gateway REST API      AWS WAF
  Centralized WAF across accounts   AWS Firewall Manager
  DDoS protection                   AWS Shield
  Laptop private network access     AWS Client VPN
  Branch-to-VPC connectivity        Site-to-Site VPN
  Dedicated network connectivity    Direct Connect
  VPC network firewall              AWS Network Firewall
  Instance traffic filtering        Security Groups
  Subnet stateless filtering        Network ACL

------------------------------------------------------------------------

# 79. SAA-C03 Exam Scenarios

## Scenario 1

A company has a public application behind an ALB and wants protection
against SQL injection and XSS.

Relevant service:

``` text
AWS WAF
```

## Scenario 2

A company wants to limit excessive requests to `/login`.

Relevant feature:

``` text
AWS WAF rate-based rule
+
scope-down statement where appropriate
```

## Scenario 3

A company wants to block known malicious IP addresses.

Relevant design:

``` text
AWS WAF IP Set
+
IP set match rule
+
Block
```

## Scenario 4

A company wants managed protection against common web attacks.

Relevant design:

``` text
AWS WAF
+
AWS Managed Rules
```

## Scenario 5

A company wants to protect a CloudFront distribution.

Relevant design:

``` text
CloudFront-scoped AWS WAF Web ACL
```

## Scenario 6

A company wants employees to connect from laptops to private EC2
instances.

Relevant service:

``` text
AWS Client VPN
```

Not AWS WAF.

## Scenario 7

A company wants a dedicated private network connection to AWS.

Relevant service:

``` text
AWS Direct Connect
```

------------------------------------------------------------------------

# 80. Official AWS Documentation Links

## Main AWS WAF Documentation

https://docs.aws.amazon.com/waf/

## AWS WAF Developer Guide

https://docs.aws.amazon.com/waf/latest/developerguide/

## How AWS WAF Works

https://docs.aws.amazon.com/waf/latest/developerguide/how-aws-waf-works.html

## Web ACLs

https://docs.aws.amazon.com/waf/latest/developerguide/web-acl.html

## Rules

https://docs.aws.amazon.com/waf/latest/developerguide/waf-rules.html

## Rule Actions

https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-action.html

## Rule Priority

https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-processing-order.html

## Rule Groups

https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-groups.html

## AWS Managed Rules

https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups.html

## Rate-Based Rules

https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based.html

## Rate Limiting

https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-rate-based-request-limiting.html

## CAPTCHA and Challenge

https://docs.aws.amazon.com/waf/latest/developerguide/waf-captcha-and-challenge-actions.html

## IP Sets

https://docs.aws.amazon.com/waf/latest/developerguide/waf-ip-set-managing.html

## SQL Injection Match

https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-sqli.html

## XSS Match

https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-xss.html

## Logging

https://docs.aws.amazon.com/waf/latest/developerguide/logging.html

## Metrics

https://docs.aws.amazon.com/waf/latest/developerguide/waf-metrics.html

## AWS WAF API Reference

https://docs.aws.amazon.com/waf/latest/APIReference/

## AWS CLI WAFv2 Examples

https://docs.aws.amazon.com/cli/latest/userguide/cli_wafv2_code_examples.html

## AWS CLI create-web-acl

https://docs.aws.amazon.com/cli/latest/reference/wafv2/create-web-acl.html

## AWS CLI associate-web-acl

https://docs.aws.amazon.com/cli/latest/reference/wafv2/associate-web-acl.html

------------------------------------------------------------------------

# 81. Terraform Documentation Links

## WAFv2 Web ACL

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl

## WAFv2 Web ACL Association

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association

## WAFv2 IP Set

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_ip_set

## WAFv2 Regex Pattern Set

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_regex_pattern_set

## WAFv2 Rule Group

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_rule_group

## WAFv2 Logging Configuration

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration

------------------------------------------------------------------------

# 82. Final Architecture Summary

The key WAF architecture is:

``` text
                         INTERNET
                            |
                            v
                     Laptop / Browser
                            |
                           HTTPS
                            |
                            v
                  +-------------------+
                  | CloudFront / ALB  |
                  +---------+---------+
                            |
                            v
                     +-------------+
                     | AWS WAF     |
                     | Web ACL     |
                     +------+------+ 
                            |
                  +---------+---------+
                  |                   |
               BLOCK                ALLOW
                  |                   |
                  v                   v
               HTTP 403          Application
                                      |
                                      v
                                    VPC
                                      |
                                +-----+-----+
                                |           |
                               EC2         RDS
```

The SAA-C03 mental model is:

``` text
AWS WAF
   =
Web ACL
   +
Rules
   +
Rule Statements
   +
Rule Groups
   +
Managed Rules
   +
Actions
   +
Priority
   +
Default Action
   +
Logging / Metrics
```

The most important service distinction is:

``` text
AWS WAF
    |
    +--> Protect web applications

AWS Client VPN
    |
    +--> Connect remote users/devices to private networks

AWS Site-to-Site VPN
    |
    +--> Connect networks

AWS Direct Connect
    |
    +--> Dedicated connectivity

AWS Network Firewall
    |
    +--> VPC/network traffic inspection

AWS Shield
    |
    +--> DDoS protection
```

AWS WAF can be tested from a laptop, but it does not itself create the
laptop-to-VPC connection. For a private laptop-to-VPC connection, use
Client VPN. For a laptop accessing an HTTP/HTTPS application, place WAF
in front of the application using a supported resource such as an ALB,
CloudFront, or API Gateway.
