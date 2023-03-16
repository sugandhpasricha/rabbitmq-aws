## Application Load Balancer for Port 15672 ##
resource "aws_lb" "rabbitmq_app_lb" {
  name               = "rabbitmq-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.alb_subnets

  enable_deletion_protection = false

  tags = {
    Environment = var.env
  }
}
resource "aws_lb_listener" "rabbitmq_listener" {
  load_balancer_arn = aws_lb.rabbitmq_app_lb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn_alb
    #target_group_arn = aws_lb_target_group.rabbitmq-tg.arn
  }
}

## Network Load Balancer for Port 5672 ##
resource "aws_lb" "rabbitmq_app_nlb" {
  name               = "rabbitmq-app-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.nlb_subnets
  enable_deletion_protection = false

  tags = {
    Environment = var.env
  }
}

resource "aws_lb_listener" "rabbitmq_nlb_listener" {
  load_balancer_arn = aws_lb.rabbitmq_app_nlb.arn
  port              = "5672"
  protocol          = "TCP"
  
  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn_nlb
    #target_group_arn = aws_lb_target_group.rabbitmq-tg.arn
  }
}

