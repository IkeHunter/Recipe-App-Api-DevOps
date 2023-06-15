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
    allowed_hosts     = "*"
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