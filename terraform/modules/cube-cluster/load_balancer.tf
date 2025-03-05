locals {
  public_subnets = var.vpc.public_subnets
}

resource "aws_lb" "main" {
  name               = "${var.cluster_prefix}-cube-api-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = local.public_subnets
}

resource "aws_lb_target_group" "main" {
  name                 = "${var.cluster_prefix}-cube-api-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = 5

  health_check {
    path              = "/readyz"
    healthy_threshold = 2
    interval          = 15
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = aws_acm_certificate_validation.lb.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
