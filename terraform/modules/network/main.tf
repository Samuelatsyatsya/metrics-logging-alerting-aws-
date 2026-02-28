data "aws_vpc" "default" {
  count   = var.vpc_id == "" ? 1 : 0
  default = true
}

data "aws_vpc" "selected" {
  count = var.vpc_id != "" ? 1 : 0
  id    = var.vpc_id
}

data "aws_subnets" "selected" {
  count = length(var.subnet_ids) == 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.effective_vpc_id]
  }
}

locals {
  effective_vpc_id           = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default[0].id
  effective_vpc_cidr         = var.vpc_id != "" ? data.aws_vpc.selected[0].cidr_block : data.aws_vpc.default[0].cidr_block
  effective_subnet_ids       = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.selected[0].ids
  alb_name                   = "${var.project_name}-alb"
  target_group_name          = substr("${var.project_name}-frontend-tg", 0, 32)
  alb_listener_protocol      = upper(var.alb_listener_protocol)
  effective_alb_egress_cidrs = length(var.alb_egress_cidr_blocks) > 0 ? var.alb_egress_cidr_blocks : [local.effective_vpc_cidr]
  effective_ecs_egress_cidrs = length(var.ecs_service_egress_cidr_blocks) > 0 ? var.ecs_service_egress_cidr_blocks : [local.effective_vpc_cidr]
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ECS ALB"
  vpc_id      = local.effective_vpc_id

  ingress {
    from_port   = var.alb_listener_port
    to_port     = var.alb_listener_port
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.effective_alb_egress_cidrs
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-sg"
  })
}

resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = local.effective_vpc_id

  ingress {
    from_port       = var.frontend_container_port
    to_port         = var.frontend_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.effective_ecs_egress_cidrs
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-sg"
  })
}

resource "aws_lb" "main" {
  name                       = local.alb_name
  internal                   = var.alb_internal
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = local.effective_subnet_ids
  drop_invalid_header_fields = var.alb_drop_invalid_header_fields

  tags = var.tags
}

resource "aws_lb_target_group" "frontend" {
  name        = local.target_group_name
  port        = var.frontend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.effective_vpc_id

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = var.tags
}

resource "aws_lb_listener" "https" {
  count = local.alb_listener_protocol == "HTTPS" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = var.alb_listener_port
  protocol          = "HTTPS"
  ssl_policy        = var.alb_ssl_policy
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  lifecycle {
    precondition {
      condition     = trimspace(var.alb_certificate_arn) != ""
      error_message = "alb_certificate_arn must be set when alb_listener_protocol is HTTPS."
    }
  }
}

resource "aws_lb_listener" "http" {
  count = local.alb_listener_protocol == "HTTP" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = var.alb_listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}
