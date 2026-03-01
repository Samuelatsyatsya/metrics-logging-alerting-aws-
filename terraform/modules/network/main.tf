locals {
  alb_name                   = "${var.project_name}-alb"
  target_group_name          = substr("${var.project_name}-frontend-tg", 0, 32)
  effective_alb_egress_cidrs = length(var.alb_egress_cidr_blocks) > 0 ? var.alb_egress_cidr_blocks : [aws_vpc.main.cidr_block]
  effective_ecs_egress_cidrs = length(var.ecs_service_egress_cidr_blocks) > 0 ? var.ecs_service_egress_cidr_blocks : [aws_vpc.main.cidr_block]
  public_subnet_map = {
    for index, cidr in var.public_subnet_cidr_blocks :
    index => {
      cidr = cidr
      az   = try(var.public_subnet_azs[index], "")
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc"
  })

  lifecycle {
    precondition {
      condition     = length(var.public_subnet_azs) == length(var.public_subnet_cidr_blocks)
      error_message = "public_subnet_azs and public_subnet_cidr_blocks must have the same length."
    }

    precondition {
      condition     = length(distinct(var.public_subnet_azs)) >= 2
      error_message = "At least two distinct Availability Zones are required for ALB subnets."
    }
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnet_map

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-${each.key + 1}"
    Tier = "public"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ECS ALB"
  vpc_id      = aws_vpc.main.id

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
  vpc_id      = aws_vpc.main.id

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
  subnets                    = [for key in sort(keys(aws_subnet.public)) : aws_subnet.public[key].id]
  drop_invalid_header_fields = var.alb_drop_invalid_header_fields

  tags = var.tags
}

resource "aws_lb_target_group" "frontend" {
  name        = local.target_group_name
  port        = var.frontend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

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
  load_balancer_arn = aws_lb.main.arn
  port              = var.alb_listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}
