# AWS EC2 Auto Scaling and Related Services

## SAA-C03 Professional Documentation

## 1. Overview

Amazon EC2 Auto Scaling automatically maintains the correct number of
EC2 instances for an application. An Auto Scaling group (ASG) defines
the minimum, desired, and maximum capacity and can replace unhealthy
instances, distribute capacity across Availability Zones, and
dynamically change capacity using scaling policies. AWS recommends
Launch Templates for modern Auto Scaling configurations. [AWS: What is
Amazon EC2 Auto
Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)

### Core architecture

``` text
                         Internet
                            |
                       Route 53 / DNS
                            |
                       ALB / ELB
                    /       |       \
                   /        |        \
                 AZ-a      AZ-b      AZ-c
                  |          |          |
               EC2-A      EC2-B      EC2-C
                  \          |          /
                   \         |         /
                    Auto Scaling Group
                            |
                    Launch Template
```

An ASG is not a load balancer. The ASG manages EC2 capacity; Elastic
Load Balancing distributes requests and performs load-balancer health
checks when configured. Auto Scaling automatically registers and
deregisters instances with an attached load balancer. [AWS: Auto Scaling
and load
balancing](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-load-balancer.html)

------------------------------------------------------------------------

# 2. SAA-C03 Scope

The most important SAA-C03 concepts are:

-   EC2 instance scaling
-   Horizontal vs vertical scaling
-   Elasticity
-   Auto Scaling groups
-   Launch Templates
-   Multi-AZ deployment
-   ELB integration
-   EC2 and ELB health checks
-   Target tracking scaling
-   Step scaling
-   Scheduled scaling
-   Predictive scaling
-   Mixed instances and Spot Instances
-   Capacity Rebalancing
-   Lifecycle hooks
-   Instance refresh
-   Warm pools
-   Scale-in protection
-   Termination policies
-   CloudWatch metrics and alarms
-   High availability and fault tolerance
-   Desired/minimum/maximum capacity
-   Instance warmup
-   Disaster recovery implications

AWS's SAA-C03 architecture questions commonly test which component
should provide availability, scaling, health checking, or traffic
distribution rather than treating these as one feature.

------------------------------------------------------------------------

# 3. Scalability, Elasticity, Availability

  -----------------------------------------------------------------------
  Concept                 Meaning                 Typical AWS
                                                  implementation
  ----------------------- ----------------------- -----------------------
  Vertical scaling        Increase size of one    Change EC2 instance
                          server                  type

  Horizontal scaling      Add/remove servers      EC2 Auto Scaling

  Elasticity              Automatically adjust    ASG + scaling policy
                          capacity to demand      

  High availability       Continue operating      Multi-AZ ASG + ALB
                          after component failure 

  Fault tolerance         Continue operation with Redundant components
                          little/no interruption  and carefully designed
                          after failure           failover

  Load balancing          Distribute requests     ALB/NLB

  Self-healing            Replace unhealthy       ASG health checks
                          capacity                
  -----------------------------------------------------------------------

For SAA-C03, when an application must automatically add instances during
increasing demand and remove them when demand decreases, EC2 Auto
Scaling is usually the central service.

------------------------------------------------------------------------

# 4. Auto Scaling Group Fundamentals

Every ASG has:

-   Minimum capacity
-   Desired capacity
-   Maximum capacity

Example:

``` text
Minimum = 2
Desired = 2
Maximum = 6
```

The ASG initially launches enough instances to satisfy desired capacity
and keeps the group within the configured minimum and maximum limits. If
an instance becomes unhealthy, the ASG can terminate it and launch a
replacement. [AWS: Auto Scaling
groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html)

### Capacity behavior

``` text
Demand increases
      |
      v
Scale out
      |
Desired capacity increases
      |
New EC2 instances launch

Demand decreases
      |
      v
Scale in
      |
Desired capacity decreases
      |
EC2 instances terminate
```

### Example

``` text
Min:     2
Desired: 3
Max:     8
```

If CPU utilization remains high and the target tracking policy requires
another instance:

``` text
3 -> 4
```

If demand later falls:

``` text
4 -> 3 -> 2
```

The group never intentionally scales below 2 or above 8 through normal
dynamic scaling.

------------------------------------------------------------------------

# 5. Launch Templates

A Launch Template defines how EC2 instances should be launched. It can
include:

-   AMI
-   Instance type
-   Key pair
-   Security groups
-   Network configuration
-   EBS volumes
-   User data
-   IAM instance profile
-   Metadata options
-   Tags

Launch Templates support versions, allowing an ASG to use a selected
version. AWS recommends Launch Templates over legacy Launch
Configurations. [AWS: Launch
Templates](https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-templates.html)

### Launch Template vs Launch Configuration

  Feature                   Launch Template   Launch Configuration
  ------------------------- ----------------- ----------------------
  Modern choice             Yes               Legacy
  Versioning                Yes               No
  Multiple instance types   Supported         Limited/legacy model
  Mixed purchase options    Supported         No
  New EC2 capabilities      Better support    Limited
  SAA-C03 recommendation    Prefer            Know as legacy

AWS documents Launch Configurations mainly for customers who have not
migrated. [AWS: Launch
Configurations](https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-configurations.html)

------------------------------------------------------------------------

# 6. Auto Scaling Health Checks

An ASG can use EC2 health checks and, when attached to a load balancer,
ELB health checks.

  -----------------------------------------------------------------------
  Health check                        Detects
  ----------------------------------- -----------------------------------
  EC2 health check                    Instance/underlying EC2 health
                                      failure

  ELB health check                    Application availability through
                                      load balancer target health
  -----------------------------------------------------------------------

For an application behind an ALB, enabling ELB health checks is
important because an instance can be running while its application is
unhealthy.

Example:

``` text
EC2 status: running
Application: crashed
ALB health: unhealthy
       |
       v
ASG replaces instance
```

AWS documents that custom/application health checks can be used in
addition to built-in checks. [AWS: EC2 Auto Scaling health
checks](https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-health-checks.html)

------------------------------------------------------------------------

# 7. Availability Zones

For high availability, distribute an ASG across multiple Availability
Zones.

``` text
                 Auto Scaling Group
                  Min = 2
                     |
          +----------+----------+
          |                     |
        AZ-a                  AZ-b
          |                     |
       EC2-1                 EC2-2
```

If AZ-a becomes unavailable, capacity in AZ-b can continue serving
traffic. The ASG attempts to maintain balance across the enabled
Availability Zones. [AWS: Auto Scaling
groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html)

### SAA-C03 rule

Do not place all instances in one Availability Zone when the requirement
is high availability.

------------------------------------------------------------------------

# 8. Elastic Load Balancing + Auto Scaling

Recommended web architecture:

``` text
Client
  |
  v
Application Load Balancer
  |
  +----------+----------+
  |                     |
 AZ-a                  AZ-b
  |                     |
 EC2                   EC2
  |                     |
 +----------+----------+
            |
      Auto Scaling Group
```

The ALB distributes HTTP/HTTPS traffic. The ASG maintains EC2 capacity.
The target group performs health checks. [AWS: Auto Scaling with load
balancing](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-load-balancer.html)

------------------------------------------------------------------------

# 9. Scaling Policy Types

AWS EC2 Auto Scaling supports dynamic scaling through target tracking,
step scaling, and simple scaling, plus scheduled and predictive
approaches. AWS strongly recommends target tracking for many common
dynamic scaling scenarios. [AWS: Dynamic
scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scale-based-on-demand.html)

  -----------------------------------------------------------------------
  Policy                  How it works            SAA-C03 use
  ----------------------- ----------------------- -----------------------
  Target tracking         Maintain a target       Default choice for
                          metric                  common workloads

  Step scaling            Different adjustments   Precise
                          for alarm breach sizes  thresholds/actions

  Simple scaling          Single adjustment with  Legacy/simple cases
                          cooldown                

  Scheduled scaling       Capacity changes at     Predictable schedules
                          known times             

  Predictive scaling      Forecast demand         Recurring load patterns
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 10. Target Tracking Scaling

Target tracking attempts to maintain a selected target value, such as
average CPU utilization.

Example:

``` text
Target CPU = 50%

CPU > target
   |
   v
Scale out

CPU < target
   |
   v
Scale in
```

AWS automatically creates and manages CloudWatch alarms for target
tracking. [AWS: Target
tracking](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html)

Common predefined metrics include:

-   ASGAverageCPUUtilization
-   ASGAverageNetworkIn
-   ASGAverageNetworkOut
-   ALBRequestCountPerTarget

A useful web workload policy is often:

``` text
ALBRequestCountPerTarget
```

rather than CPU alone, when request volume is the better measure of
application load.

------------------------------------------------------------------------

# 11. Step Scaling

Step scaling uses different adjustments based on the magnitude of an
alarm breach.

Example:

  CPU      Action
  -------- --------------
  50-70%   +1 instance
  70-85%   +2 instances
  \>85%    +3 instances

This provides more explicit control than target tracking.

AWS CLI uses `put-scaling-policy` to create or update scaling policies.
[AWS CLI:
put-scaling-policy](https://docs.aws.amazon.com/cli/latest/reference/autoscaling/put-scaling-policy.html)

------------------------------------------------------------------------

# 12. Scheduled Scaling

Use scheduled scaling when demand is predictable.

Example:

``` text
08:00 -> scale to 6
20:00 -> scale to 2
```

Typical examples:

-   Business hours
-   Batch windows
-   Scheduled events
-   Known daily traffic patterns

Scheduled scaling does not replace dynamic scaling when unexpected
demand can occur.

------------------------------------------------------------------------

# 13. Predictive Scaling

Predictive scaling uses historical load data to forecast future demand
and proactively adjust capacity. It is appropriate when the workload has
recurring patterns.

Reference:

https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive.html

------------------------------------------------------------------------

# 14. Instance Warmup

When an instance launches, it may require time before it contributes
useful capacity.

Examples:

-   Application startup
-   Container startup
-   Cache initialization
-   Configuration retrieval
-   Package installation

Configure an appropriate default instance warmup so scaling decisions do
not react too aggressively to instances that are not ready.

------------------------------------------------------------------------

# 15. Scale-In Behavior

Scale-in removes capacity when demand decreases.

Potential termination selection is affected by the Auto Scaling group's
termination policy and availability-zone balancing requirements.

For workloads requiring protection from termination, use:

-   Scale-in protection
-   Lifecycle hooks
-   Appropriate termination policies
-   External state storage

Do not store important application state only on an ephemeral EC2
instance when automatic termination is expected.

------------------------------------------------------------------------

# 16. Mixed Instances and Spot Instances

An ASG can use multiple instance types and purchasing options through a
Launch Template and mixed instances policy.

Example:

``` text
ASG
 |
 +-- On-Demand
 |    m7i.large
 |
 +-- Spot
      m7i.large
      m6i.large
      c7i.large
```

Spot Instances reduce cost but can be interrupted. Capacity Rebalancing
can proactively replace Spot Instances at elevated interruption risk.
[AWS: Capacity
Rebalancing](https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-capacity-rebalancing.html)

------------------------------------------------------------------------

# 17. Lifecycle Hooks

Lifecycle hooks pause instances during launch or termination so custom
actions can run.

Example launch flow:

``` text
Pending
  |
  v
Pending:Wait
  |
  | bootstrap/configuration
  v
Pending:Proceed
  |
  v
InService
```

Example termination flow:

``` text
InService
   |
   v
Terminating:Wait
   |
   | save logs / deregister / cleanup
   v
Terminating:Proceed
   |
   v
Terminated
```

Lifecycle hooks can integrate with EventBridge, Lambda, SNS, SQS, or
custom actions. [AWS: Lifecycle
hooks](https://docs.aws.amazon.com/autoscaling/ec2/userguide/adding-lifecycle-hooks.html)

------------------------------------------------------------------------

# 18. Instance Refresh

Instance refresh updates existing ASG instances after changing a Launch
Template or AMI.

Typical workflow:

``` text
Old Launch Template
        |
        v
Create new version
        |
        v
Start Instance Refresh
        |
        v
Replace instances gradually
```

Instance refresh supports rolling replacement and can maintain a
configured minimum healthy percentage. [AWS: Instance
refresh](https://docs.aws.amazon.com/autoscaling/ec2/userguide/instance-refresh-overview.html)

------------------------------------------------------------------------

# 19. Warm Pools

A warm pool contains pre-initialized EC2 instances outside the InService
capacity of the ASG. It can reduce scale-out latency for applications
with long startup times. [AWS: Warm
pools](https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html)

``` text
Auto Scaling Group
 |
 +-- InService EC2
 |
 +-- InService EC2
 |
 +-- Warm Pool
      EC2 ready to start
```

------------------------------------------------------------------------

# 20. Related Services

  Service               Role
  --------------------- ---------------------------------------------
  EC2                   Compute capacity
  Auto Scaling          Maintains/scales EC2 capacity
  ALB                   HTTP/HTTPS load balancing
  NLB                   Layer 4 load balancing
  CloudWatch            Metrics, alarms, monitoring
  Route 53              DNS and routing
  Systems Manager       Instance management
  IAM                   Permissions and instance roles
  EBS                   Instance block storage
  S3                    Durable object storage for application data
  RDS                   Managed relational database
  ElastiCache           In-memory application caching
  SNS/SQS/EventBridge   Event-driven integrations

------------------------------------------------------------------------

# 21. Management Console Lab

## Architecture

``` text
Internet
   |
   v
ALB
   |
Target Group
   |
+-----------------------+
| Auto Scaling Group     |
|                       |
| AZ-a      AZ-b        |
| EC2       EC2         |
+-----------------------+
          |
   Launch Template
```

## Lab values

  Resource         Value
  ---------------- ---------------------------------
  Region           `ap-south-1` example
  VPC              Existing/default VPC or lab VPC
  Minimum          2
  Desired          2
  Maximum          4
  Instance type    `t3.micro` example
  Scaling target   50% average CPU
  Application      Nginx

Use your own Region and current AMI ID.

------------------------------------------------------------------------

## Step 1: Create a Security Group

EC2 Console -\> Security Groups -\> Create security group.

Name:

``` text
sg-asg-web
```

Inbound:

  Protocol     Port Source
  ---------- ------ ---------------------------
  HTTP           80 `0.0.0.0/0`
  SSH            22 Your IP only, if required

For a production ALB architecture, preferably expose HTTP/HTTPS on the
ALB security group and allow port 80/443 from the ALB security group on
the instance security group.

------------------------------------------------------------------------

## Step 2: Create Launch Template

EC2 Console -\> Launch Templates -\> Create launch template.

Name:

``` text
lt-web-asg
```

Select:

-   AMI: current Amazon Linux AMI
-   Instance type: `t3.micro` for a small lab
-   Key pair: optional if using Session Manager/user-data only
-   Security group: `sg-asg-web`

User data:

``` bash
#!/bin/bash
set -eux

dnf update -y
dnf install -y nginx

cat > /usr/share/nginx/html/index.html <<'HTML'
<html>
<head><title>EC2 Auto Scaling Demo</title></head>
<body>
<h1>EC2 Auto Scaling Demo</h1>
<p>Served by an EC2 instance in an Auto Scaling Group.</p>
</body>
</html>
HTML

systemctl enable nginx
systemctl start nginx
```

Launch Templates contain AMI, instance type, key pair, security groups,
storage and other launch settings. [AWS: Create Launch
Template](https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-launch-template.html)

------------------------------------------------------------------------

## Step 3: Create Target Group

EC2 Console -\> Target Groups -\> Create target group.

Choose:

``` text
Target type: Instances
Protocol: HTTP
Port: 80
VPC: your VPC
Health check protocol: HTTP
Health check path: /
```

Do not manually register instances when using an ASG. The ASG will
attach instances to the target group.

------------------------------------------------------------------------

## Step 4: Create Application Load Balancer

EC2 Console -\> Load Balancers -\> Create Load Balancer -\> Application
Load Balancer.

Configure:

``` text
Name: alb-web
Scheme: Internet-facing
IP address type: IPv4
```

Select at least two Availability Zones/subnets.

Create an ALB security group allowing:

``` text
HTTP 80 from 0.0.0.0/0
```

Listener:

``` text
HTTP : 80
Forward to: web target group
```

------------------------------------------------------------------------

## Step 5: Create Auto Scaling Group

EC2 Console -\> Auto Scaling Groups -\> Create Auto Scaling group.

Name:

``` text
asg-web
```

Select:

``` text
Launch Template: lt-web-asg
Version: Latest
```

Choose VPC and at least two subnets in different Availability Zones.

Set:

``` text
Desired capacity: 2
Minimum capacity: 2
Maximum capacity: 4
```

Attach the existing target group.

Choose ELB health checks in addition to EC2 health checks.

AWS's console workflow requires a Launch Template, Availability
Zones/subnets, desired capacity, and min/max limits. [AWS: Create an ASG
with a Launch
Template](https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-asg-launch-template.html)

------------------------------------------------------------------------

## Step 6: Add Target Tracking

During ASG creation or afterward, configure automatic scaling.

Choose:

``` text
Target tracking scaling policy
Metric: Average CPU utilization
Target value: 50
```

Set an appropriate instance warmup period for the application.

AWS target tracking creates and manages the CloudWatch alarms needed for
the policy. [AWS: Target tracking scaling
policies](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html)

------------------------------------------------------------------------

## Step 7: Verify Instances

Go to:

EC2 -\> Auto Scaling Groups -\> `asg-web`

Verify:

``` text
Desired: 2
Min: 2
Max: 4

Instances: 2
```

Then go to:

EC2 -\> Target Groups -\> Targets

Both instances should become:

``` text
healthy
```

------------------------------------------------------------------------

## Step 8: Test the ALB

Copy the ALB DNS name.

Open:

``` text
http://ALB-DNS-NAME
```

You should receive the Nginx response.

------------------------------------------------------------------------

## Step 9: Test Self-Healing

Terminate one ASG-managed instance manually.

EC2 Auto Scaling should detect the capacity loss and launch a
replacement to restore desired capacity. AWS's introductory tutorial
demonstrates this behavior. [AWS: First Auto Scaling group
tutorial](https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-your-first-auto-scaling-group.html)

------------------------------------------------------------------------

# 22. AWS CLI Implementation

Set the region:

``` bash
aws configure set region ap-south-1
```

## Step 1: Create Launch Template

Example:

``` bash
aws ec2 create-launch-template \
  --launch-template-name lt-web-asg \
  --version-description initial \
  --launch-template-data '{
    "ImageId":"ami-REPLACE_ME",
    "InstanceType":"t3.micro",
    "SecurityGroupIds":["sg-REPLACE_ME"],
    "UserData":"BASE64_ENCODED_USER_DATA"
  }'
```

The AMI ID is Region-specific.

Reference: [AWS CLI
create-launch-template](https://docs.aws.amazon.com/cli/latest/reference/ec2/create-launch-template.html)

------------------------------------------------------------------------

## Step 2: Create Auto Scaling Group

``` bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name asg-web \
  --launch-template LaunchTemplateName=lt-web-asg,Version='$Latest' \
  --min-size 2 \
  --max-size 4 \
  --desired-capacity 2 \
  --vpc-zone-identifier "subnet-AAAA,subnet-BBBB"
```

AWS strongly recommends using a Launch Template with
`create-auto-scaling-group`. [AWS CLI:
create-auto-scaling-group](https://docs.aws.amazon.com/cli/latest/reference/autoscaling/create-auto-scaling-group.html)

------------------------------------------------------------------------

## Step 3: Attach Target Group

``` bash
aws autoscaling attach-traffic-sources \
  --auto-scaling-group-name asg-web \
  --traffic-sources "Identifier=arn:aws:elasticloadbalancing:REGION:ACCOUNT:targetgroup/web-tg/TARGETGROUPID,Type=elbv2"
```

Alternatively, use the ASG `--target-group-arns` option where supported
by the CLI/API workflow.

------------------------------------------------------------------------

## Step 4: Create Target Tracking Policy

Create `target-tracking.json`:

``` json
{
  "TargetValue": 50.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ASGAverageCPUUtilization"
  },
  "ScaleOutCooldown": 60,
  "ScaleInCooldown": 300
}
```

Then:

``` bash
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name asg-web \
  --policy-name cpu50-target-tracking \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration file://target-tracking.json
```

AWS documents this CLI pattern for target tracking. [AWS: Create target
tracking scaling
policy](https://docs.aws.amazon.com/autoscaling/ec2/userguide/policy_creating.html)

------------------------------------------------------------------------

## Step 5: Verify

``` bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names asg-web
```

Policies:

``` bash
aws autoscaling describe-policies \
  --auto-scaling-group-name asg-web
```

Instances:

``` bash
aws autoscaling describe-auto-scaling-instances
```

------------------------------------------------------------------------

## Step 6: Change Desired Capacity

``` bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name asg-web \
  --desired-capacity 3
```

This is manual scaling, not dynamic scaling.

------------------------------------------------------------------------

## Step 7: Start Instance Refresh

``` bash
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name asg-web \
  --preferences MinHealthyPercentage=100,InstanceWarmup=60
```

Check:

``` bash
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name asg-web
```

Reference: [AWS: Start an instance
refresh](https://docs.aws.amazon.com/autoscaling/ec2/userguide/start-instance-refresh.html)

------------------------------------------------------------------------

# 23. Terraform Implementation

The core Terraform resources are:

-   `aws_launch_template`
-   `aws_autoscaling_group`
-   `aws_autoscaling_policy`
-   `aws_lb`
-   `aws_lb_target_group`
-   `aws_lb_listener`
-   `aws_autoscaling_attachment` or appropriate traffic-source
    attachment

Terraform's `aws_autoscaling_group` supports Launch Templates and mixed
instance policies. [Terraform:
aws_autoscaling_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group)

------------------------------------------------------------------------

## Step 1: Provider

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

Use the provider version appropriate for your environment and check the
current Terraform Registry documentation before deployment.

------------------------------------------------------------------------

## Step 2: Variables

``` hcl
variable "ami_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}
```

------------------------------------------------------------------------

## Step 3: Security Group

``` hcl
resource "aws_security_group" "web" {
  name   = "sg-asg-web"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

For production, separate the ALB and EC2 security groups and allow
application traffic to EC2 only from the ALB security group.

------------------------------------------------------------------------

## Step 4: Launch Template

``` hcl
resource "aws_launch_template" "web" {
  name_prefix   = "lt-web-asg-"
  image_id      = var.ami_id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -eux
    dnf install -y nginx
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <html>
    <body>
      <h1>EC2 Auto Scaling Demo</h1>
    </body>
    </html>
    HTML
    systemctl enable nginx
    systemctl start nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ASG-Web"
    }
  }
}
```

------------------------------------------------------------------------

## Step 5: Application Load Balancer

``` hcl
resource "aws_lb" "web" {
  name               = "alb-web"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.web.id]
  subnets            = var.subnet_ids
}
```

For a production architecture, use a dedicated ALB security group rather
than sharing the instance security group.

------------------------------------------------------------------------

## Step 6: Target Group

``` hcl
resource "aws_lb_target_group" "web" {
  name     = "tg-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }
}
```

------------------------------------------------------------------------

## Step 7: ALB Listener

``` hcl
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
```

------------------------------------------------------------------------

## Step 8: Auto Scaling Group

``` hcl
resource "aws_autoscaling_group" "web" {
  name                = "asg-web"
  min_size            = 2
  desired_capacity    = 2
  max_size            = 4
  vpc_zone_identifier = var.subnet_ids

  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web.arn]

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 100
      instance_warmup        = 60
    }
  }

  tag {
    key                 = "Name"
    value               = "ASG-Web"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

------------------------------------------------------------------------

## Step 9: Target Tracking Policy

``` hcl
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "cpu50-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.web.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}
```

------------------------------------------------------------------------

## Step 10: Outputs

``` hcl
output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.web.name
}
```

------------------------------------------------------------------------

## Step 11: Terraform Deployment

``` bash
terraform init
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

Test the ALB DNS name from the Terraform output.

------------------------------------------------------------------------

# 24. Console vs CLI vs Terraform

  --------------------------------------------------------------------------------------------------------
  Activity          Console               CLI                           Terraform
  ----------------- --------------------- ----------------------------- ----------------------------------
  Launch Template   GUI                   `create-launch-template`      `aws_launch_template`

  ASG               GUI                   `create-auto-scaling-group`   `aws_autoscaling_group`

  Scaling policy    GUI                   `put-scaling-policy`          `aws_autoscaling_policy`

  Desired capacity  GUI                   `set-desired-capacity`        `desired_capacity`

  Instance refresh  GUI                   `start-instance-refresh`      `instance_refresh`

  Lifecycle hook    GUI                   `put-lifecycle-hook`          `aws_autoscaling_lifecycle_hook`

  ALB               GUI                   `create-load-balancer`        `aws_lb`

  Target group      GUI                   `create-target-group`         `aws_lb_target_group`

  Repeatability     Low/medium            High                          Very high

  State management  AWS console           AWS APIs                      Terraform state

  Best use          Learning/inspection   Automation/scripts            Infrastructure as code
  --------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 25. Scaling Decision Table

  -----------------------------------------------------------------------
  Requirement                         Recommended approach
  ----------------------------------- -----------------------------------
  Maintain CPU around 50%             Target tracking

  Add different amounts for different Step scaling
  alarm ranges                        

  Predictable business-hour demand    Scheduled scaling

  Recurring historical demand         Predictive scaling

  Very fast application startup       Warm pool
  required                            

  Graceful startup/termination        Lifecycle hook
  actions                             

  Update AMI without replacing all    Instance refresh
  instances simultaneously            

  Lowest compute cost and             Spot + mixed instances
  interruption-tolerant workload      

  Replace at-risk Spot instances      Capacity Rebalancing
  early                               

  High availability                   Multi-AZ ASG + ALB

  Application health should determine ELB health check
  replacement                         
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 26. EC2 Auto Scaling vs Other Compute Services

  --------------------------------------------------------------------------
  Service                 Scaling model            Best fit
  ----------------------- ------------------------ -------------------------
  EC2 + ASG               Instance-based           Full OS control

  ECS on EC2              Container tasks + EC2    Container workloads
                          capacity                 requiring EC2 control

  ECS Fargate             Task/service scaling     Serverless containers
                          without managing servers 

  Lambda                  Invocation/concurrency   Event-driven/serverless
                          scaling                  functions

  EKS                     Kubernetes workload      Kubernetes
                          scaling                  

  AWS Batch               Batch job compute        Batch workloads
                          scaling                  
  --------------------------------------------------------------------------

SAA-C03 often tests whether the requirement is for server control,
containers, or serverless execution.

------------------------------------------------------------------------

# 27. ALB + ASG vs Single EC2

  Requirement                   Single EC2       ALB + ASG
  ------------------------- -------------- ---------------
  Automatic scaling                     No             Yes
  Instance replacement              Manual       Automatic
  Multi-AZ                    No by itself             Yes
  Load balancing                        No             Yes
  Fault tolerance                      Low            High
  Operational complexity               Low          Higher
  Production web workload          Limited   Common choice

------------------------------------------------------------------------

# 28. SAA-C03 Architecture Patterns

## Pattern 1: Highly Available Web Application

``` text
Route 53
   |
   v
ALB
 |
 +-------------------+
 |                   |
AZ-a                AZ-b
 |                   |
EC2                 EC2
 \                   /
  \                 /
   Auto Scaling Group
```

Use when the requirement is:

-   High availability
-   Automatic scaling
-   Web traffic distribution
-   Instance replacement

------------------------------------------------------------------------

## Pattern 2: Predictable Daily Traffic

``` text
Scheduled Scaling
       |
       v
ASG
```

Use scheduled scaling for known traffic patterns and combine it with
dynamic scaling if unexpected demand is possible.

------------------------------------------------------------------------

## Pattern 3: Long Startup Time

``` text
ASG
 |
 +-- InService
 |
 +-- Warm Pool
```

Use a warm pool when launching and initializing an instance takes
significant time.

------------------------------------------------------------------------

## Pattern 4: Spot Cost Optimization

``` text
ASG
 |
 +-- On-Demand baseline
 |
 +-- Spot capacity
       |
       +-- Capacity Rebalancing
```

Use only when the application can tolerate interruption.

------------------------------------------------------------------------

# 29. CloudWatch and Auto Scaling

CloudWatch provides the metrics and alarms used by many scaling
strategies.

Important metrics include:

-   CPUUtilization
-   NetworkIn
-   NetworkOut
-   ALB RequestCountPerTarget
-   Application-specific custom metrics

Target tracking can create/manage the CloudWatch alarms used to maintain
its target. [AWS: Target
tracking](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html)

------------------------------------------------------------------------

# 30. Custom Metrics

If CPU does not represent application load well, publish a custom
metric.

Examples:

``` text
ActiveUsers
QueueDepth
TransactionsPerSecond
RequestsPerSecond
```

A worker ASG is often better scaled using queue depth than CPU.

Example:

``` text
SQS Queue
    |
    | queue depth
    v
CloudWatch
    |
    v
ASG scaling policy
    |
    v
EC2 workers
```

------------------------------------------------------------------------

# 31. SQS Worker Auto Scaling

For asynchronous workers:

``` text
Application
    |
    v
SQS
    |
    v
EC2 Worker ASG
```

Scale based on queue backlog or a derived metric such as backlog per
instance.

This is often a better architecture than scaling worker EC2 instances
purely on CPU utilization.

------------------------------------------------------------------------

# 32. User Data and Immutable Instances

Use user data to bootstrap an instance:

``` bash
#!/bin/bash
apt-get update
apt-get install -y nginx
```

For production systems, prefer immutable images using EC2 Image Builder
or a CI/CD process when startup scripts become large or fragile.

An ASG should be able to create a replacement instance without relying
on manual configuration performed on an old instance.

------------------------------------------------------------------------

# 33. Instance Refresh Best Practice

When updating an application:

``` text
Old AMI
   |
Create new AMI
   |
Create new Launch Template version
   |
Instance Refresh
   |
Rolling replacement
```

AWS's instance refresh can replace instances in batches while
maintaining a configured minimum healthy percentage. [AWS: Instance
refresh](https://docs.aws.amazon.com/autoscaling/ec2/userguide/instance-refresh-overview.html)

------------------------------------------------------------------------

# 34. Failure Scenarios

## EC2 instance fails

``` text
Instance unhealthy
       |
       v
ASG detects failure
       |
       v
Terminate/replace
       |
       v
Desired capacity restored
```

## Availability Zone fails

With multiple AZs:

``` text
AZ-a -> unavailable
AZ-b -> continues
AZ-c -> continues
```

The ASG attempts to rebalance capacity across enabled AZs.

## Traffic increases

``` text
Traffic
  |
  v
ALB
  |
CloudWatch metric
  |
Scaling policy
  |
ASG scale out
```

------------------------------------------------------------------------

# 35. Troubleshooting

## ASG does not launch instances

Check:

1.  Launch Template AMI exists in the selected Region.
2.  Instance type is compatible with AMI architecture.
3.  Subnets have available IP addresses.
4.  Security group exists in the same VPC.
5.  IAM instance profile is valid.
6.  Service-linked role exists and permissions are adequate.
7.  EC2 quotas are not exceeded.
8.  Capacity is available for the selected instance type.

AWS notes that Launch Template values are not fully validated at
template creation time, so incorrect combinations can prevent instances
from launching. [AWS: Launch
Templates](https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-launch-template.html)

## Instances launch but become unhealthy

Check:

``` text
ALB target health
Application port
Security groups
NACLs
Health check path
Application startup
User data logs
```

## Scaling does not happen

Check:

``` text
CloudWatch metric
Scaling policy
Current desired capacity
Maximum capacity
Instance warmup
Policy state
Alarm state
```

## ASG scales too aggressively

Review:

-   Target value
-   Warmup period
-   Metric selection
-   Scale-out thresholds
-   Application startup time

------------------------------------------------------------------------

# 36. Security Best Practices

-   Use IAM roles instead of static AWS credentials on EC2.
-   Keep SSH restricted to trusted source IPs or use Systems Manager
    Session Manager.
-   Use separate ALB and EC2 security groups.
-   Store application state outside ephemeral EC2 instances.
-   Use encrypted EBS volumes where appropriate.
-   Use IMDSv2.
-   Keep AMIs patched.
-   Use private subnets for application instances where appropriate.
-   Put internet-facing ALBs in public subnets and application EC2
    instances in private subnets for common production architectures.
-   Use HTTPS/TLS through the ALB for secure web traffic.
-   Monitor scaling activities and instance health.

------------------------------------------------------------------------

# 37. Cost Considerations

EC2 Auto Scaling itself has no additional service charge; you pay for
the AWS resources it launches and uses, such as EC2 instances, EBS
volumes, and CloudWatch alarms. [AWS: EC2 Auto Scaling
pricing](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-benefits.html)

Scaling can reduce cost by removing excess capacity, but poorly
configured policies can increase cost through excessive scale-out or
slow scale-in.

------------------------------------------------------------------------

# 38. Cleanup

## Console

Delete:

1.  Auto Scaling Group
2.  Load Balancer
3.  Target Group
4.  Launch Template
5.  Security Groups if no longer required
6.  Other lab resources

When deleting an ASG, be careful with instances and attached resources
according to the selected deletion behavior.

## CLI

``` bash
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name asg-web \
  --min-size 0 \
  --desired-capacity 0
```

Then delete:

``` bash
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name asg-web \
  --force-delete
```

Delete the scaling policy:

``` bash
aws autoscaling delete-policy \
  --auto-scaling-group-name asg-web \
  --policy-name cpu50-target-tracking
```

## Terraform

``` bash
terraform destroy
```

Review the plan before confirming.

------------------------------------------------------------------------

# 39. SAA-C03 Exam Decision Table

  Question requirement                            Best answer
  ----------------------------------------------- --------------------------------
  Automatically add EC2 instances                 Auto Scaling Group
  Maintain desired EC2 capacity                   Auto Scaling Group
  Replace failed EC2 instances                    Auto Scaling Group
  Distribute traffic across EC2                   ALB/NLB
  HTTP/HTTPS application routing                  ALB
  TCP/UDP/very high performance L4                NLB
  Maintain average CPU target                     Target tracking
  Different actions at different thresholds       Step scaling
  Predictable traffic every morning               Scheduled scaling
  Forecast recurring demand                       Predictive scaling
  Long EC2 startup time                           Warm pool
  Graceful launch/termination action              Lifecycle hook
  Update AMI gradually                            Instance refresh
  Cheap interruptible capacity                    Spot Instances
  Replace at-risk Spot instances                  Capacity Rebalancing
  High availability                               Multi-AZ ASG + load balancer
  Application health should trigger replacement   ELB health check
  Container workload                              ECS/EKS depending requirements
  Event-driven short-running compute              Lambda

------------------------------------------------------------------------

# 40. Important SAA-C03 Distinctions

### Auto Scaling vs Load Balancer

``` text
ALB = distributes traffic
ASG = manages EC2 capacity
```

### Auto Scaling vs CloudWatch

``` text
CloudWatch = metrics/alarms
ASG = changes EC2 capacity
```

### Auto Scaling vs Route 53

``` text
Route 53 = DNS/routing
ASG = EC2 capacity
```

### Auto Scaling vs ECS Service Auto Scaling

``` text
EC2 Auto Scaling = EC2 instance capacity
ECS Service Auto Scaling = ECS task/service capacity
```

### Auto Scaling vs AWS Auto Scaling

Amazon EC2 Auto Scaling manages EC2 Auto Scaling Groups. AWS Auto
Scaling is a broader service/interface for scaling multiple supported
AWS resources. Do not treat the names as interchangeable.

------------------------------------------------------------------------

# 41. Official AWS Documentation

## Amazon EC2 Auto Scaling

https://docs.aws.amazon.com/autoscaling/ec2/userguide/

## Auto Scaling Groups

https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html

## Launch Templates

https://docs.aws.amazon.com/autoscaling/ec2/userguide/launch-templates.html

## Create Launch Template

https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-launch-template.html

## Create Auto Scaling Group

https://docs.aws.amazon.com/autoscaling/ec2/userguide/create-asg-launch-template.html

## Dynamic Scaling

https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scale-based-on-demand.html

## Target Tracking

https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html

## Step Scaling

https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html

## Scheduled Scaling

https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-scheduled-scaling.html

## Predictive Scaling

https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive.html

## Health Checks

https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-health-checks.html

## Lifecycle Hooks

https://docs.aws.amazon.com/autoscaling/ec2/userguide/adding-lifecycle-hooks.html

## Instance Refresh

https://docs.aws.amazon.com/autoscaling/ec2/userguide/instance-refresh-overview.html

## Warm Pools

https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-warm-pools.html

## Capacity Rebalancing

https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-capacity-rebalancing.html

## ELB with Auto Scaling

https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-load-balancer.html

## AWS CLI Auto Scaling

https://docs.aws.amazon.com/cli/latest/reference/autoscaling/

## create-auto-scaling-group

https://docs.aws.amazon.com/cli/latest/reference/autoscaling/create-auto-scaling-group.html

## put-scaling-policy

https://docs.aws.amazon.com/cli/latest/reference/autoscaling/put-scaling-policy.html

------------------------------------------------------------------------

# 42. Terraform Documentation

## aws_launch_template

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template

## aws_autoscaling_group

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group

## aws_autoscaling_policy

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy

## aws_autoscaling_lifecycle_hook

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook

## aws_lb

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb

## aws_lb_target_group

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group

## aws_lb_listener

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener

------------------------------------------------------------------------

# 43. Final SAA-C03 Mental Model

``` text
                 Client
                    |
                    v
              Route 53 / DNS
                    |
                    v
             Application Load Balancer
                    |
          +---------+---------+
          |                   |
        AZ-a                AZ-b
          |                   |
        EC2                 EC2
          |                   |
          +---------+---------+
                    |
             Auto Scaling Group
                    |
             Launch Template
                    |
              CloudWatch metrics
                    |
             Scaling Policy
                    |
          +---------+---------+
          |                   |
       Scale Out            Scale In
          |                   |
      More EC2             Fewer EC2
```

Remember:

1.  **Launch Template defines how instances are launched.**
2.  **Auto Scaling Group maintains and changes EC2 capacity.**
3.  **ALB distributes application traffic.**
4.  **CloudWatch provides metrics and alarms.**
5.  **Target tracking is the common default for dynamic scaling.**
6.  **Multi-AZ placement provides availability.**
7.  **ELB health checks allow application health to influence instance
    replacement.**
8.  **Instance refresh updates an ASG gradually.**
9.  **Lifecycle hooks allow custom actions during launch/termination.**
10. **Warm pools reduce scale-out latency for slow-starting
    applications.**
11. **Mixed instances and Spot can reduce compute cost.**
12. **Capacity Rebalancing helps replace at-risk Spot capacity
    proactively.**

For SAA-C03, choose the architecture that separates **traffic
distribution, capacity management, health detection, monitoring, and
application state** instead of relying on a single service to perform
all of these functions.
