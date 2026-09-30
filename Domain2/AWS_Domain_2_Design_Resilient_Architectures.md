# AWS Solutions Architect Associate (SAA-C03)
# Domain 2: Design Resilient Architectures

## 1. Domain Overview

AWS Certified Solutions Architect - Associate SAA-C03 Domain 2 is **Design Resilient Architectures** and represents **26% of scored content**. The current AWS exam guide divides the domain into two tasks:

- **Task 2.1: Design scalable and loosely coupled architectures**
- **Task 2.2: Design highly available and/or fault-tolerant architectures**

AWS lists knowledge areas including API management, managed services, caching, stateless design, event-driven architectures, horizontal/vertical scaling, edge acceleration, containers, load balancing, multi-tier architectures, queues and messaging, serverless, storage, ECS/EKS, read replicas, Step Functions, AWS global infrastructure, DR strategies, distributed design, failover, immutable infrastructure, proxies, quotas, storage durability/availability, and workload visibility. [Official AWS SAA-C03 Domain 2](https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03/solutions-architect-associate-03-domain2.html)

---

## 2. Resilience, Availability, Fault Tolerance, Scalability

| Concept | Meaning | Typical AWS mechanisms |
|---|---|---|
| Availability | Ability to remain operational when required | Multi-AZ, load balancing, managed services |
| Resilience | Ability to recover from disruptions and continue operating | Auto Scaling, backups, failover, multi-AZ/multi-Region |
| Fault tolerance | Continue operating despite failure of a component | Redundant resources, multi-AZ, replicated data |
| Scalability | Ability to handle increased workload | Auto Scaling, serverless, queues, distributed architecture |
| Elasticity | Automatically add/remove capacity according to demand | EC2 Auto Scaling, Lambda, DynamoDB on-demand |
| Durability | Ability to retain data without loss | S3, backups, replication |
| RTO | Maximum acceptable time to restore service | Determines DR strategy |
| RPO | Maximum acceptable data loss measured in time | Determines backup/replication frequency |

AWS defines resiliency as the ability of a workload to recover from infrastructure or service disruptions, dynamically acquire resources to meet demand, and mitigate disruptions such as misconfigurations and transient network problems. [AWS Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/resiliency-and-the-components-of-reliability.html)

---

# PART I - TASK 2.1
# Design Scalable and Loosely Coupled Architectures

## 3. Horizontal vs Vertical Scaling

### Vertical scaling

Increase the size of an existing resource.

```text
Before:
EC2 t3.medium

        ↓

After:
EC2 t3.large
```

Advantages:
- Simple
- Useful for workloads that cannot easily distribute processing

Limitations:
- Has hardware/instance limits
- May require replacement or downtime depending on workload
- Does not eliminate a single resource failure

### Horizontal scaling

Add more resources.

```text
              ALB
               |
       +-------+-------+
       |       |       |
      EC2     EC2     EC2
```

Horizontal scaling is usually preferred for highly available distributed workloads.

---

## 4. Elasticity

Elasticity means capacity can increase and decrease according to demand.

Common AWS services:

| Requirement | AWS service |
|---|---|
| EC2 fleet scaling | EC2 Auto Scaling |
| Serverless compute | Lambda |
| Container compute | ECS/Fargate |
| Kubernetes workloads | EKS |
| Database capacity scaling | Aurora, DynamoDB |
| Queue-based workload scaling | SQS + Auto Scaling |

---

# 5. Stateless Architecture

A stateless application does not depend on local instance memory or local instance storage to preserve user session state.

```text
                    ALB
                     |
          +----------+----------+
          |          |          |
         EC2        EC2        EC2
          |          |          |
          +----------+----------+
                     |
              Shared services
          +----------+----------+
          |                     |
       DynamoDB              S3/ElastiCache
```

Session data can be stored externally using services such as ElastiCache or DynamoDB when appropriate.

### SAA-C03 distinction

| Design | Resilience |
|---|---|
| Session stored only in one EC2 | Lower |
| Session stored in external shared service | Better for horizontal scaling |
| Application state stored on instance local disk | Creates dependency on instance |
| Stateless EC2 behind ALB | Supports replacement and scaling |

---

# 6. Load Balancing

## Application Load Balancer

ALB operates at Layer 7 and supports HTTP/HTTPS routing features.

Typical architecture:

```text
Internet
   |
CloudFront
   |
ALB
   |
+--+----------------+
|                   |
EC2-A              EC2-B
AZ-a                AZ-b
```

For high availability, place targets across multiple Availability Zones.

## Network Load Balancer

NLB operates at Layer 4 and is suitable for TCP, TLS, UDP and workloads requiring very high network performance or static IP requirements.

## Gateway Load Balancer

Used to deploy, scale and manage virtual network appliances such as firewalls.

---

# 7. ALB vs NLB vs GWLB

| Feature | ALB | NLB | GWLB |
|---|---|---|---|
| Layer | 7 | 4 | 3/4 network appliance integration |
| HTTP routing | Yes | Limited | No |
| Host/path routing | Yes | No | No |
| TCP | No direct Layer-4 listener model | Yes | Yes for appliance traffic |
| UDP | No | Yes | Appliance dependent |
| Main use | Web applications | High-performance network traffic | Network/security appliances |

---

# 8. Loose Coupling

Loose coupling means components can operate independently and communicate through well-defined interfaces or messaging mechanisms.

Bad tightly coupled model:

```text
Application A ---> Application B ---> Application C
```

A failure in B can directly affect A.

Loosely coupled model:

```text
Producer
   |
   v
 Amazon SQS
   |
   v
Consumer
```

The producer does not need the consumer to process the request immediately.

---

# 9. Amazon SQS

Amazon SQS is a managed message queue.

Typical architecture:

```text
Web Application
      |
      v
     SQS
      |
      v
Worker Fleet
```

Benefits:
- Decouples components
- Buffers traffic spikes
- Allows asynchronous processing
- Supports retry behavior
- Helps isolate failures

## Standard vs FIFO

| Feature | Standard | FIFO |
|---|---|---|
| Throughput | Very high | Lower than Standard depending on configuration |
| Ordering | Best effort | Guaranteed ordering within FIFO constraints |
| Duplicate delivery | At-least-once | Exactly-once processing semantics when configured/used correctly |
| Use case | General asynchronous workloads | Ordering/deduplication requirements |

---

# 10. SNS

Amazon SNS is primarily a pub/sub messaging service.

```text
                  SNS Topic
                 /    |    \
                /     |     \
              SQS   Lambda   HTTPS
```

Use SNS when one event needs to be delivered to multiple subscribers.

### SNS vs SQS

| Requirement | Service |
|---|---|
| Queue/buffer work | SQS |
| Publish to many subscribers | SNS |
| Fan-out | SNS + SQS |
| Worker decoupling | SQS |
| Ordered queue | SQS FIFO |

---

# 11. Event-Driven Architecture

```text
Application
    |
    v
EventBridge
    |
+---+---------+----------+
|             |          |
Lambda       SQS       Step Functions
```

Use event-driven architectures when components should react to events without tight synchronous dependencies.

---

# 12. Amazon EventBridge

EventBridge routes events between producers and targets.

Common pattern:

```text
AWS service
    |
    v
EventBridge Rule
    |
    +----> Lambda
    +----> SQS
    +----> Step Functions
```

It is useful for service events, application events, and scheduled events.

---

# 13. API Gateway

API Gateway provides managed APIs.

Typical architecture:

```text
Client
  |
API Gateway
  |
Lambda / ALB / AWS service
```

Use API Gateway when the requirement involves managed API exposure, throttling, authentication/integration patterns, or serverless APIs.

---

# 14. Caching

Caching reduces repeated access to slower or more expensive backend systems.

Common AWS caching mechanisms:

| Requirement | Service |
|---|---|
| Application in-memory cache | ElastiCache |
| Distributed Redis/Valkey-compatible cache | ElastiCache |
| CDN caching | CloudFront |
| DynamoDB caching | DAX |
| API caching | API Gateway caching where applicable |

Typical architecture:

```text
Client
  |
CloudFront
  |
ALB
  |
Application
  |
ElastiCache
  |
Database
```

---

# 15. Multi-Tier Architecture

A common resilient web architecture is:

```text
                 Internet
                    |
                CloudFront
                    |
                   ALB
                    |
          +---------+---------+
          |                   |
       App AZ-a            App AZ-b
          |                   |
          +---------+---------+
                    |
              Database layer
                    |
               Aurora/RDS
```

Typical tiers:

1. Presentation/web tier
2. Application tier
3. Database/data tier

For high availability, distribute appropriate tiers across Availability Zones.

---

# 16. Containers

Use containers when the application benefits from packaged runtime dependencies, portability, rapid deployment, or microservice architecture.

### ECS vs EKS

| Requirement | ECS | EKS |
|---|---|---|
| AWS-native container orchestration | Strong fit | Also supported |
| Kubernetes required | No | Yes |
| Operational complexity | Generally lower | Higher |
| Kubernetes ecosystem | No | Yes |

### Fargate

Fargate provides serverless compute for containers. You don't manage the underlying EC2 instances.

---

# 17. Lambda and Serverless

Lambda is appropriate for event-driven, short-lived, automatically scaling workloads.

```text
S3 event
   |
   v
Lambda
   |
DynamoDB / SQS / SNS
```

Serverless does not mean that no servers exist. It means AWS manages the underlying infrastructure for the service.

---

# 18. Step Functions

Step Functions orchestrates workflows.

```text
Start
  |
Validate
  |
Process
  |
+-- Success --> Store
|
+-- Failure --> Retry / Recovery
```

Use it when the requirement involves workflow state, retries, branching, parallel processing, or orchestration across AWS services.

---

# 19. Storage Types

| Type | AWS examples | Characteristics |
|---|---|---|
| Object | S3 | Highly durable object storage |
| Block | EBS | Block storage attached to compute |
| File | EFS | Shared file system |
| File | FSx | Purpose-built file systems |
| Archive | S3 Glacier classes | Long-term archival |

Storage selection must consider performance, durability, availability, access model and cost.

---

# 20. Read Replicas

Read replicas allow read traffic to be distributed away from the primary database.

```text
             Application
                  |
             +----+----+
             |         |
           Writer     Reader
             |         |
         Primary    Read Replica
```

A read replica is primarily a scaling mechanism for read-heavy workloads. It should not automatically be treated as the same thing as a Multi-AZ standby.

### Multi-AZ vs Read Replica

| Feature | Multi-AZ | Read Replica |
|---|---|---|
| Primary purpose | Availability/failover | Read scaling |
| Application reads from standby | Generally no | Yes |
| Replication | Synchronous for supported RDS Multi-AZ configurations | Asynchronous |
| Typical use | HA | Read-heavy workloads |

---

# PART II - TASK 2.2
# Design Highly Available and Fault-Tolerant Architectures

## 21. AWS Global Infrastructure

Important hierarchy:

```text
AWS
 |
 +-- Region
      |
      +-- Availability Zone
      |     |
      |     +-- Data centers
      |
      +-- Availability Zone
            |
            +-- Data centers
```

### Region

A geographic AWS infrastructure area containing multiple Availability Zones.

### Availability Zone

An isolated location within a Region, designed to reduce correlated failure between zones.

For highly available applications, deploy redundant components across multiple Availability Zones where the service and architecture support it.

---

# 22. Availability Zones

Single-AZ architecture:

```text
Region
 |
 +-- AZ-a
      |
      +-- Application
```

Multi-AZ architecture:

```text
Region
 |
 +-- AZ-a --> Application A
 |
 +-- AZ-b --> Application B
```

A failure of one AZ should not remove the entire workload when the architecture is correctly designed for multi-AZ operation.

---

# 23. Single Point of Failure

A single point of failure is a component whose failure can make the workload unavailable.

Example:

```text
ALB
 |
 EC2-A
```

If EC2-A fails, the application has no healthy application capacity.

Better:

```text
          ALB
        /     \
     EC2-A   EC2-B
      AZ-a     AZ-b
```

---

# 24. High Availability Architecture

Recommended pattern:

```text
                  Route 53
                     |
                CloudFront
                     |
                    ALB
                /         \
             AZ-a         AZ-b
              |             |
           EC2-A          EC2-B
              \             /
               \           /
                Aurora/RDS
```

Each layer should be examined for its own failure modes.

---

# 25. Auto Scaling

EC2 Auto Scaling can maintain desired capacity and replace unhealthy instances.

Example:

```text
Minimum: 2
Desired: 2
Maximum: 6
```

If an instance becomes unhealthy:

```text
Unhealthy EC2
      ↓
Removed
      ↓
New EC2 launched
      ↓
Registered with ALB
```

This is an example of automated healing.

---

# 26. Auto Scaling Across Availability Zones

Configure the Auto Scaling Group with subnets in multiple AZs.

```text
ASG
 |
 +-- AZ-a --> EC2
 |
 +-- AZ-b --> EC2
```

This is significantly more resilient than placing all instances in one AZ.

---

# 27. Elastic Load Balancing + Auto Scaling

A standard highly available web architecture is:

```text
Internet
   |
  ALB
   |
+--+----------------+
|                   |
ASG AZ-a          ASG AZ-b
|                   |
EC2                EC2
```

The load balancer distributes traffic and the Auto Scaling Group maintains application capacity.

---

# 28. Route 53 Failover

Route 53 can route users based on routing policies including failover, latency, weighted, geolocation and geoproximity where applicable.

Failover model:

```text
             Route 53
                |
          Health Check
                |
        +-------+-------+
        |               |
      Primary        Secondary
       Region          Region
```

If the primary endpoint fails health checks, DNS failover can direct traffic to the secondary endpoint.

---

# 29. Multi-Region Architecture

```text
                 Route 53
                    |
            +-------+-------+
            |               |
         Region A         Region B
            |               |
         ALB/EC2          ALB/EC2
            |               |
        Database         Database
```

Multi-Region architectures can provide protection against Region-level disruption but introduce additional replication, routing, consistency, operational and cost considerations.

---

# 30. Disaster Recovery

The four classic DR approaches commonly tested in SAA-C03 are:

| Strategy | Standby resources | Recovery speed | Typical cost |
|---|---|---|---|
| Backup and restore | Minimal | Slowest | Lowest |
| Pilot light | Core services/data running | Faster | Low-medium |
| Warm standby | Scaled-down environment running | Faster | Medium-high |
| Multi-site active/active | Full environments | Fastest | Highest |

The exact implementation depends on RTO/RPO requirements.

---

# 31. RTO and RPO

### RTO

Recovery Time Objective:

> How long can the application be unavailable?

Example:

```text
RTO = 1 hour
```

The system must recover within approximately one hour of the disruption under the defined recovery process.

### RPO

Recovery Point Objective:

> How much data loss measured in time is acceptable?

Example:

```text
RPO = 15 minutes
```

Recovery must limit data loss to approximately the latest 15 minutes under the defined process.

---

# 32. DR Strategy Selection

| Requirement | Typical approach |
|---|---|
| Very low cost, long recovery acceptable | Backup and restore |
| Core infrastructure must already exist | Pilot light |
| Faster recovery with reduced running capacity | Warm standby |
| Minimal downtime and continuous service | Active/active |

Do not choose a DR strategy from cost alone. Start with business RTO/RPO requirements.

---

# 33. Backup and Restore

Architecture:

```text
Production
    |
Backups / Snapshots
    |
S3 / Backup Vault / Archive
    |
Recovery Environment
```

Common AWS services:

- AWS Backup
- EBS snapshots
- RDS automated backups
- RDS snapshots
- S3 versioning and replication
- DynamoDB backups

---

# 34. Immutable Infrastructure

Immutable infrastructure means existing deployed infrastructure is not modified in place as the normal deployment model.

Instead:

```text
Old AMI
   ↓
New AMI
   ↓
New instances
   ↓
Traffic moved
   ↓
Old instances removed
```

Benefits include consistency and reduced configuration drift.

---

# 35. Distributed Systems Failure Handling

AWS Reliability guidance recommends designing distributed interactions to tolerate network latency, data loss and component failures. Relevant practices include graceful degradation, throttling, controlled retries, fail-fast behavior, timeouts and stateless designs. [AWS Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/design-interactions-in-a-distributed-system-to-mitigate-or-withstand-failures.html)

### Retry problem

Bad design:

```text
Failure
 ↓
Retry immediately
 ↓
Failure
 ↓
Retry immediately
 ↓
Retry storm
```

Better:

```text
Failure
 ↓
Exponential backoff
 ↓
Retry
 ↓
Maximum retry limit
 ↓
Dead-letter queue / fallback
```

---

# 36. Throttling

Throttling limits request rates to protect services and downstream dependencies.

Use cases:

- API protection
- Preventing overload
- Managing service quotas
- Controlling retry storms

AWS services may also have service quotas that need to be considered when designing highly available workloads.

---

# 37. Amazon RDS Proxy

RDS Proxy sits between applications and the database.

```text
Application Fleet
       |
       v
   RDS Proxy
       |
       v
      RDS
```

It can reduce connection-management pressure and is especially useful for applications such as Lambda that can create large numbers of concurrent connections.

---

# 38. Storage Resilience

### S3

S3 is designed for very high durability and provides multiple storage classes and availability characteristics.

### EBS

EBS provides persistent block storage for EC2. Snapshots can be used for backup and recovery.

### EFS

EFS provides managed shared file storage that can be mounted by multiple compute resources.

### FSx

FSx provides purpose-built managed file systems such as Windows File Server and Lustre.

---

# 39. S3 Versioning

Versioning protects against accidental overwrite and deletion scenarios.

```text
Object
 |
 +-- Version 1
 +-- Version 2
 +-- Version 3
```

Versioning alone is not a complete disaster recovery strategy. Combine it with appropriate replication, lifecycle and backup requirements.

---

# 40. S3 Cross-Region Replication

```text
S3 Bucket - Region A
        |
        | Replication
        v
S3 Bucket - Region B
```

Use when copies of objects need to be maintained in another Region according to the workload's recovery and data-residency requirements.

---

# 41. DynamoDB Global Tables

DynamoDB global tables support multi-Region, multi-active database architectures.

```text
Region A DynamoDB
       ↕
Region B DynamoDB
```

Use when applications require multi-Region data availability with the characteristics supported by DynamoDB global tables.

---

# 42. Aurora Global Database

Aurora Global Database is designed for cross-Region database replication and disaster recovery/read scaling use cases.

```text
Primary Region
Aurora Cluster
      |
      | Replication
      v
Secondary Region
Aurora Cluster
```

---

# 43. Monitoring and Visibility

Resilient architectures require detection of failures.

Important AWS services:

| Service | Main use |
|---|---|
| CloudWatch | Metrics, logs, alarms |
| CloudTrail | API activity/audit |
| AWS X-Ray | Distributed tracing |
| EventBridge | Event routing/automation |
| SNS | Notifications |
| Route 53 Health Checks | Endpoint health |
| AWS Health Dashboard | AWS service/account events |

AWS reliability guidance emphasizes monitoring components, failing over to healthy resources, automating healing, notifications and testing recovery procedures. [AWS Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/design-your-workload-to-withstand-component-failures.html)

---

# 44. CloudWatch Alarms

Example:

```text
EC2 CPU > 80%
       |
       v
CloudWatch Alarm
       |
       v
SNS / Auto Scaling / EventBridge
```

The exact response should be based on the business and technical requirement.

---

# 45. AWS X-Ray

X-Ray provides distributed tracing for applications.

```text
Client
  ↓
API
  ↓
Service A
  ↓
Service B
  ↓
Database
```

X-Ray helps identify latency and errors across distributed application components.

---

# 46. Reliability Design Pattern

A strong general-purpose AWS web architecture is:

```text
                         Route 53
                            |
                       CloudFront
                            |
                           WAF
                            |
                           ALB
                    /                 \
                  AZ-a               AZ-b
                   |                   |
              EC2 / ECS           EC2 / ECS
                   |                   |
                   +--------+----------+
                            |
                     ElastiCache
                            |
                         Aurora
                            |
                    Backup / DR Region
```

This architecture addresses several Domain 2 concerns:

- Multi-AZ application capacity
- Load balancing
- Horizontal scaling
- Caching
- Database availability
- Backup and recovery
- Edge delivery
- Separation of tiers

---

# 47. Architecture Decision Table

| Requirement | Recommended AWS pattern |
|---|---|
| Web application needs HA | ALB + Multi-AZ Auto Scaling |
| Need asynchronous processing | SQS |
| Need fan-out | SNS + SQS |
| Need event routing | EventBridge |
| Need API management | API Gateway |
| Need serverless event processing | Lambda |
| Need containerized serverless compute | Fargate |
| Need Kubernetes | EKS |
| Need workflow orchestration | Step Functions |
| Need distributed cache | ElastiCache |
| Need CDN | CloudFront |
| Need read scaling for RDS | Read replicas |
| Need database HA | RDS/Aurora Multi-AZ architecture |
| Need cross-Region DNS failover | Route 53 |
| Need object durability | S3 |
| Need shared file storage | EFS |
| Need block storage | EBS |
| Need centralized backup | AWS Backup |
| Need distributed tracing | X-Ray |

---

# 48. Console Implementation Lab: Highly Available Web Application

## Objective

Create a simple Multi-AZ web application:

```text
Internet
   |
  ALB
   |
+--+----------+
|             |
AZ-a          AZ-b
EC2           EC2
```

### Step 1: Create VPC

Create a VPC with at least two Availability Zones.

### Step 2: Create subnets

Create public subnets for the ALB and appropriate private subnets for application instances.

### Step 3: Create security groups

ALB SG:

```text
TCP 80 from 0.0.0.0/0
```

EC2 SG:

```text
TCP 80 from ALB security group
```

### Step 4: Create EC2 instances

Launch application instances in different AZs.

### Step 5: Create target group

Register both EC2 instances.

### Step 6: Create ALB

Select at least two AZ subnets.

### Step 7: Configure listener

```text
HTTP : 80 → Target Group
```

### Step 8: Test

Open the ALB DNS name.

### Step 9: Test failure

Stop one EC2 instance and verify that ALB continues sending traffic to the healthy target.

This demonstrates fault isolation at the instance level.

---

# 49. CLI Implementation Example

Create a target group:

```bash
aws elbv2 create-target-group \
  --name resilient-demo-tg \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-xxxxxxxx \
  --target-type instance
```

Register targets:

```bash
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:...:targetgroup/... \
  --targets Id=i-aaaaaaaa Id=i-bbbbbbbb
```

Create the load balancer:

```bash
aws elbv2 create-load-balancer \
  --name resilient-demo-alb \
  --subnets subnet-aaaa subnet-bbbb \
  --security-groups sg-xxxxxxxx
```

Create listener:

```bash
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:...:loadbalancer/app/... \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:...:targetgroup/...
```

---

# 50. Terraform Implementation Pattern

```hcl
resource "aws_lb" "app" {
  name               = "resilient-demo-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "app" {
  name     = "resilient-demo-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

The key resilience property is not Terraform itself. It is the architecture: multiple healthy targets across Availability Zones behind a load balancer.

---

# 51. Common SAA-C03 Comparisons

## Multi-AZ vs Multi-Region

| Multi-AZ | Multi-Region |
|---|---|
| Protects against AZ failure | Protects against larger regional disruption |
| Lower complexity | Higher complexity |
| Usually lower latency | Cross-Region latency possible |
| Common default for HA | Used when business requirements justify it |

## Backup vs Replication

| Backup | Replication |
|---|---|
| Recovery-oriented copy | Maintains another copy continuously/near-continuously depending on service |
| Usually slower recovery | Can provide faster recovery |
| Lower cost in many cases | Often higher cost |
| Does not necessarily provide immediate failover | Can support failover architectures |

## SQS vs SNS vs EventBridge

| Service | Core concept |
|---|---|
| SQS | Queue |
| SNS | Pub/sub notification and fan-out |
| EventBridge | Event bus and event routing |

## Scaling vs HA

| Requirement | Main concept |
|---|---|
| Handle more requests | Scaling |
| Survive resource failure | High availability |
| Recover after major disruption | Disaster recovery |
| Continue despite component failure | Fault tolerance |

---

# 52. SAA-C03 Exam Decision Process

When a question describes a requirement, identify the failure and scaling dimension first.

### If the question says:

**“Traffic suddenly increases.”**

Think:

```text
Auto Scaling / serverless / queues / caching
```

**“One EC2 instance fails.”**

Think:

```text
ALB + multiple targets + Auto Scaling
```

**“One Availability Zone fails.”**

Think:

```text
Multi-AZ architecture
```

**“Entire AWS Region fails.”**

Think:

```text
Multi-Region DR/failover
```

**“Application components should not depend directly on each other.”**

Think:

```text
SQS / SNS / EventBridge / asynchronous architecture
```

**“Read-heavy database workload.”**

Think:

```text
Read replicas / caching / purpose-built database options
```

**“Very low RTO.”**

Think:

```text
Warm standby / active-active depending on requirements
```

**“Very low cost but recovery can take hours.”**

Think:

```text
Backup and restore
```

---

# 53. Common Exam Traps

### Trap 1: Read replica = automatic HA

Not necessarily. Read replicas are primarily a read-scaling mechanism.

### Trap 2: More EC2 instances automatically means HA

Not if all instances are in the same failure domain.

### Trap 3: Multi-AZ = Multi-Region

They address different failure scopes.

### Trap 4: SQS = pub/sub

SQS is a queue. SNS is primarily pub/sub.

### Trap 5: SNS = durable worker queue

For worker decoupling and buffering, SQS is generally the relevant service.

### Trap 6: Vertical scaling solves fault tolerance

Increasing instance size does not eliminate the instance as a single point of failure.

### Trap 7: Backup = failover

A backup is not automatically a live failover environment.

### Trap 8: CloudFront = only performance

CloudFront can improve performance and can also contribute to resilience by distributing content and reducing origin load.

---

# 54. Domain 2 Practical Lab Set

A strong hands-on sequence is:

| Lab | Topic |
|---|---|
| Lab 1 | ALB across two AZs |
| Lab 2 | EC2 Auto Scaling |
| Lab 3 | SQS + Lambda asynchronous processing |
| Lab 4 | SNS + SQS fan-out |
| Lab 5 | EventBridge + Lambda |
| Lab 6 | ElastiCache caching |
| Lab 7 | RDS Multi-AZ |
| Lab 8 | RDS read replica |
| Lab 9 | S3 versioning and replication |
| Lab 10 | AWS Backup |
| Lab 11 | Route 53 failover |
| Lab 12 | Multi-Region DR |
| Lab 13 | Step Functions |
| Lab 14 | ECS/Fargate resilient deployment |
| Lab 15 | CloudWatch alarms and automated recovery |

---

# 55. Official AWS Documentation

## SAA-C03

- [AWS Certified Solutions Architect - Associate SAA-C03](https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03.html)
- [SAA-C03 Domain 2](https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03/solutions-architect-associate-03-domain2.html)
- [SAA-C03 Exam Guide PDF](https://docs.aws.amazon.com/pdfs/aws-certification/latest/solutions-architect-associate-03/solutions-architect-associate-03.pdf)

## Reliability

- [AWS Well-Architected Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/reliability.html)
- [Resiliency and Components of Reliability](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/resiliency-and-the-components-of-reliability.html)
- [Design Workloads to Withstand Component Failures](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/design-your-workload-to-withstand-component-failures.html)
- [Design Distributed Systems to Mitigate Failures](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/design-interactions-in-a-distributed-system-to-mitigate-or-withstand-failures.html)

## Load Balancing

- [Elastic Load Balancing](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html)
- [Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
- [Network Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html)

## Auto Scaling

- [EC2 Auto Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html)

## Messaging

- [Amazon SQS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html)
- [Amazon SNS](https://docs.aws.amazon.com/sns/latest/dg/welcome.html)
- [Amazon EventBridge](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html)

## Serverless and Containers

- [AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)
- [AWS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [AWS Step Functions](https://docs.aws.amazon.com/step-functions/latest/dg/welcome.html)

## Databases and Storage

- [Amazon RDS Multi-AZ](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZSingleStandby.html)
- [Amazon RDS Read Replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html)
- [Amazon Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Welcome.html)
- [Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
- [Amazon EBS](https://docs.aws.amazon.com/ebs/latest/userguide/what-is-ebs.html)
- [Amazon EFS](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html)
- [AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html)

## DNS and DR

- [Amazon Route 53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html)
- [Route 53 Routing Policies](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html)
- [AWS Disaster Recovery](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html)

## Monitoring

- [Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)
- [AWS X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/aws-xray.html)

---

# 56. Domain 2 Final Checklist

Before considering Domain 2 complete, be able to explain:

- Horizontal vs vertical scaling
- Scaling vs elasticity
- Stateless architecture
- ALB vs NLB vs GWLB
- Multi-AZ architecture
- Multi-Region architecture
- SQS vs SNS vs EventBridge
- Event-driven architecture
- API Gateway
- Lambda
- ECS vs EKS
- Fargate
- Step Functions
- Caching
- ElastiCache
- RDS Multi-AZ
- RDS read replicas
- Aurora availability options
- S3 durability/versioning/replication
- EBS vs EFS vs S3
- RTO vs RPO
- Backup and restore
- Pilot light
- Warm standby
- Active/active
- Route 53 failover
- Auto Scaling
- Load balancing
- Fault tolerance
- High availability
- Single points of failure
- Distributed-system failure handling
- Retry and backoff
- Throttling
- RDS Proxy
- CloudWatch
- X-Ray
- AWS Backup

---

# 57. Final SAA-C03 Mental Model

Use this decision sequence:

```text
                    Requirement
                         |
          +--------------+--------------+
          |                             |
       More load?                    Failure?
          |                             |
     Scaling/Elasticity          +------+------+
          |                       |             |
    +-----+------+             Instance       AZ/Region
    |            |                |             |
Horizontal    Vertical         Multi-AZ       DR
    |            |                |             |
ASG/serverless  Larger       ALB + ASG     Multi-Region
                                 |
                           Need decoupling?
                                 |
                         +-------+-------+
                         |               |
                        SQS          SNS/EventBridge
                         |
                    Async processing
```

The central SAA-C03 Domain 2 principle is to design systems so that **increased workload, component failure, Availability Zone failure, and larger-scale disruption do not unnecessarily become application-wide outages**. AWS's Reliability guidance emphasizes automatic recovery, recovery testing, horizontal scaling, and eliminating single points of failure. [AWS Reliability Design Principles](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/design-principles.html)

---

## Source Basis

This documentation is aligned to the current AWS SAA-C03 exam guide. AWS currently assigns **26% of scored content** to Domain 2 and defines the two tasks as scalable/loosely coupled architectures and highly available/fault-tolerant architectures. [AWS SAA-C03 Exam Guide](https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03.html)
