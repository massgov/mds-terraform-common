module "asg" {
  source        = "../asg"
  name          = var.name
  keypair       = var.keypair
  capacity      = var.capacity
  instance_type = var.instance_type
  ami           = var.ami

  security_groups = [
    var.security_groups,
  ]

  subnets              = var.subnets
  policies             = ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"]
  user_data            = base64encode(data.template_file.instance_init.rendered)
  volume_size          = var.volume_size
  volume_encryption    = var.volume_encryption
  instance_schedule    = var.instance_schedule
  instance_patch_group = var.instance_patch_group
  instance_backup      = var.instance_backup
  schedule             = var.schedule
  schedule_down        = var.schedule_down
  schedule_up          = var.schedule_up

  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

resource "aws_ecs_cluster" "cluster" {
  name = var.name
}

data "template_file" "instance_init" {
  template = file("${path.module}/src/instance_init.yml")

  vars = {
    cluster_name = aws_ecs_cluster.cluster.name
  }
}

