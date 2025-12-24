variable "name" {
  description = "Name prefix for VPC resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_database_subnets" {
  description = "Whether to create database subnets"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (cost optimization)"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Flow logs retention in days"
  type        = number
  default     = 30
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
  description = "Interface VPC endpoints to create"
  type        = map(string)
  default     = {}
}
