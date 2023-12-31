resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster"

  tags = local.common_tags
}

# next 3 resources give permissions required to start tasks
resource "aws_iam_policy" "task_execution_role_policy" {
  name        = "${local.prefix}-task-exec-role-policy" # creates new policy
  path        = "/"                                     # way of organizing policies
  description = "Allow retrieving of images and adding to logs"
  policy      = file("./templates/ecs/task-exec-role.json") # contents of policy
}

resource "aws_iam_role" "task_execution_role" {
  name               = "${local.prefix}-task-exec-role"
  assume_role_policy = file("./templates/ecs/assume-role-policy.json")

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_role_policy.arn # sets it to policy created above
}

# this is required to give permissions to task at runtime
resource "aws_iam_role" "app_iam_role" {
  name               = "${local.prefix}-api-task"
  assume_role_policy = file("./templates/ecs/assume-role-policy.json")

  tags = local.common_tags
}

# creates log group
resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name = "${local.prefix}-api"

  tags = local.common_tags
}

# creating task definitions with following 2
data "template_file" "api_container_definitions" {
  template = file("./templates/ecs/container-definitions.json.tpl")

  vars = {
    app_image         = var.ecr_image_api
    proxy_image       = var.ecr_image_proxy
    django_secret_key = var.django_secret_key
    db_host           = aws_db_instance.main.address
    db_name           = aws_db_instance.main.name
    db_user           = aws_db_instance.main.username
    db_pass           = aws_db_instance.main.password
    log_group_name    = aws_cloudwatch_log_group.ecs_task_logs.name
    log_group_region  = data.aws_region.current.name
    # allowed_hosts            = aws_lb.api.dns_name
    allowed_hosts            = aws_route53_record.app.fqdn # point to custom domain
    s3_storage_bucket_name   = aws_s3_bucket.app_public_files.bucket
    s3_storage_bucket_region = data.aws_region.current.name
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.prefix}-api" # name of task definition
  container_definitions    = data.template_file.api_container_definitions.rendered
  requires_compatibilities = ["FARGATE"] # type of ecs hosting, "serverless"
  network_mode             = "awsvpc"
  cpu                      = 256                                  # determines cost
  memory                   = 512                                  # determines cost
  execution_role_arn       = aws_iam_role.task_execution_role.arn # permissions to execute new task
  task_role_arn            = aws_iam_role.app_iam_role.arn        # permissions determined at runtime

  volume {
    name = "static"
  }

  tags = local.common_tags
}

resource "aws_security_group" "ecs_service" {
  description = "Access for the ECS Service"
  name        = "${local.prefix}-ecs-service"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress { # allow outbound access from service to database
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      aws_subnet.private_a.cidr_block,
      aws_subnet.private_b.cidr_block
    ]
  }

  ingress {          # accept inbound connections from internet to proxy
    from_port = 8000 # proxy port
    to_port   = 8000
    protocol  = "tcp"
    security_groups = [
      aws_security_group.lb.id # only allow requests from load balancer
    ]
  }

  tags = local.common_tags
}

resource "aws_ecs_service" "api" {
  name            = "${local.prefix}-api"
  cluster         = aws_ecs_cluster.main.name          # assigns cluster
  task_definition = aws_ecs_task_definition.api.family # definition created above
  desired_count   = 1                                  # increase as traffic grows, effects cost
  launch_type     = "FARGATE"                          # allows to run tasks without managing servers (serverless)

  network_configuration {
    subnets = [
      aws_subnet.private_a.id, # public handled by load balancer
      aws_subnet.private_b.id
    ]
    security_groups = [aws_security_group.ecs_service.id]
  }

  load_balancer { # register new tasks with target group
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "proxy"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.api_https] # force https to configure before ecs service
}

data "template_file" "ecs_s3_write_policy" { # pull in policy template
  template = file("./templates/ecs/s3-write-policy.json.tpl")

  vars = {
    bucket_arn = aws_s3_bucket.app_public_files.arn
  }
}

resource "aws_iam_policy" "ecs_s3_access" { # create new policy from template
  name        = "${local.prefix}-AppS3AccessPolicy"
  path        = "/"
  description = "Allow access to the recipe app S3 bucket"

  policy = data.template_file.ecs_s3_write_policy.rendered # set new policy to template
}

resource "aws_iam_role_policy_attachment" "ecs_s3_access" { # give access to bucket at runtime
  role       = aws_iam_role.app_iam_role.name
  policy_arn = aws_iam_policy.ecs_s3_access.arn
}
