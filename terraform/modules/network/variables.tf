variable "project_name" {
  description = "Prefix applied to network resources"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC created by the network module"
  type        = string
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks for public subnets (must include at least two for ALB)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidr_blocks) >= 2
    error_message = "public_subnet_cidr_blocks must contain at least two subnets."
  }
}

variable "public_subnet_azs" {
  description = "Availability zones for public subnets, index-aligned with public_subnet_cidr_blocks"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_azs) >= 2
    error_message = "public_subnet_azs must contain at least two Availability Zones."
  }
}

variable "map_public_ip_on_launch" {
  description = "Whether instances/tasks launched in public subnets receive public IPs by default"
  type        = bool
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support in the VPC"
  type        = bool
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames in the VPC"
  type        = bool
}

variable "frontend_container_port" {
  description = "Frontend container port used by target group"
  type        = number
}

variable "health_check_path" {
  description = "ALB target group health check path for the frontend service"
  type        = string
}

variable "alb_internal" {
  description = "Whether the ALB should be internal (private)"
  type        = bool
}

variable "alb_drop_invalid_header_fields" {
  description = "Whether ALB should drop invalid HTTP headers"
  type        = bool
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB listener port"
  type        = list(string)
}

variable "alb_egress_cidr_blocks" {
  description = "CIDR blocks allowed as ALB egress. If empty, module uses VPC CIDR."
  type        = list(string)
}

variable "ecs_service_egress_cidr_blocks" {
  description = "CIDR blocks allowed as ECS task egress. If empty, module uses VPC CIDR."
  type        = list(string)
}

variable "alb_listener_port" {
  description = "ALB listener port"
  type        = number
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS ALB listener"
  type        = string
}

variable "alb_ssl_policy" {
  description = "SSL policy for HTTPS ALB listener"
  type        = string
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
}
