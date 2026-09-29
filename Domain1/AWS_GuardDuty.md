# Amazon GuardDuty - Professional Documentation for AWS Solutions Architect Associate (SAA-C03)

## 1. Overview

Amazon GuardDuty is an AWS managed threat detection service. It
continuously analyzes supported AWS data sources and logs, applies
threat intelligence, machine learning, and AWS security expertise, and
produces security findings when it detects suspicious or potentially
malicious activity.

GuardDuty is a **detection service**. It does not replace Security
Groups, Network ACLs, AWS WAF, AWS Network Firewall, IAM controls,
encryption, or patching. A typical security architecture uses GuardDuty
to detect activity and EventBridge, SNS, Lambda, Security Hub, or other
response systems to process the findings.

AWS documentation: https://docs.aws.amazon.com/guardduty/latest/ug/

## 2. SAA-C03 Scope

For SAA-C03, understand GuardDuty primarily as a managed security
monitoring and threat-detection service that:

-   continuously monitors AWS activity for suspicious behavior
-   uses foundational data sources such as CloudTrail management events,
    VPC Flow Logs, and Route 53 Resolver DNS query logs
-   generates findings rather than directly blocking traffic
-   can detect compromised credentials, reconnaissance, unusual API
    behavior, cryptocurrency mining, data exfiltration, and other
    threats
-   can be extended with protection plans for services such as S3, EKS,
    EC2, RDS, Lambda, and other supported workloads
-   integrates with EventBridge for automated response
-   is regional, with a GuardDuty detector in each enabled Region
-   supports centralized administration for multi-account AWS
    Organizations environments

AWS states that when GuardDuty is enabled, it automatically begins
ingesting foundational data sources associated with the account.
Additional protection plans are enabled separately when required.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html

## 3. Core GuardDuty Architecture

``` text
                         AWS ACCOUNT / REGION

   CloudTrail Management Events
              |
   VPC Flow Logs  -----------+
              |              |
   Route 53 Resolver DNS ----+----> Amazon GuardDuty Detector
                             |              |
                             |              +--> Threat Intelligence
                             |              +--> Machine Learning
                             |              +--> Anomaly Detection
                             |              +--> AWS Security Expertise
                             |              |
                             |              v
                             |        GuardDuty Findings
                             |              |
                             |              v
                             |        Amazon EventBridge
                             |          /       |       \
                             |         /        |        \
                            SNS     Lambda   Security Hub  SIEM
```

GuardDuty can also analyze additional data and signals when the
corresponding protection plans are enabled, including S3 CloudTrail data
events, EKS audit logs, RDS login activity, EBS volumes, Runtime
Monitoring, and Lambda network activity logs.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html

## 4. GuardDuty Foundational Data Sources

  -----------------------------------------------------------------------
  Data source             What GuardDuty uses it  SAA-C03 point
                          for                     
  ----------------------- ----------------------- -----------------------
  AWS CloudTrail          Detects suspicious AWS  Foundational source
  management events       API and account         
                          activity                

  Amazon VPC Flow Logs    Analyzes network        No packet payload
                          traffic metadata for    inspection
                          supported EC2 threat    
                          detection               

  Route 53 Resolver DNS   Detects suspicious DNS  Foundational source
  query logs              activity                

  S3 CloudTrail data      Object-level S3         Additional protection
  events                  activity when S3        plan
                          Protection is enabled   

  EKS audit logs          Kubernetes API activity Additional protection
                          when EKS Protection is  plan
                          enabled                 

  RDS login activity      Suspicious database     Additional protection
                          login behavior when RDS plan
                          Protection is enabled   

  EBS volumes             Malware scanning for    Additional protection
                          supported EC2 workflows capability

  Runtime events          OS, network, and file   Runtime Monitoring
                          activity for supported  
                          workloads               
  -----------------------------------------------------------------------

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html

## 5. GuardDuty Detector

A GuardDuty detector represents GuardDuty for an AWS account in a
Region.

Important properties:

-   You can have one detector per account per Region.
-   You must create or enable GuardDuty in each Region where you want
    detection.
-   GuardDuty is therefore a regional service from an operational
    configuration perspective.
-   A finding belongs to a detector and Region.
-   Multi-account environments can use a delegated GuardDuty
    administrator account to manage member accounts.

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/guardduty/create-detector.html

AWS quota documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_limits.html

## 6. GuardDuty Findings

A GuardDuty finding is a notification that GuardDuty detected an
indication of suspicious or malicious activity.

A finding normally contains information such as:

-   finding type
-   severity
-   affected AWS resource
-   account ID
-   Region
-   timestamps
-   remote IP information where applicable
-   action and network details
-   threat intelligence context
-   finding ID
-   resource details

Findings can be viewed in the GuardDuty console or retrieved through the
API/CLI.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings.html

Finding types:
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-active.html

## 7. Finding Severity

GuardDuty findings are classified by severity. For architecture and
incident response, treat severity as an indicator of the potential
security impact and urgency, not as proof that an attack succeeded.

A production architecture should route important findings to an
operational response path rather than relying only on the GuardDuty
console.

## 8. GuardDuty Standard Capabilities vs Protection Plans

  -----------------------------------------------------------------------
  Capability              Purpose                 Configuration
  ----------------------- ----------------------- -----------------------
  Foundational threat     Monitors core AWS       Enabled with GuardDuty
  detection               activity                

  S3 Protection           Detects suspicious S3   Enable protection plan
                          object-level activity   

  EKS Protection          Analyzes EKS audit      Enable protection plan
                          activity                

  Runtime Monitoring      Detects runtime         Enable and configure
                          activity on supported   
                          workloads               

  Malware Protection for  Scans supported EBS     Configure protection
  EC2                     volumes associated with 
                          findings                

  Malware Protection for  Scans newly uploaded S3 Configure per bucket
  S3                      objects for malware     

  RDS Protection          Detects suspicious      Enable protection plan
                          RDS/Aurora login        
                          activity                

  Lambda Protection       Analyzes Lambda network Enable protection plan
                          activity                
  -----------------------------------------------------------------------

AWS documentation: https://docs.aws.amazon.com/guardduty/latest/ug/

## 9. GuardDuty vs Other AWS Security Services

  ---------------------------------------------------------------------------
  Service           Primary function    Prevents/blocks?   Typical SAA-C03
                                                           use
  ----------------- ------------------- ------------------ ------------------
  GuardDuty         Threat detection    No, primarily      Detect compromised
                                        detects            resources,
                                                           credentials,
                                                           suspicious
                                                           activity

  AWS WAF           Web application     Yes                Block malicious
                    filtering                              HTTP/HTTPS
                                                           requests

  AWS Shield        DDoS protection     Yes/mitigates DDoS Protect
                                                           internet-facing
                                                           resources

  Security Group    Instance/resource   Yes                Allow/deny traffic
                    network firewall                       at resource level

  Network ACL       Subnet-level        Yes                Allow/deny subnet
                    stateless firewall                     traffic

  AWS Network       Managed network     Yes                Stateful network
  Firewall          firewall                               inspection and
                                                           filtering

  IAM               Authentication and  Yes                Control
                    authorization                          API/resource
                                                           permissions

  Security Hub      Central security    No                 Aggregate security
                    posture/findings                       findings and
                    aggregation                            standards

  Amazon Inspector  Vulnerability       No                 Find
                    management                             software/package
                                                           vulnerabilities

  Macie             Sensitive data      No                 Discover and
                    discovery                              classify sensitive
                                                           S3 data
  ---------------------------------------------------------------------------

## 10. Important Architecture Distinction

GuardDuty is not a firewall.

For example:

``` text
Internet
   |
   v
ALB / CloudFront
   |
   +---- AWS WAF  ---> filters web requests
   |
   v
Application
   |
   +---- GuardDuty ---> detects suspicious activity
   |
   +---- Security Group ---> controls allowed network traffic
```

If GuardDuty detects suspicious activity on an EC2 instance, it
generates a finding. An automated response architecture can then use
EventBridge and Lambda or Systems Manager Automation to perform an
approved remediation action.

## 11. Management Console Implementation - Enable GuardDuty

### Step 1 - Sign in

1.  Sign in to the AWS Management Console.
2.  Select the Region in which you want to configure GuardDuty.
3.  Open the Amazon GuardDuty console.

Console: https://console.aws.amazon.com/guardduty/

### Step 2 - Get started

1.  Open GuardDuty.
2.  Choose **Get started** if GuardDuty is not already enabled.
3.  Review the data sources and protection plan configuration.
4.  Enable GuardDuty.

AWS automatically starts foundational threat detection after GuardDuty
is enabled.

### Step 3 - Verify detector status

Open the GuardDuty **Settings** page and verify that the detector is
enabled.

Record the detector ID. You will use it with the AWS CLI and some API
operations.

### Step 4 - Configure finding frequency

For supported configurations, GuardDuty can publish subsequent finding
occurrences at frequencies including:

-   15 minutes
-   1 hour
-   6 hours

Choose the frequency according to your operational requirement.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html

## 12. Console Implementation - Generate Sample Findings

Do not create real malicious activity to test GuardDuty.

AWS provides sample findings specifically for testing.

Steps:

1.  Open GuardDuty.
2.  Choose **Settings**.
3.  Locate **Sample findings**.
4.  Choose **Generate sample findings**.
5.  Open **Findings**.
6.  Look for findings with the `[SAMPLE]` prefix.

Sample findings are simulated and use placeholder values. They are
suitable for validating dashboards, EventBridge rules, filters, and
operational workflows.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/sample_findings.html

## 13. Console Implementation - Enable S3 Protection

S3 Protection analyzes CloudTrail data events for S3 object-level API
activity.

Steps:

1.  Open GuardDuty.
2.  Select the required Region.
3.  Open **S3 Protection** or the protection-plan configuration.
4.  Choose **Enable**.
5.  Confirm the configuration.
6.  Verify that S3 Protection shows as enabled.

Important distinction:

-   CloudTrail management events and S3 data events are different.
-   S3 Protection uses S3 CloudTrail data events for object-level
    activity.
-   You do not have to separately configure CloudTrail S3 data-event
    logging just to use GuardDuty S3 Protection.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/s3-protection.html

## 14. Console Implementation - EKS Protection

For an EKS environment:

1.  Open GuardDuty.
2.  Select the Region containing the EKS cluster.
3.  Open **Protection plans**.
4.  Select **EKS Protection**.
5.  Enable the feature.
6.  Verify that EKS audit-log monitoring is active.

GuardDuty then monitors supported EKS audit activity for potential
threats.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/eks-protection-enable-standalone-account.html

## 15. Console Implementation - Runtime Monitoring

Runtime Monitoring provides additional visibility into runtime activity
for supported workloads.

High-level process:

1.  Open GuardDuty.
2.  Select **Runtime Monitoring**.
3.  Review supported resource and platform prerequisites.
4.  Enable Runtime Monitoring.
5.  Configure the required runtime components for the workloads you want
    to monitor.
6.  Verify monitoring status.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/runtime-monitoring-configuration.html

## 16. Console Implementation - Malware Protection for S3

This is separate from ordinary S3 Protection.

Malware Protection for S3 scans newly uploaded objects in protected
buckets for malware.

Steps:

1.  Open the GuardDuty console.
2.  Select the Region of the S3 bucket.
3.  Choose **Malware Protection for S3**.
4.  Under protected buckets, choose **Enable**.
5.  Enter or select the S3 bucket.
6.  Configure the required service access/IAM role.
7.  Complete the protection-plan setup.
8.  Verify the bucket appears as protected.

The S3 bucket and GuardDuty configuration must meet the Region
requirements documented by AWS.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/enable-malware-protection-s3-bucket.html

## 17. Console Implementation - EventBridge Alerting

GuardDuty automatically publishes findings to Amazon EventBridge.

Architecture:

``` text
GuardDuty Finding
       |
       v
Amazon EventBridge Rule
       |
       +------> SNS ------> Email/SMS integrations
       |
       +------> Lambda ---> Automated response
       |
       +------> SQS ------> Queue / workflow
       |
       +------> Step Functions / other supported target
```

Console process:

1.  Open Amazon EventBridge.
2.  Choose **Rules**.
3.  Choose **Create rule**.
4.  Give the rule a name.
5.  Select the default event bus.
6.  Configure an event pattern for GuardDuty findings.
7.  Example source: `aws.guardduty`.
8.  Add a target such as SNS or Lambda.
9.  Configure required permissions.
10. Create the rule.
11. Generate GuardDuty sample findings.
12. Verify that the EventBridge target receives the event.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings_eventbridge.html

## 18. AWS CLI Prerequisites

Configure AWS CLI credentials and a default Region with permissions to
use GuardDuty.

``` bash
aws configure
aws sts get-caller-identity
aws configure get region
```

Use the Region explicitly when learning or when working across multiple
Regions.

## 19. CLI - Check Existing Detector

``` bash
aws guardduty list-detectors --region ap-south-1
```

If a detector exists, retrieve its configuration:

``` bash
aws guardduty get-detector \
  --detector-id <DETECTOR_ID> \
  --region ap-south-1
```

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/guardduty/list-detectors.html

## 20. CLI - Create and Enable GuardDuty

Create a detector:

``` bash
aws guardduty create-detector \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES \
  --region ap-south-1
```

Save the returned detector ID.

Verify it:

``` bash
aws guardduty list-detectors --region ap-south-1
```

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/guardduty/create-detector.html

## 21. CLI - Update GuardDuty

To enable or change detector settings:

``` bash
aws guardduty update-detector \
  --detector-id <DETECTOR_ID> \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES \
  --region ap-south-1
```

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/guardduty/update-detector.html

## 22. CLI - Enable S3 Protection

``` bash
aws guardduty update-detector \
  --detector-id <DETECTOR_ID> \
  --region ap-south-1 \
  --features '[{"Name":"S3_DATA_EVENTS","Status":"ENABLED"}]'
```

Verify:

``` bash
aws guardduty get-detector \
  --detector-id <DETECTOR_ID> \
  --region ap-south-1
```

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/data-source-configure.html

## 23. CLI - Generate Sample Findings

Generate all supported sample findings:

``` bash
aws guardduty create-sample-findings \
  --detector-id <DETECTOR_ID> \
  --region ap-south-1
```

Generate one specific sample finding:

``` bash
aws guardduty create-sample-findings \
  --detector-id <DETECTOR_ID> \
  --finding-types Backdoor:EC2/DenialOfService.Tcp \
  --region ap-south-1
```

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/guardduty/create-sample-findings.html

## 24. CLI - List Findings

``` bash
aws guardduty list-findings \
  --detector-id <DETECTOR_ID> \
  --region ap-south-1
```

Sort/filter findings using the documented `--finding-criteria` and
`--sort-criteria` options.

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/guardduty/list-findings.html

## 25. CLI - Retrieve Finding Details

``` bash
aws guardduty get-findings \
  --detector-id <DETECTOR_ID> \
  --finding-ids <FINDING_ID> \
  --region ap-south-1
```

AWS CLI documentation:
https://docs.aws.amazon.com/cli/latest/reference/guardduty/get-findings.html

## 26. CLI - Malware Protection for S3

For Malware Protection for S3, AWS provides a CLI workflow based on
`create-malware-protection-plan`.

Example form:

``` bash
aws guardduty create-malware-protection-plan \
  --role arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME> \
  --protected-resource 'S3Bucket={BucketName=<BUCKET_NAME>}' \
  --region ap-south-1
```

The IAM role must have the permissions required by the GuardDuty malware
protection workflow.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/enable-malware-protection-s3-bucket.html

## 27. Terraform - Basic GuardDuty Detector

Use the AWS provider.

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

resource "aws_guardduty_detector" "main" {
  enable                     = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

output "guardduty_detector_id" {
  value = aws_guardduty_detector.main.id
}
```

The current Terraform AWS provider documentation supports
`aws_guardduty_detector` for managing a GuardDuty detector. Newer
configurations should prefer the separate
`aws_guardduty_detector_feature` resource for individual detector
features rather than relying on deprecated data-source configuration
blocks.

Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector

## 28. Terraform - Enable S3 Protection

``` hcl
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

resource "aws_guardduty_detector_feature" "s3_protection" {
  detector_id = aws_guardduty_detector.main.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}
```

Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature

## 29. Terraform - EKS Protection

The exact feature names and additional configuration depend on the
current GuardDuty provider version and the AWS feature being configured.
Verify the provider schema before applying production configuration.

Example pattern:

``` hcl
resource "aws_guardduty_detector_feature" "eks_protection" {
  detector_id = aws_guardduty_detector.main.id
  name        = "EKS_AUDIT_LOGS"
  status      = "ENABLED"
}
```

Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature

## 30. Terraform Workflow

``` bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Verify the detector:

``` bash
aws guardduty list-detectors --region ap-south-1
```

Verify the Terraform state:

``` bash
terraform state list
```

## 31. Terraform - Existing GuardDuty Detector

If GuardDuty is already enabled manually, do not blindly create another
detector. GuardDuty permits one detector per account per Region.

First retrieve the detector ID:

``` bash
aws guardduty list-detectors --region ap-south-1
```

Then import it into Terraform:

``` bash
terraform import aws_guardduty_detector.main <DETECTOR_ID>
```

Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector

## 32. Terraform - Custom Threat Intelligence IP Set

GuardDuty supports custom IP sets. Terraform provides
`aws_guardduty_ipset` for managing them.

Example:

``` hcl
resource "aws_guardduty_ipset" "trusted_or_custom_ips" {
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "https://s3.amazonaws.com/<BUCKET>/<KEY>"
  name        = "custom-ip-set"
}
```

Use the exact S3 access model and permissions required by the current
AWS GuardDuty documentation before using this in production.

Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_ipset

## 33. Terraform - Threat Intelligence Set

A ThreatIntelSet lets GuardDuty use a custom list of known malicious IP
addresses/domains according to the supported GuardDuty model.

Example resource pattern:

``` hcl
resource "aws_guardduty_threatintelset" "custom" {
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "https://s3.amazonaws.com/<BUCKET>/<KEY>"
  name        = "custom-threat-intel"
}
```

Terraform documentation:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_threatintelset

## 34. EventBridge Automation Pattern

For production environments, a common pattern is:

``` text
AWS Resources
     |
     v
GuardDuty
     |
     v
Finding
     |
     v
EventBridge Rule
     |
     +------> SNS notification
     |
     +------> Lambda response
     |
     +------> Systems Manager Automation
     |
     +------> Security operations / SIEM
```

The response action must be designed carefully. GuardDuty detects the
condition; the downstream automation decides what action to perform.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings_eventbridge.html

## 35. EventBridge Example CLI

Create a rule for GuardDuty findings:

``` bash
aws events put-rule \
  --name guardduty-findings \
  --event-pattern '{"source":["aws.guardduty"],"detail-type":["GuardDuty Finding"]}' \
  --region ap-south-1
```

A severity-based example:

``` bash
aws events put-rule \
  --name guardduty-high-severity \
  --event-pattern '{"source":["aws.guardduty"],"detail-type":["GuardDuty Finding"],"detail":{"severity":[5,8]}}' \
  --region ap-south-1
```

Add a target according to your architecture, such as SNS or Lambda.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings_eventbridge.html

## 36. Console vs CLI vs Terraform

  ---------------------------------------------------------------------------
  Area              Management        AWS CLI           Terraform
                    Console                             
  ----------------- ----------------- ----------------- ---------------------
  Initial           Fast interactive  Scriptable        Infrastructure as
  enablement        setup                               code

  Repeatability     Low to medium     High              Very high

  Change history    Console/audit     Script/Git if     Git + state
                    dependent         stored            

  Multi-Region      Repeat manually   Script across     Provider
                                      Regions           aliases/modules

  CI/CD             Limited           Strong            Strong

  Existing resource Manual management Direct API        `terraform import`
  import                              operations        

  Best use          Learning, one-off Automation and    Standardized
                    configuration     operations        infrastructure

  Risk              Manual drift      Script mistakes   Incorrect
                                                        state/configuration
  ---------------------------------------------------------------------------

## 37. Multi-Region GuardDuty Design

Because GuardDuty detectors are regional, decide which AWS Regions
require monitoring.

Example:

``` text
AWS Account
 |
 +-- ap-south-1
 |      +-- GuardDuty Detector
 |
 +-- us-east-1
 |      +-- GuardDuty Detector
 |
 +-- eu-west-1
        +-- GuardDuty Detector
```

For a multi-Region architecture, standardize GuardDuty configuration
with Terraform modules or an organizational security-management
approach.

## 38. Multi-Account GuardDuty Design

For AWS Organizations environments, a delegated GuardDuty administrator
can centrally manage GuardDuty configuration and findings for member
accounts.

Conceptual architecture:

``` text
AWS Organization
       |
       v
GuardDuty Delegated Administrator
       |
       +---- Security Account
       |
       +---- Production Account
       |
       +---- Development Account
       |
       +---- Data Account
```

The administrator account can use EventBridge and other services to
centralize security operations.

## 39. GuardDuty Finding Retention and EventBridge

GuardDuty stores findings for a limited period. AWS documents a 90-day
finding retention period. For longer retention or downstream analysis,
findings can be routed through EventBridge to other services or storage
systems.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings_eventbridge.html

## 40. What GuardDuty Does Not Do

  Requirement                      GuardDuty              Correct AWS service/pattern
  -------------------------------- ---------------------- -----------------------------
  Block a malicious HTTP request   No                     AWS WAF
  Allow/deny EC2 network traffic   No                     Security Group
  Subnet stateless filtering       No                     Network ACL
  Stateful network firewall        No                     AWS Network Firewall
  DDoS mitigation                  Not its primary role   AWS Shield
  Vulnerability scanning           No                     Amazon Inspector
  Sensitive data discovery         No                     Amazon Macie
  Identity authorization           No                     AWS IAM
  Detect suspicious AWS activity   Yes                    Amazon GuardDuty

## 41. GuardDuty and CloudTrail

GuardDuty uses CloudTrail management events as a foundational data
source.

Do not confuse these two services:

  -----------------------------------------------------------------------
  Service                             Function
  ----------------------------------- -----------------------------------
  CloudTrail                          Records AWS API activity for
                                      auditing and governance

  GuardDuty                           Analyzes supported signals and
                                      detects suspicious activity

  EventBridge                         Routes events and findings to
                                      targets

  Security Hub                        Aggregates and manages security
                                      findings/posture
  -----------------------------------------------------------------------

GuardDuty does not mean CloudTrail becomes unnecessary. CloudTrail
remains important for audit, governance, investigation, and historical
API activity.

## 42. GuardDuty and VPC Flow Logs

VPC Flow Logs provide network traffic metadata. GuardDuty can use VPC
Flow Logs as a foundational signal for EC2-related threat detection.

Do not describe GuardDuty as a packet-capture service. VPC Flow Logs
contain flow metadata rather than full packet payloads.

## 43. GuardDuty and S3 Protection

S3 Protection is important because standard CloudTrail management events
do not provide the same object-level visibility as S3 data events.

  -----------------------------------------------------------------------
  Monitoring                          Example visibility
  ----------------------------------- -----------------------------------
  CloudTrail management events        Bucket-level/control-plane API
                                      activity

  GuardDuty S3 Protection             Object-level S3 activity through
                                      CloudTrail data events

  Malware Protection for S3           Malware scanning of newly uploaded
                                      objects in protected buckets
  -----------------------------------------------------------------------

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/s3-protection.html

## 44. Safe Testing Strategy

Use GuardDuty sample findings for demonstrations and integration
testing.

Recommended lab sequence:

1.  Enable GuardDuty.
2.  Record detector ID.
3.  Generate sample findings.
4.  View findings.
5.  Create EventBridge rule.
6.  Route findings to SNS or Lambda.
7.  Generate sample findings again.
8.  Verify downstream delivery.
9.  Test filters and severity conditions.
10. Remove lab resources after validation.

Avoid deliberately generating malicious network traffic, credential
abuse, port scans against production assets, or malware-like behavior
merely to test detection.

AWS documentation:
https://docs.aws.amazon.com/guardduty/latest/ug/sample_findings.html

## 45. Troubleshooting

### GuardDuty is not showing findings

Check:

1.  GuardDuty is enabled in the correct Region.
2.  The detector exists.
3.  The workload is in the Region being monitored.
4.  The required protection plan is enabled.
5.  You are not expecting a protection plan's finding from foundational
    monitoring alone.
6.  Generate sample findings to verify the console and downstream
    pipeline.

### CLI cannot find detector

Run:

``` bash
aws guardduty list-detectors --region ap-south-1
```

If no detector is returned, create one in that Region.

### Terraform tries to create a duplicate detector

GuardDuty permits one detector per account per Region. Import the
existing detector instead of creating another.

### EventBridge does not trigger

Check:

-   Event pattern
-   Region
-   event bus
-   target ARN
-   target permissions
-   Lambda resource policy if Lambda is the target
-   SNS subscription confirmation where applicable
-   sample finding generation

## 46. Best Practices

1.  Enable GuardDuty in every Region required by the organization's
    security architecture.
2.  Use centralized administration for multi-account environments.
3.  Enable relevant protection plans based on workload type.
4.  Use EventBridge for operational response and alerting.
5.  Route high-value findings to security operations tooling.
6.  Use sample findings for testing instead of generating malicious
    activity.
7.  Keep CloudTrail enabled for audit and investigation.
8.  Do not treat GuardDuty as a replacement for preventive controls.
9.  Manage repeatable configurations through Terraform where
    appropriate.
10. Regularly review GuardDuty findings, suppression rules, and
    downstream response workflows.

## 47. SAA-C03 Architecture Decision Table

  Scenario                                               Service to remember
  ------------------------------------------------------ ---------------------
  Detect compromised EC2 behavior                        GuardDuty
  Detect suspicious API activity                         GuardDuty
  Analyze AWS activity for threats                       GuardDuty
  Record API calls                                       CloudTrail
  Detect vulnerable packages                             Inspector
  Protect web application from malicious HTTP requests   WAF
  Protect against DDoS                                   Shield
  Aggregate security findings                            Security Hub
  Discover sensitive data in S3                          Macie
  Control permissions                                    IAM
  Filter subnet traffic                                  NACL
  Filter instance-level traffic                          Security Group
  Inspect/filter network traffic centrally               Network Firewall

## 48. SAA-C03 Exam Points to Memorize

### GuardDuty

**Managed threat detection service.**

### CloudTrail

**API activity and audit logging.**

### VPC Flow Logs

**Network flow metadata.**

### GuardDuty findings

**Security detections that indicate potentially suspicious or malicious
activity.**

### EventBridge

**Routes GuardDuty findings to targets for notification or automated
response.**

### S3 Protection

**Uses S3 CloudTrail data events for object-level activity monitoring.**

### Regional behavior

**GuardDuty detector is regional and one detector is allowed per account
per Region.**

### GuardDuty vs WAF

**GuardDuty detects threats; WAF filters web requests.**

### GuardDuty vs Inspector

**GuardDuty detects suspicious activity; Inspector assesses
vulnerabilities.**

### GuardDuty vs CloudTrail

**CloudTrail records API activity; GuardDuty analyzes supported signals
for threats.**

## 49. Official AWS Documentation Links

### GuardDuty

-   What is Amazon GuardDuty:
    https://docs.aws.amazon.com/guardduty/latest/ug/
-   Getting started:
    https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html
-   GuardDuty findings:
    https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings.html
-   Finding types:
    https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-active.html
-   Sample findings:
    https://docs.aws.amazon.com/guardduty/latest/ug/sample_findings.html
-   S3 Protection:
    https://docs.aws.amazon.com/guardduty/latest/ug/s3-protection.html
-   EKS Protection:
    https://docs.aws.amazon.com/guardduty/latest/ug/eks-protection-enable-standalone-account.html
-   Runtime Monitoring:
    https://docs.aws.amazon.com/guardduty/latest/ug/runtime-monitoring-configuration.html
-   Malware Protection for S3:
    https://docs.aws.amazon.com/guardduty/latest/ug/enable-malware-protection-s3-bucket.html
-   EventBridge integration:
    https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings_eventbridge.html
-   GuardDuty quotas:
    https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_limits.html

### AWS CLI

-   GuardDuty CLI examples:
    https://docs.aws.amazon.com/cli/latest/userguide/cli_guardduty_code_examples.html
-   create-detector:
    https://docs.aws.amazon.com/cli/latest/reference/guardduty/create-detector.html
-   list-detectors:
    https://docs.aws.amazon.com/cli/latest/reference/guardduty/list-detectors.html
-   update-detector:
    https://docs.aws.amazon.com/cli/latest/reference/guardduty/update-detector.html
-   create-sample-findings:
    https://docs.aws.amazon.com/cli/latest/reference/guardduty/create-sample-findings.html
-   list-findings:
    https://docs.aws.amazon.com/cli/latest/reference/guardduty/list-findings.html
-   get-findings:
    https://docs.aws.amazon.com/cli/latest/reference/guardduty/get-findings.html

### Terraform AWS Provider

-   aws_guardduty_detector:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector
-   aws_guardduty_detector_feature:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature
-   aws_guardduty_ipset:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_ipset
-   aws_guardduty_threatintelset:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_threatintelset
-   GuardDuty provider resources:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs

## 50. Final SAA-C03 Mental Model

``` text
                 AWS ENVIRONMENT
                        |
       +----------------+----------------+
       |                |                |
   CloudTrail       VPC Flow Logs     DNS Logs
       |                |                |
       +----------------+----------------+
                        |
                        v
                AMAZON GUARDDUTY
                        |
              Threat Detection Engine
                        |
                        v
                    FINDING
                        |
                        v
                 EVENTBRIDGE
                  /    |     \
                 /     |      \
               SNS   Lambda   Security Hub / SIEM
```

The SAA-C03 decision is straightforward:

**Need to detect suspicious activity in AWS? Think GuardDuty.**

**Need to record API activity? Think CloudTrail.**

**Need to block malicious web requests? Think AWS WAF.**

**Need DDoS protection? Think AWS Shield.**

**Need vulnerability assessment? Think Amazon Inspector.**

**Need centralized security findings and posture management? Think AWS
Security Hub.**

GuardDuty is the detection layer in this architecture. It produces
findings; other services and automation can be used to notify,
investigate, or respond.
