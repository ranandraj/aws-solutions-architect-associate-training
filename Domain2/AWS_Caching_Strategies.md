# AWS Caching Strategies and Related Services

## AWS Solutions Architect Associate (SAA-C03) Professional Documentation

## 1. Overview

Caching stores frequently requested data closer to the component that
needs it so that repeated requests can be served without repeatedly
accessing the original data source.

For SAA-C03, caching should be understood as an architectural decision
rather than as a single AWS service. The main AWS caching technologies
relevant to solution architecture are:

  ----------------------------------------------------------------------------
  Layer                  AWS service       Typical cached    Main location
                                           content           
  ---------------------- ----------------- ----------------- -----------------
  Edge/content delivery  Amazon CloudFront Static files,     Edge locations
                                           cacheable HTTP    
                                           responses         

  API response           Amazon API        API responses     API Gateway stage
                         Gateway REST API                    cache
                         cache                               

  Application/database   Amazon            Frequently        VPC
                         ElastiCache       accessed          
                                           application data, 
                                           sessions,         
                                           computed results  

  DynamoDB-specific      DynamoDB          DynamoDB          VPC
                         Accelerator (DAX) item/query        
                                           results           

  Application-managed    Application       Small,            Application host
                         memory/local      process-local     
                         cache             data              
  ----------------------------------------------------------------------------

CloudFront uses cache policies to control cache keys and TTLs. API
Gateway REST APIs can cache endpoint responses at the stage level.
ElastiCache supports common strategies such as lazy loading,
write-through, and TTL. DAX is a managed in-memory cache designed
specifically for DynamoDB.

## 2. Caching Fundamentals

### 2.1 Cache hit

A cache hit occurs when a request maps to a valid cached object.

``` text
Client
  |
  v
Cache
  |
  +-- HIT --> Return cached data
```

### 2.2 Cache miss

A cache miss occurs when the requested item is absent or no longer
valid.

``` text
Client
  |
  v
Cache
  |
  +-- MISS --> Origin / Database
                  |
                  v
                Data
                  |
                  v
                Cache
                  |
                  v
               Client
```

### 2.3 TTL

TTL controls how long cached data remains valid. TTL is central to
balancing freshness and cache effectiveness.

### 2.4 Cache invalidation

Common approaches include:

-   TTL expiration
-   Explicit invalidation
-   Versioned object names
-   Application-driven deletion/update
-   CloudFront invalidation

### 2.5 Cache key

A cache key determines whether two requests can share the same cached
response. A cache key can include values such as URL path, query
strings, headers, and cookies depending on the caching service and
configuration.

For CloudFront, cache policies explicitly control which headers,
cookies, and query strings participate in the cache key. Fewer
unnecessary cache-key components generally increase cache-hit ratio.
[AWS CloudFront cache
policies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-key-understand-cache-policy.html)

## 3. Major Caching Strategies

### 3.1 Lazy loading / Cache-aside

The application checks the cache first. On a miss, it reads from the
database and places the result in the cache.

``` text
Application
    |
    v
  Cache
  /   \\
HIT   MISS
 |      |
 |      v
 |   Database
 |      |
 |      v
 |    Cache
 |
 v
Response
```

Advantages:

-   Only requested data is cached.
-   Simple to implement.
-   Works well for read-heavy workloads.

Disadvantages:

-   First request after expiration is slower.
-   Stale data is possible if TTL/invalidation is poorly designed.
-   Cache misses can create database load.

AWS documents lazy loading as a common ElastiCache strategy. [AWS
ElastiCache caching
strategies](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Strategies.html)

### 3.2 Write-through

The application updates the database and cache when data changes.

``` text
Application
    |
    +----> Database
    |
    +----> Cache
```

Advantages:

-   Cached data is more likely to be current.
-   Subsequent reads have high cache-hit probability.

Disadvantages:

-   Every write may populate the cache.
-   Infrequently read data can consume cache capacity.

AWS Prescriptive Guidance discusses combining write-through with lazy
loading and TTL. [AWS caching
patterns](https://docs.aws.amazon.com/whitepapers/latest/database-caching-strategies-using-redis/caching-patterns.html)

### 3.3 TTL-based caching

Cached objects expire after a defined period.

``` text
Write data
    |
    v
Cache
 TTL = 300 seconds
    |
    +---- expires ----> MISS
```

Use shorter TTLs when freshness is important and longer TTLs when data
changes infrequently.

### 3.4 Cache-aside plus TTL

This is a common application caching combination:

1.  Check cache.
2.  If hit, return cached data.
3.  If miss, read database.
4.  Write result to cache with TTL.
5.  Return result.

### 3.5 Negative caching

An application can temporarily cache a known "not found" result to
prevent repeated expensive database queries for the same nonexistent
object. Use a short TTL.

### 3.6 Refresh-ahead

Frequently requested objects can be refreshed before expiration so users
are less likely to encounter a cold cache. This is an application design
pattern and must be used carefully to avoid refreshing data that is
rarely requested.

## 4. Amazon CloudFront

Amazon CloudFront is the primary AWS service for caching content close
to viewers at AWS edge locations. Cached content reduces origin requests
and latency. [AWS CloudFront caching and
availability](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/ConfiguringCaching.html)

### 4.1 Typical architecture

``` text
User
 |
 v
CloudFront Edge
 |
 +-- Cache HIT --> User
 |
 +-- Cache MISS
       |
       v
     Origin
       |
       +-- S3
       +-- ALB
       +-- EC2
       +-- API Gateway
```

### 4.2 Cache policy

A CloudFront cache policy controls:

-   Minimum TTL
-   Default TTL
-   Maximum TTL
-   Headers included in cache key
-   Cookies included in cache key
-   Query strings included in cache key

[AWS CloudFront cache
policies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-key-understand-cache-policy.html)

### 4.3 Origin request policy

An origin request policy controls values forwarded to the origin that do
not necessarily need to be part of the cache key. Separating cache-key
values from origin-request values can improve cache efficiency.

### 4.4 Cache behaviors

A distribution can have different cache behaviors based on URL path
patterns.

Example:

``` text
/images/*       -> Long TTL
/static/*       -> Long TTL
/api/*          -> Short/no caching
```

[AWS CloudFront cache
behaviors](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistValuesCacheBehavior.html)

## 5. CloudFront Console Implementation

### Lab architecture

``` text
Browser
   |
   v
CloudFront
   |
   v
S3 bucket
```

### Step 1: Create an S3 bucket

Open Amazon S3 and create a bucket with a globally unique name.

Upload a test object such as `index.html`.

For production, prefer CloudFront Origin Access Control (OAC) rather
than making the bucket public.

### Step 2: Create CloudFront distribution

Open:

**CloudFront -\> Distributions -\> Create distribution**

Select the S3 bucket as the origin.

For the default cache behavior:

-   Viewer protocol: Redirect HTTP to HTTPS
-   Allowed methods: GET, HEAD
-   Cache policy: choose an AWS managed cache policy or create a custom
    policy

### Step 3: Create custom cache policy

Go to:

**CloudFront -\> Policies -\> Cache policies -\> Create cache policy**

Example:

``` text
Name: StaticContentCachePolicy
Minimum TTL: 0
Default TTL: 86400
Maximum TTL: 31536000
```

For static content that does not vary by query string/header/cookie,
avoid adding unnecessary values to the cache key.

### Step 4: Attach cache policy

Open the distribution and edit the default cache behavior.

Attach `StaticContentCachePolicy`.

### Step 5: Test

Open the CloudFront distribution domain name.

Request the object twice.

Inspect response headers such as:

``` text
X-Cache: Hit from cloudfront
```

### Step 6: Invalidate content

When a cached object must be refreshed immediately:

**CloudFront -\> Distribution -\> Invalidations -\> Create
invalidation**

Example:

``` text
/*
```

Use invalidation selectively. Versioned filenames such as `app.v42.js`
are often a better long-term deployment strategy for static assets.

## 6. CloudFront CLI Implementation

Create a cache policy using a JSON document.

Example `cache-policy.json`:

``` json
{
  "CachePolicyConfig": {
    "Name": "StaticContentCachePolicy",
    "Comment": "Cache static objects for one day by default",
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "MinTTL": 0,
    "ParametersInCacheKeyAndForwardedToOrigin": {
      "EnableAcceptEncodingGzip": true,
      "EnableAcceptEncodingBrotli": true,
      "HeadersConfig": {"HeaderBehavior": "none"},
      "CookiesConfig": {"CookieBehavior": "none"},
      "QueryStringsConfig": {"QueryStringBehavior": "none"}
    }
  }
}
```

Create it:

``` bash
aws cloudfront create-cache-policy \
  --cache-policy-config file://cache-policy.json
```

AWS documents the `create-cache-policy` command and cache policy
behavior in the CloudFront CLI reference. [AWS CLI
create-cache-policy](https://docs.aws.amazon.com/cli/latest/reference/cloudfront/create-cache-policy.html)

Create a distribution with the cache policy by supplying its ID in the
distribution configuration, or update an existing distribution so its
cache behavior references the policy.

Invalidate:

``` bash
aws cloudfront create-invalidation \
  --distribution-id E123EXAMPLE \
  --paths '/*'
```

## 7. CloudFront Terraform Implementation

Example cache policy:

``` hcl
resource "aws_cloudfront_cache_policy" "static" {
  name        = "static-content-cache-policy"
  comment     = "Cache static objects"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}
```

Attach it to a distribution:

``` hcl
resource "aws_cloudfront_distribution" "example" {
  enabled = true

  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = "s3-site"
  }

  default_cache_behavior {
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.static.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
```

The current Terraform AWS provider recommends `cache_policy_id` rather
than the older `forwarded_values` approach. [Terraform
aws_cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution.html)

## 8. Amazon ElastiCache

Amazon ElastiCache provides managed in-memory caching for application
workloads. Common architecture choices include Redis/Valkey-compatible
caching and Memcached depending on workload requirements.

Typical architecture:

``` text
Client
  |
  v
Application
  |
  +------> ElastiCache
  |
  +------> Database
```

Use ElastiCache when the application needs an application/data cache
that it controls directly.

## 9. ElastiCache Lazy Loading

Example flow:

``` text
GET product:100
      |
      v
   Cache?
    /   \\
  YES    NO
   |      |
   |      v
   |   Database
   |      |
   |      v
   |   SET cache
   |      |
   +------+
      |
      v
   Response
```

AWS documents lazy loading as a common strategy for ElastiCache. [AWS
ElastiCache caching
strategies](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Strategies.html)

## 10. ElastiCache Write-Through

``` text
Application
   |
   +----> Database update
   |
   +----> Cache update
```

This reduces cache staleness but can cache data that is rarely read.
[AWS caching
patterns](https://docs.aws.amazon.com/whitepapers/latest/database-caching-strategies-using-redis/caching-patterns.html)

## 11. ElastiCache TTL

A cached key can have an expiration time.

Conceptually:

``` text
SET product:100 value EX 300
```

After 300 seconds, the entry expires.

Choose TTL based on data volatility and acceptable staleness.

## 12. ElastiCache Console Implementation

### Step 1: Create VPC

Create a VPC with at least two private subnets in different Availability
Zones.

### Step 2: Create security group

Allow the application security group to connect to the cache port.

Do not open Redis/Valkey or Memcached ports to `0.0.0.0/0`.

### Step 3: Create subnet group

Open:

**ElastiCache -\> Subnet groups -\> Create subnet group**

Select the VPC and private subnets.

### Step 4: Create cache

Open:

**ElastiCache -\> Caches -\> Create**

Choose the appropriate engine/deployment option supported by the current
console.

Configure:

-   VPC
-   Subnet group
-   Security group
-   Encryption
-   Availability settings
-   Node sizing

### Step 5: Connect application

Use the cache endpoint supplied by ElastiCache from an application
running in the VPC.

### Step 6: Test

For Redis/Valkey-compatible clients, test a SET/GET operation.

For example, application logic:

``` text
GET key
IF hit:
    return value
ELSE:
    read database
    SET key value with TTL
    return value
```

## 13. ElastiCache CLI

CLI commands depend on the current ElastiCache deployment type and
engine. Common discovery commands include:

``` bash
aws elasticache describe-cache-clusters
```

For subnet groups:

``` bash
aws elasticache describe-cache-subnet-groups
```

For replication groups where applicable:

``` bash
aws elasticache describe-replication-groups
```

For the exact current command set, use the AWS CLI ElastiCache
reference. [AWS CLI
ElastiCache](https://docs.aws.amazon.com/cli/latest/reference/elasticache/)

## 14. ElastiCache Terraform

A simplified subnet group example:

``` hcl
resource "aws_elasticache_subnet_group" "cache" {
  name       = "application-cache-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}
```

For a Redis/Valkey-compatible replication group, use the current
provider resource and engine options supported by the selected AWS
engine/version.

``` hcl
resource "aws_elasticache_replication_group" "cache" {
  replication_group_id = "application-cache"
  description          = "Application cache"

  node_type            = "cache.t4g.micro"
  num_cache_clusters   = 2
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.cache.name
  security_group_ids = [aws_security_group.cache.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
}
```

Verify the exact engine/version arguments against the current AWS
provider documentation before deployment.

## 15. DynamoDB Accelerator (DAX)

DAX is a managed, DynamoDB-compatible in-memory caching service. It is
specifically designed to accelerate DynamoDB reads and can provide
microsecond-scale access for cached data. [AWS DAX
overview](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.html)

Architecture:

``` text
Application
    |
    v
   DAX
    |
    v
DynamoDB
```

DAX is not a general-purpose cache for arbitrary databases.

## 16. DAX vs ElastiCache

  -----------------------------------------------------------------------
  Feature                 DAX                     ElastiCache
  ----------------------- ----------------------- -----------------------
  Primary purpose         DynamoDB caching        General
                                                  application/data
                                                  caching

  DynamoDB integration    Native                  Application-managed

  Application code        Use DAX-compatible      Application implements
  changes                 client                  cache logic

  General key-value use   No, specialized         Yes

  Best fit                Read-heavy DynamoDB     Sessions, application
                          workloads               data, computed results,
                                                  caching DB queries

  Network                 VPC                     VPC
  -----------------------------------------------------------------------

## 17. DAX Console Implementation

AWS's current console workflow is:

1.  Open DynamoDB.
2.  Open **DAX -\> Subnet groups**.
3.  Create a subnet group.
4.  Open **DAX -\> Clusters**.
5.  Choose **Create cluster**.
6.  Select node type and cluster size.
7.  Select subnet group and security group.
8.  Configure encryption as required.
9.  Create the cluster.

AWS recommends multiple Availability Zones for fault tolerance. AWS's
current console guide states that a production DAX cluster should use at
least three nodes, with nodes distributed across Availability Zones.
[AWS DAX console
creation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.create-cluster.console.html)

DAX uses TCP 8111 for unencrypted clusters and 9111 for encrypted
clusters. [AWS DAX console
creation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.create-cluster.console.html)

## 18. DAX CLI Implementation

Create subnet group:

``` bash
aws dax create-subnet-group \
  --subnet-group-name my-dax-subnet-group \
  --subnet-ids subnet-aaa subnet-bbb subnet-ccc
```

Create cluster:

``` bash
aws dax create-cluster \
  --cluster-name my-dax-cluster \
  --node-type dax.r4.large \
  --replication-factor 3 \
  --iam-role-arn arn:aws:iam::123456789012:role/DAXServiceRoleForDynamoDBAccess \
  --subnet-group my-dax-subnet-group \
  --sse-specification Enabled=true
```

Check status:

``` bash
aws dax describe-clusters
```

AWS's current CLI documentation shows this workflow and requires a DAX
service role for the cluster. [AWS DAX CLI
creation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.create-cluster.cli.html)

## 19. DAX TTL

DAX maintains item and query caches. AWS documents default TTL behavior
and allows TTL configuration through DAX parameter groups. [AWS DAX
cluster
management](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.cluster-management.html)

## 20. DAX Terraform

The AWS provider includes resources for DAX subnet groups, parameter
groups, clusters, and related configuration. Verify the current provider
documentation for exact arguments.

Conceptually:

``` hcl
resource "aws_dax_subnet_group" "example" {
  name       = "dax-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}
```

Then create the DAX cluster using the provider's current
`aws_dax_cluster` resource and associate the subnet group, IAM role,
security group, node type, and replication factor.

## 21. API Gateway Response Caching

API Gateway REST APIs can cache endpoint responses. When enabled, API
Gateway checks the cache before invoking the endpoint, reducing backend
calls and latency. API Gateway caching is configured at the stage level,
with method-level overrides available. [AWS API Gateway
caching](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-caching.html)

Architecture:

``` text
Client
  |
  v
API Gateway
  |
  +-- Cache HIT --> Response
  |
  +-- MISS --> Lambda / HTTP backend
```

Important SAA-C03 distinction:

-   API Gateway cache is primarily an API response cache.
-   ElastiCache is an application/data cache.
-   CloudFront is an edge/content cache.

## 22. API Gateway Console Implementation

For a REST API:

1.  Open API Gateway.
2.  Select an existing REST API or create one.
3.  Create a resource such as `/products`.
4.  Create a `GET` method.
5.  Configure the backend integration.
6.  Deploy the API to a stage such as `prod`.
7.  Open **Stages**.
8.  Select `prod`.
9.  Enable stage caching.
10. Select an appropriate cache capacity.
11. Set TTL according to workload requirements.
12. Deploy/test the API.

API Gateway creates a dedicated cache instance when caching is enabled,
and AWS notes that changing cache capacity replaces the existing cache
and deletes existing cached data. [AWS API Gateway
caching](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-caching.html)

## 23. API Gateway CLI

For a REST API stage, cache cluster settings can be configured using API
Gateway CLI operations. For example, use the stage update operation to
enable caching and specify cache size according to the current API
Gateway API reference.

Inspect a stage:

``` bash
aws apigateway get-stage \
  --rest-api-id REST_API_ID \
  --stage-name prod
```

Flush the stage cache:

``` bash
aws apigateway flush-stage-cache \
  --rest-api-id REST_API_ID \
  --stage-name prod
```

[AWS API Gateway CLI
reference](https://docs.aws.amazon.com/cli/latest/reference/apigateway/)

## 24. API Gateway Terraform

For REST APIs, Terraform can manage stage caching through
`aws_api_gateway_stage`.

Example pattern:

``` hcl
resource "aws_api_gateway_stage" "prod" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  stage_name = "prod"

  cache_cluster_enabled = true
  cache_cluster_size    = "0.5"

  method_settings {
    path               = "/*"
    caching_enabled    = true
    cache_ttl_in_seconds = 300
  }
}
```

Use the current Terraform AWS provider documentation to confirm
supported cache sizes and method-setting arguments.

## 25. Choosing the Right AWS Cache

  Requirement                                    Service
  ---------------------------------------------- ----------------------------
  Cache website images/CSS/JS globally           CloudFront
  Cache S3 static content at edge locations      CloudFront
  Cache API responses at API Gateway             API Gateway REST API cache
  Cache database/application data                ElastiCache
  Cache sessions                                 ElastiCache
  Cache computed application results             ElastiCache
  Accelerate DynamoDB reads with managed cache   DAX
  Cache content close to global users            CloudFront
  Need arbitrary application cache semantics     ElastiCache

## 26. CloudFront vs ElastiCache

  -----------------------------------------------------------------------
  Characteristic          CloudFront              ElastiCache
  ----------------------- ----------------------- -----------------------
  Location                Edge locations          VPC

  Main target             HTTP content            Application/data

  Typical consumers       Browsers/mobile clients Application servers

  Origin                  S3, ALB, API Gateway,   Database/application
                          custom HTTP origin      

  Cache key               HTTP request policy     Application-defined
                                                  keys

  Global edge delivery    Yes                     No

  Session/application     Generally not the       Yes
  objects                 primary use             
  -----------------------------------------------------------------------

## 27. API Gateway Cache vs CloudFront

  -----------------------------------------------------------------------
  Requirement             API Gateway cache       CloudFront
  ----------------------- ----------------------- -----------------------
  API response cache      Yes                     Can cache HTTP
                                                  responses depending on
                                                  configuration

  Edge locations          No                      Yes

  Stage-specific cache    Yes                     No equivalent stage
                                                  cache

  API Gateway integration Native                  Can use API Gateway as
                                                  origin

  Static assets           Not primary use         Excellent fit

  Global content delivery Not primary use         Excellent fit
  -----------------------------------------------------------------------

## 28. ElastiCache vs DAX

  -----------------------------------------------------------------------
  Requirement             ElastiCache             DAX
  ----------------------- ----------------------- -----------------------
  DynamoDB-specific       No                      Yes

  General application     Yes                     No
  cache                                           

  Session storage         Yes                     No

  Cache arbitrary DB      Yes                     No, specialized for
  query results                                   DynamoDB

  DynamoDB-compatible     No                      Yes
  client                                          

  Application-managed     Common                  Reduced for DynamoDB
  cache logic                                     access
  -----------------------------------------------------------------------

## 29. Cache Stampede

A cache stampede occurs when many requests encounter an expired/missing
popular item simultaneously and all query the origin.

Mitigations:

-   Randomized TTLs
-   Request coalescing/single-flight
-   Refresh-ahead
-   Warm cache
-   Rate limiting
-   Distributed locking where appropriate

## 30. Stale Data

Caching introduces a consistency decision.

  Requirement                     Strategy
  ------------------------------- --------------------------------------
  Data can be stale for minutes   Longer TTL
  Data must be nearly current     Short TTL/write-through/invalidation
  Static versioned assets         Long TTL + versioned filenames
  Frequently changing API data    Short TTL or no caching
  User/session state              Carefully designed application cache

Do not cache sensitive or user-specific responses under a shared cache
key.

## 31. Cache Key Design

A cache key that contains too many request attributes reduces cache
reuse.

Example:

``` text
/product/100?user=1001
/product/100?user=1002
/product/100?user=1003
```

If the response is identical for all users, including `user` in the
cache key unnecessarily creates multiple cache entries.

Conversely, excluding a value that changes the response can cause
incorrect content to be served.

The design question is:

> Which request attributes actually change the response?

## 32. Security Considerations

### CloudFront

-   Use HTTPS.
-   Use Origin Access Control for private S3 origins.
-   Avoid caching personalized content under shared keys.
-   Use signed URLs/cookies where required.

### ElastiCache

-   Place caches in private subnets.
-   Restrict security groups to application clients.
-   Enable encryption in transit and at rest where supported and
    required.
-   Do not expose cache endpoints directly to the Internet.

### DAX

-   Deploy inside a VPC.
-   Restrict security-group access.
-   Use encryption where required.
-   Grant the DAX service role appropriate DynamoDB permissions.

### API Gateway

-   Do not cache sensitive personalized responses unless the cache key
    and authorization model are designed correctly.
-   Use authorization and throttling independently of caching.

## 33. Monitoring Cache Performance

Important metrics/concepts include:

  Service       Useful metric/concept
  ------------- --------------------------------------------------------------
  CloudFront    Cache hit ratio, requests, errors
  ElastiCache   Cache hits/misses, CPU, memory, evictions, connections
  DAX           Cache hits/misses, item/query cache behavior, cluster health
  API Gateway   Latency, cache behavior, request count, errors

A cache should be measured rather than enabled blindly. AWS specifically
recommends load testing API Gateway cache capacity for a suitable
workload. [AWS API Gateway
caching](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-caching.html)

## 34. SAA-C03 Architecture Decision Table

  -----------------------------------------------------------------------
  Scenario                            Recommended answer
  ----------------------------------- -----------------------------------
  Users around the world request      CloudFront
  static images                       

  S3 website needs global low-latency CloudFront
  delivery                            

  API backend receives repeated       API Gateway caching and/or
  identical GET requests              CloudFront depending on
                                      architecture

  Application repeatedly queries      ElastiCache
  relational database                 

  Store user sessions for a           ElastiCache
  distributed application             

  Read-heavy DynamoDB application     DAX can be considered

  Need arbitrary application          ElastiCache
  key/value caching                   

  Need cache close to end users       CloudFront

  Need cache inside VPC close to      ElastiCache/DAX
  application servers                 
  -----------------------------------------------------------------------

## 35. Common SAA-C03 Exam Distinctions

### CloudFront

Think:

``` text
Global users -> Edge cache -> Origin
```

### ElastiCache

Think:

``` text
Application -> In-memory cache -> Database
```

### DAX

Think:

``` text
Application -> DAX -> DynamoDB
```

### API Gateway cache

Think:

``` text
Client -> API Gateway cache -> API backend
```

## 36. Practical Multi-Layer Caching Architecture

A production architecture may use multiple cache layers:

``` text
                         Users
                           |
                           v
                     CloudFront
                           |
                    Cache HIT/MISS
                           |
                           v
                    API Gateway
                           |
                    API cache/MISS
                           |
                           v
                    Application
                           |
                     ElastiCache
                       /       \\
                    HIT         MISS
                                 |
                                 v
                              Database
```

Not every application should use all layers. Each cache adds operational
and consistency considerations.

## 37. Cache Invalidation Strategy

Use one or more of:

### TTL

Best when some staleness is acceptable.

### Explicit invalidation

Useful when data changes must become visible immediately.

### Versioning

For static assets:

``` text
app.v1.js
app.v2.js
app.v3.js
```

The new filename automatically creates a new cache key.

### Event-driven invalidation

A data update can publish an event that causes affected cache entries to
be removed or refreshed.

## 38. Implementation Comparison

  Capability                   Console     CLI         Terraform
  ---------------------------- ----------- ----------- -----------
  Easy initial lab             Excellent   Good        Good
  Repeatability                Low         Medium      High
  Version controlled           No          Scripts     Yes
  Fine-grained automation      Medium      High        High
  Good for teaching concepts   Excellent   Excellent   Excellent
  Production IaC               No          Sometimes   Yes

## 39. Recommended Learning Sequence

For SAA-C03, study caching in this order:

1.  Cache hit/miss and TTL.
2.  Cache-aside/lazy loading.
3.  Write-through caching.
4.  CloudFront edge caching.
5.  CloudFront cache policies and cache keys.
6.  API Gateway response caching.
7.  ElastiCache.
8.  ElastiCache caching strategies.
9.  DAX for DynamoDB.
10. Cache invalidation and stale-data tradeoffs.
11. Security and personalized-content considerations.
12. Architecture selection questions.

## 40. Official AWS Documentation

### Amazon CloudFront

-   [CloudFront Developer
    Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Introduction.html)
-   [Caching and
    availability](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/ConfiguringCaching.html)
-   [Understand cache
    policies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-key-understand-cache-policy.html)
-   [Create cache
    policies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-key-create-cache-policy.html)
-   [Control the cache
    key](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/controlling-the-cache-key.html)
-   [Cache behavior
    settings](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistValuesCacheBehavior.html)
-   [CloudFront
    CLI](https://docs.aws.amazon.com/cli/latest/reference/cloudfront/)

### Amazon ElastiCache

-   [ElastiCache User
    Guide](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/WhatIs.html)
-   [Caching
    strategies](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Strategies.html)
-   [ElastiCache
    CLI](https://docs.aws.amazon.com/cli/latest/reference/elasticache/)

### Amazon DynamoDB Accelerator

-   [DAX Developer
    Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.html)
-   [Create a DAX
    cluster](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.create-cluster.html)
-   [DAX
    Console](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.create-cluster.console.html)
-   [DAX
    CLI](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.create-cluster.cli.html)
-   [DAX cluster
    management](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.cluster-management.html)
-   [DAX CLI
    reference](https://docs.aws.amazon.com/cli/latest/reference/dax/)

### Amazon API Gateway

-   [API Gateway documentation](https://docs.aws.amazon.com/apigateway/)
-   [REST API
    caching](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-caching.html)
-   [REST API
    optimization](https://docs.aws.amazon.com/apigateway/latest/developerguide/rest-api-optimize.html)
-   [API Gateway
    CLI](https://docs.aws.amazon.com/cli/latest/reference/apigateway/)

### AWS Prescriptive Guidance

-   [Database Caching Strategies Using
    Redis](https://docs.aws.amazon.com/whitepapers/latest/database-caching-strategies-using-redis/caching-patterns.html)

### Terraform

-   [Terraform AWS CloudFront
    Distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution.html)
-   [Terraform AWS CloudFront Cache
    Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy.html)
-   [Terraform AWS ElastiCache Replication
    Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group.html)
-   [Terraform AWS API Gateway
    Stage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage.html)
-   [Terraform AWS DAX
    Cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dax_cluster.html)

## 41. Final SAA-C03 Mental Model

``` text
                     CACHING
                        |
       +----------------+----------------+
       |                |                |
       v                v                v
  CloudFront       API Gateway      ElastiCache
       |                |                |
       v                v                v
 Global HTTP       API responses    App/database data
 content
                        |
                        v
                       DAX
                        |
                        v
                    DynamoDB
```

The key SAA-C03 decision is to identify **where the repeated data is
being requested and where the cache should live**:

-   Global web content -\> CloudFront
-   API response caching -\> API Gateway REST API cache
-   General application/database caching -\> ElastiCache
-   DynamoDB-specific acceleration -\> DAX

Caching improves latency and reduces origin/database load, but it
introduces cache-key, TTL, invalidation, consistency, capacity, and
security decisions. A good architecture chooses the cache layer that
matches the access pattern rather than adding caching indiscriminately.
