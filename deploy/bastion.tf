data "aws_ami" "amazon_linux" { # retrieving info from aws
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.*-x86_64-gp2"] # name of EC2 image, * indicates wild card for latest version
  }
  owners = ["amazon"]
}

resource "aws_instance" "bastion" {            # instance created
  ami           = data.aws_ami.amazon_linux.id # data from above, gets ami id
  instance_type = "t2.micro"
  user_data     = file("./templates/bastion/user-data.sh")

  tags = merge( # allows you to add new tag, merge with common_tags
    local.common_tags,
    map("Name", "${local.prefix}-bastion")
  )
}
