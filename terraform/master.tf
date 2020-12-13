resource "aws_lb" "this" {
  name               = "${var.project}-${var.env}"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.subnet_public_ids

  enable_deletion_protection = false

  tags = {
    Name    = "${var.project}-${var.env}"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${var.project}-${var.env}-controlplane"
  port     = 6443
  protocol = "TCP"
  vpc_id   = module.vpc.vpc.id
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_launch_template" "master" {
  name_prefix            = "${var.project}-${var.env}-master-"
  image_id               = data.aws_ami.this.id
  instance_type          = "r5a.large"
  vpc_security_group_ids = [aws_security_group.this.id]
  user_data              = base64encode(file("./requirements.sh"))

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = "gp2"
      volume_size           = 200
      delete_on_termination = true
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  monitoring {
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  name_prefix               = "${var.project}-${var.env}-master-"
  max_size                  = 10
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = module.vpc.subnet_public_ids
  health_check_grace_period = 120
  default_cooldown          = 60
  metrics_granularity       = "1Minute"
  enabled_metrics           = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.master.id
        version = aws_launch_template.master.latest_version
      }

      override {
        instance_type = "r5a.large"
      }

      override {
        instance_type = "r5.large"
      }
    }
    instances_distribution {
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "lowest-price"
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-${var.env}-master"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project
    propagate_at_launch = true
  }

  tag {
    key                 = "Env"
    value               = var.env
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}