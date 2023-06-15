resource "aws_db_subnet_group" "main" { # allows adding multiple subnets to database
  name = "${local.prefix}-main"
  subnet_ids = [ # sits in private subnet
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]

  tags = merge(
    local.common_tags,
    map("Name", "${local.prefix}-main") # add name tag to get name to show up properly in aws
  )
}

# security group allows control of the inbound and outbound access to a resource
resource "aws_security_group" "rds" {
  description = "Allow access to the RDS database instance" # add descriptions to sec. groups to see what they're for
  name        = "${local.prefix}-rds-inbound-access"        # this is sufficient for name in aws
  vpc_id      = aws_vpc.main.id

  ingress { # controls what the rules are for inbound access. 'egress' is for outbound
    protocol  = "tcp"
    from_port = 5432 # db port
    to_port   = 5432

    security_groups = [
      aws_security_group.bastion.id,    # only resources with this group can access
      aws_security_group.ecs_service.id # allow access from ecs service
    ]
  }

  tags = local.common_tags
}

resource "aws_db_instance" "main" {                       # defines main db instance (rds)
  identifier              = "${local.prefix}-db"          # instance name
  name                    = "recipe"                      # db name
  allocated_storage       = 20                            # disk space: 20gb, this effects cost
  storage_type            = "gp2"                         # "general purpose 2", smaller simplier storage
  engine                  = "postgres"                    # defines type of db
  engine_version          = "11.16"                       # postgres version
  instance_class          = "db.t2.micro"                 # type of db server, this is smaller and cheaper
  db_subnet_group_name    = aws_db_subnet_group.main.name # connects subnet group
  password                = var.db_password               # local var password
  username                = var.db_username               # local var username
  backup_retention_period = 0                             # amount of days to store backups of db, effects cost
  multi_az                = false                         # determines if db should be run on multiple availability zones. in prod, recommended to be true
  skip_final_snapshot     = true                          # when destroying, aws will create snapshot. disable to make smoother with tf
  vpc_security_group_ids  = [aws_security_group.rds.id]   # connects to security group

  tags = merge(
    local.common_tags,
    map("Name", "${local.prefix}-main")
  )
}



