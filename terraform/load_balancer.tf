# ==============================================================================
# load_balancer.tf - Application Load Balancer (ALB) Configuration
# ==============================================================================
# Creates an internet-facing ALB, Target Group, Listener, and attaches 
# all EC2 instances. Routes port 80 traffic to the instances.
# ==============================================================================

resource "aws_lb_target_group" "main" {
  name     = "${var.project_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "${var.project_prefix}-target-group"
  }
}

resource "aws_lb" "main" {
  name               = "${var.project_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  
  # ✅ FIX: ALB requires subnets in at least 2 different AZs for high availability
  subnets = [
    aws_subnet.public.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "${var.project_prefix}-alb"
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Attach every EC2 instance to the ALB Target Group
resource "aws_lb_target_group_attachment" "this" {
  for_each         = aws_instance.this
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = each.value.id
  port             = 80
}