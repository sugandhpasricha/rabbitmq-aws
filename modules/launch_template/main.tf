resource "aws_launch_template" "rabbitMQcluster" {
  name = "rabbitMQcluster"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 10
      delete_on_termination = true
      volume_type           = "gp3"
    }
  }
  block_device_mappings {
    device_name = "/dev/sdb"

    ebs {
      volume_size           = 10
      delete_on_termination = true
      volume_type           = "gp3"
    }
  }

  ebs_optimized = true

  iam_instance_profile {
    name = "rabbitMQ_asg_role"
  }

  image_id = var.image_id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.instance_type

  key_name = var.key_name

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    subnet_id = var.subnet_id
    security_groups = var.security_groups
    device_index = 0
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Rabbitmq-Cluster"
      service = "rabbitmq"
    }
  }
  user_data = filebase64("./rabbitmq_user_data/rabbitmq_user_data.sh")
}


resource "aws_autoscaling_group" "rabbitmq_asg" {
  availability_zones = ["ap-south-1a"]
  desired_capacity   = 3
  max_size           = 3
  min_size           = 3

  launch_template {
    id      = aws_launch_template.rabbitMQcluster.id
    version = "$Latest"
  }
}

resource "aws_lb_target_group" "rabbitmq-tg" {
  name        = "rabbitmq-tg"
  target_type = "instance"
  port        = 15672
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
}

resource "aws_lb_target_group" "rabbitmq-nlb-tg" {
  name        = "rabbitmq-nlb-tg"
  target_type = "instance"
  port        = 5672
  protocol    = "TCP"
  vpc_id      = var.vpc_id
}

resource "aws_autoscaling_attachment" "asg_attachment_rabbitmq" {
  autoscaling_group_name = aws_autoscaling_group.rabbitmq_asg.id
  lb_target_group_arn    = aws_lb_target_group.rabbitmq-tg.arn
}

resource "aws_autoscaling_attachment" "asg_attachment_rabbitmq_nlb" {
  autoscaling_group_name = aws_autoscaling_group.rabbitmq_asg.id
  lb_target_group_arn    = aws_lb_target_group.rabbitmq-nlb-tg.arn
}

output "rabbitmq-tg-arn" {
  value = aws_lb_target_group.rabbitmq-tg.arn
}

output "rabbitmq-nlb-tg-arn" {
  value = aws_lb_target_group.rabbitmq-nlb-tg.arn
}