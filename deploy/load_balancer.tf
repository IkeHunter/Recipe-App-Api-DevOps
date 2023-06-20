resource "aws_lb" "api" {
  name               = "${local.prefix}-main"
  load_balancer_type = "application" # handles requests at the http/s level, compared to "network" type
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  security_groups = [aws_security_group.lb.id]

  tags = local.common_tags
}

# Target group: group of servers load balancer can forward requests to
resource "aws_lb_target_group" "api" {
  name        = "${local.prefix}-api"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # add address to load balancer via ip
  port        = 8000 # proxy port

  # health check: allows lb to perform regular polls on app to ensure it's running
  health_check {
    path = "/admin/login/" # must return http 200
  }
}

resource "aws_lb_listener" "api" {   # entrypoint to lb
  load_balancer_arn = aws_lb.api.arn # identifies lb
  port              = 80             # port to listen on
  protocol          = "HTTP"         # protocol to make request over

  default_action {
    type             = "forward"                   # forward request to target group
    target_group_arn = aws_lb_target_group.api.arn # to this target group
  }
}

resource "aws_security_group" "lb" {
  description = "Allow access to Application Load Balancer"
  name        = "${local.prefix}-lb"
  vpc_id      = aws_vpc.main.id

  ingress { # accept all in
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress { # only allow proxy out
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}