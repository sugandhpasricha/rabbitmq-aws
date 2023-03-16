provider "aws" {
  region = var.aws_region
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

# creates launch template --> autoscaling group --> attach autoscaling group to new target group
module "launch_template" {
  source = "./modules/launch_template"
  image_id = var.image_id
  instance_type = var.instance_type
  vpc_id = var.vpc_id
  subnet_id = var.lt_subnet_id
  security_groups = var.lt_security_groups
  key_name = var.key_name
}

module "load_balancer" {
    source = "./modules/load_balancer"
    target_group_arn_alb = module.launch_template.rabbitmq-tg-arn
    target_group_arn_nlb = module.launch_template.rabbitmq-nlb-tg-arn
    security_groups = var.lb_security_groups
    alb_subnets = var.alb_subnets
    nlb_subnets = var.nlb_subnets
    env = var.env
}