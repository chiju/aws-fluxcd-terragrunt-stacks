variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "The cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets. If not provided, will auto-generate based on available AZs"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets. If not provided, will auto-generate based on available AZs"
  type        = list(string)
  default     = []
}

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets. If not provided, will auto-generate based on available AZs"
  type        = list(string)
  default     = []
}

variable "create_database_subnets" {
  description = "Whether to create database subnets"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization)"
  type        = bool
  default     = false
}

variable "map_public_ip_on_launch" {
  description = "Map public IP on launch for public subnets"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to capture in flow logs"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_log_traffic_type)
    error_message = "Flow log traffic type must be ALL, ACCEPT, or REJECT."
  }
}

variable "flow_log_retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_log_retention_days)
    error_message = "Flow log retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC Endpoint"
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Enable DynamoDB VPC Endpoint"
  type        = bool
  default     = false
}

variable "interface_vpc_endpoints" {
  description = "Map of interface VPC endpoints to create"
  type        = map(string)
  default     = {}
  # Example:
  # {
  #   "ec2" = "EC2 endpoint"
  #   "ecr.dkr" = "ECR Docker endpoint"
  #   "ecr.api" = "ECR API endpoint"
  #   "logs" = "CloudWatch Logs endpoint"
  # }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets"
  type        = map(string)
  default     = {}
}
