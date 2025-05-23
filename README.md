# two-path-ingress-routing-eks
# Kubernetes Multi-Application Deployment Overview

This documentation describes a complete Kubernetes deployment setup that hosts two web applications (Nginx and Apache) behind an AWS Application Load Balancer (ALB) in an Amazon EKS cluster.

## Architecture Overview

The deployment consists of:
- **Two web applications**: Nginx (root path) and Apache (custom path)
- **AWS Load Balancer Controller** for managing ALB resources
- **Application Load Balancer** for internet-facing traffic distribution
- **Path-based routing** to direct traffic to appropriate services

## Components Breakdown

### 1. Namespace and Service Account

**Namespace**: All application resources are deployed in the `luit` namespace.

**Service Account** (`sa.yaml`):
- Creates `aws-load-balancer-controller` service account in `kube-system` namespace
- Associates with IAM role `AmazonEKSLoadBalancerControllerRole` for AWS permissions
- Enables the load balancer controller to manage AWS resources

### 2. Application Deployments

#### Nginx Deployment (`nginx-deployment.yaml`)
- **Replicas**: 3 instances for high availability
- **Image**: `public.ecr.aws/docker/library/nginx:stable-bookworm`
- **Labels**: `app: nginx-web`
- **Health Checks**: 
  - Liveness probe: HTTP GET on port 80, starts after 30s, checks every 10s
  - Readiness probe: HTTP GET on port 80, starts after 30s, checks every 10s
- **Resource Limits**: 
  - Requests: 64Mi memory, 100m CPU
  - Limits: 128Mi memory, 250m CPU

#### Apache Deployment (`apache-deployment.yaml`)
- **Replicas**: 3 instances for high availability
- **Image**: `public.ecr.aws/docker/library/httpd:latest`
- **Labels**: `app: apache`
- **Custom Configuration**: 
  - Creates `/apache` directory in document root
  - Serves custom welcome message at `/apache/index.html`
- **Health Checks**:
  - Liveness probe: HTTP GET on port 80, starts after 10s, checks every 10s
  - Readiness probe: HTTP GET on port 80, starts after 5s, checks every 5s

### 3. Services

#### Nginx Service (`service-nginx.yaml`)
- **Name**: `nginx-service`
- **Selector**: `app: nginx-web`
- **Port Mapping**: TCP port 80 → target port 80

#### Apache Service (`service-apache.yaml`)
- **Name**: `apache-service`
- **Selector**: `app: apache`
- **Port Mapping**: TCP port 80 → target port 80

### 4. Ingress Configuration

**ALB Ingress** (`ingress.yaml`):
- **Name**: `luit-ingress`
- **Ingress Class**: `alb` (AWS Load Balancer Controller)
- **Scheme**: Internet-facing
- **Target Type**: IP-based routing
- **Listen Ports**: HTTP on port 80
- **Health Check Path**: `/`
- **Load Balancer Group**: `luit-group`

**Routing Rules**:
- **Root Path** (`/`): Routes to `nginx-service:80`
- **Apache Path** (`/apache`): Routes to `apache-service:80`

### 5. IAM Permissions

**IAM Policy** (`iam_policy.json`):
Comprehensive permissions for the AWS Load Balancer Controller including:

- **Service Linked Roles**: Create ELB service-linked roles
- **EC2 Permissions**: Describe VPCs, subnets, security groups, instances
- **ELB Permissions**: Full lifecycle management of load balancers and target groups
- **Security Group Management**: Create, modify, and delete security groups
- **Certificate Management**: ACM and IAM server certificates
- **WAF Integration**: Associate/disassociate Web ACLs
- **Shield Integration**: Manage DDoS protection

## Traffic Flow

1. **External Traffic** hits the internet-facing Application Load Balancer
2. **ALB** evaluates path-based routing rules:
   - Requests to `/` → Forward to Nginx pods via `nginx-service`
   - Requests to `/apache` → Forward to Apache pods via `apache-service`
3. **Services** distribute traffic across healthy pod replicas
4. **Pods** serve the requested content

## Key Features

- **High Availability**: 3 replicas for each application
- **Health Monitoring**: Comprehensive liveness and readiness probes
- **Path-Based Routing**: Single ALB serving multiple applications
- **Resource Management**: CPU and memory limits for Nginx
- **Custom Content**: Apache serves customized content under `/apache`
- **Security**: Least-privilege IAM permissions for controller
- **Scalability**: Kubernetes-native scaling capabilities

## Deployment Notes

- Replace `<aws-account-number>` in the service account with your actual AWS account ID
- Ensure the AWS Load Balancer Controller is installed in your EKS cluster
- The ALB will be automatically created and configured based on the ingress annotations
- All resources use the `luit` namespace for organization and isolation
