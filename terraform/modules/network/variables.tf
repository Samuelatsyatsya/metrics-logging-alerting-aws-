variable "project_name" {
  description = "Prefix applied to network resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for ALB and security groups. If empty, default VPC is used."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnets for ALB and ECS service. If empty, all subnets in selected VPC are used."
  type        = list(string)
  default     = []
}

variable "frontend_container_port" {
  description = "Frontend container port used by target group"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "ALB target group health check path for the frontend service"
  type        = string
  default     = "/"
}

variable "alb_internal" {
  description = "Whether the ALB should be internal (private)"
  type        = bool
  default     = true
}

variable "alb_drop_invalid_header_fields" {
  description = "Whether ALB should drop invalid HTTP headers"
  type        = bool
  default     = true
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB listener port"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "alb_egress_cidr_blocks" {
  description = "CIDR blocks allowed as ALB egress. If empty, module uses VPC CIDR."
  type        = list(string)
  default     = []
}

variable "ecs_service_egress_cidr_blocks" {
  description = "CIDR blocks allowed as ECS task egress. If empty, module uses VPC CIDR."
  type        = list(string)
  default     = []
}

variable "alb_listener_port" {
  description = "ALB listener port"
  type        = number
  default     = 443
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS ALB listener"
  type        = string
  default     = ""
}

variable "alb_ssl_policy" {
  description = "SSL policy for HTTPS ALB listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}
