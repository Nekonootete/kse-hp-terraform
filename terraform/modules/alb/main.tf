resource "aws_lb" "alb" {
  name               = "alb-${var.project_name}-${var.environment}"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]

  tags = {
    Name        = "alb-${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy       = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.next.arn
  }
}

resource "aws_lb_listener_rule" "rails" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rails.arn
  }
  condition {
    host_header {
      values = [var.cdn_fqdn]
    }
  }
}

resource "aws_lb_target_group" "next" {
  name        = "tg-next-${var.project_name}-${var.environment}"
  port        = var.port_next
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path              = "/plans"
    protocol          = "HTTP"
    interval          = 60
    timeout           = 30
    healthy_threshold = 3
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "tg-next-${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "rails" {
  name        = "tg-rails-${var.project_name}-${var.environment}"
  port        = var.port_rails
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path              = "/"
    protocol          = "HTTP"
    interval          = 60
    timeout           = 30
    healthy_threshold = 3
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "tg-rails-${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}
