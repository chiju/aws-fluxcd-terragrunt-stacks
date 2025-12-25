# VPC Module

This module creates a production-ready AWS VPC with industry best practices and security configurations.

## Features

- **Multi-AZ Architecture**: Subnets across multiple availability zones for high availability
- **Three-Tier Network**: Public, private, and database subnets for proper network segmentation
- **NAT Gateway**: Configurable NAT Gateway setup (single or per-AZ) for private subnet internet access
- **VPC Flow Logs**: Network monitoring and security analysis with CloudWatch integration
- **VPC Endpoints**: Optional S3, DynamoDB, and interface endpoints for private AWS service access
- **Security**: Default security group with deny-all rules and proper IAM roles
- **Flexible Configuration**: Extensive variables for customization

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                              VPC                                │
│                         (10.0.0.0/16)                          │
├─────────────────────────────────────────────────────────────────┤
│  Public Subnets                                                 │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │   10.0.1.0/24   │  │   10.0.2.0/24   │                      │
│  │      AZ-a       │  │      AZ-b       │                      │
│  │   [NAT Gateway] │  │   [NAT Gateway] │                      │
│  └─────────────────┘  └─────────────────┘                      │
├─────────────────────────────────────────────────────────────────┤
│  Private Subnets                                                │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │  10.0.10.0/24   │  │  10.0.20.0/24   │                      │
│  │      AZ-a       │  │      AZ-b       │                      │
│  │  [App Servers]  │  │  [App Servers]  │                      │
│  └─────────────────┘  └─────────────────┘                      │
├─────────────────────────────────────────────────────────────────┤
│  Database Subnets (Optional)                                    │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │  10.0.30.0/24   │  │  10.0.40.0/24   │                      │
│  │      AZ-a       │  │      AZ-b       │                      │
│  │   [Databases]   │  │   [Databases]   │                      │
│  └─────────────────┘  └─────────────────┘                      │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  name        = "my-app"
  environment = "prod"
  
  cidr_block           = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

  tags = {
    Project = "MyApp"
    Owner   = "Platform Team"
  }
}
```

### Advanced Usage with Database Subnets and VPC Endpoints

```hcl
module "vpc" {
  source = "./modules/vpc"

  name        = "my-app"
  environment = "prod"
  
  cidr_block            = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]
  database_subnet_cidrs = ["10.0.30.0/24", "10.0.40.0/24"]

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = false  # One NAT Gateway per AZ for HA

  # VPC Flow Logs
  enable_flow_logs         = true
  flow_log_retention_days  = 30
  flow_log_traffic_type    = "ALL"

  # VPC Endpoints
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  
  interface_vpc_endpoints = {
    "ec2"     = "EC2 endpoint"
    "ecr.dkr" = "ECR Docker endpoint"
    "ecr.api" = "ECR API endpoint"
    "logs"    = "CloudWatch Logs endpoint"
  }

  # Subnet-specific tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = "my-app"
  }

  tags = {
    Project     = "MyApp"
    Owner       = "Platform Team"
    Environment = "prod"
  }
}
```

### Cost-Optimized Configuration

```hcl
module "vpc" {
  source = "./modules/vpc"

  name        = "my-app"
  environment = "dev"
  
  cidr_block           = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

  # Cost optimization: Single NAT Gateway
  enable_nat_gateway = true
  single_nat_gateway = true

  # Minimal flow logs retention
  enable_flow_logs        = true
  flow_log_retention_days = 7

  # Essential VPC endpoints only
  enable_s3_endpoint = true

  tags = {
    Project     = "MyApp"
    Environment = "dev"
    CostCenter  = "Development"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for all resources | `string` | n/a | yes |
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| cidr_block | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_cidrs | List of CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | no |
| private_subnet_cidrs | List of CIDR blocks for private subnets | `list(string)` | `["10.0.10.0/24", "10.0.20.0/24"]` | no |
| database_subnet_cidrs | List of CIDR blocks for database subnets | `list(string)` | `[]` | no |
| enable_nat_gateway | Enable NAT Gateway for private subnets | `bool` | `true` | no |
| single_nat_gateway | Use a single NAT Gateway for all private subnets | `bool` | `false` | no |
| enable_flow_logs | Enable VPC Flow Logs | `bool` | `true` | no |
| flow_log_retention_days | Number of days to retain flow logs | `number` | `30` | no |
| enable_s3_endpoint | Enable S3 VPC Endpoint | `bool` | `true` | no |
| enable_dynamodb_endpoint | Enable DynamoDB VPC Endpoint | `bool` | `false` | no |
| interface_vpc_endpoints | Map of interface VPC endpoints to create | `map(string)` | `{}` | no |
| tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| public_subnet_ids | List of IDs of the public subnets |
| private_subnet_ids | List of IDs of the private subnets |
| database_subnet_ids | List of IDs of the database subnets |
| database_subnet_group_name | Name of the database subnet group |
| nat_gateway_ids | List of IDs of the NAT Gateways |
| internet_gateway_id | ID of the Internet Gateway |

## Security Considerations

1. **Default Security Group**: Configured to deny all traffic by default
2. **VPC Flow Logs**: Enabled by default for network monitoring
3. **Private Subnets**: No direct internet access, only through NAT Gateway
4. **Database Subnets**: Isolated tier for database resources
5. **VPC Endpoints**: Reduce data transfer costs and improve security
6. **IAM Roles**: Least privilege access for VPC Flow Logs

## Cost Optimization

1. **Single NAT Gateway**: Use `single_nat_gateway = true` for development environments
2. **VPC Endpoints**: Enable S3 and DynamoDB endpoints to reduce NAT Gateway costs
3. **Flow Log Retention**: Adjust retention period based on compliance requirements
4. **Interface Endpoints**: Only enable required interface endpoints

## Best Practices

1. **Multi-AZ Deployment**: Always use at least 2 availability zones
2. **Network Segmentation**: Use separate subnets for different tiers
3. **Tagging Strategy**: Implement consistent tagging for resource management
4. **CIDR Planning**: Plan IP address space to avoid conflicts
5. **Monitoring**: Enable VPC Flow Logs for security and troubleshooting

## Examples

See the `examples/` directory for complete usage examples:
- Basic VPC setup
- VPC with database subnets
- Cost-optimized configuration
- Production-ready setup with all features

## License

This module is licensed under the MIT License.
