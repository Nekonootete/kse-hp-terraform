resource "aws_lb" "this" {
  name               = "alb-${var.project_name}-${var.environment}"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_security_group_id]

  tags = {
    Name        = "alb-${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
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
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy       = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.next.arn
  }
}

resource "aws_lb_target_group" "next" {
  name        = "tg-next-${var.project_name}-${var.environment}"
  port        = var.port_next
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check { path = "/" }

  tags = {
    Name        = "tg-next-${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "rails" {
  name        = "tg-rails-${var.project_name}-${var.environment}"
  port        = var.port_rails
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check { path = "/" }

  tags = {
    Name        = "tg-rails-${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_listener_rule" "rails" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rails.arn
  }
  condition {
    host_header {
      values = ["api.example.com"]
    }
  }
}