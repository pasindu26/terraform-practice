#-----------VPC-------------
resource "aws_vpc" "my_vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "VPC-${var.project_reg[var.provider_region]}-${var.project_env}-${var.project_name}"
  }
}

#----subnet--------

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.my_vpc.id

  count = length(var.public_subnet_cird_block)

  cidr_block              = var.public_subnet_cird_block[count.index]
  availability_zone       = data.aws_availability_zones.us_az_zone.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-${var.project_reg[var.provider_region]}-${var.project_env}-${var.project_name}-public-${data.aws_availability_zones.us_az_zone.names[count.index]}"

  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.my_vpc.id

  count = length(var.private_subnet_cird_block)

  cidr_block        = var.private_subnet_cird_block[count.index]
  availability_zone = data.aws_availability_zones.us_az_zone.names[count.index]
  tags = {
    Name = "subnet-${var.project_reg[var.provider_region]}-${var.project_env}-${var.project_name}-private-${data.aws_availability_zones.us_az_zone.names[count.index]}"

  }
}


#------igw------

resource "aws_internet_gateway" "esis_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "igw-${var.project_reg[var.provider_region]}-${var.project_env}-${var.project_name}"
  }

}


#-----route_table-------

#---Public---
resource "aws_route_table" "route_to_igw" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.esis_igw.id
  }


  tags = {
    Name = "igw-${var.project_reg[var.provider_region]}-${var.project_env}-${var.project_name}"
  }
}

resource "aws_route_table_association" "public_sbt_route_to_igw" {
  count = length(var.public_subnet_cird_block)

  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.route_to_igw.id

}

#--PRIVATE

resource "aws_route_table" "route_to_public_instance" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    /* gateway_id = aws_instance.jumphost_ec2.id888888888888888888888888888888888888 */
    network_interface_id = aws_instance.jumphost_ec2.primary_network_interface_id
  }


  tags = {
    Name = "private-to-ec2-${var.project_reg[var.provider_region]}-${var.project_env}-${var.project_name}"
  }
}

resource "aws_route_table_association" "private_app-to-public_subnet" {
  count = length(var.private_subnet_cird_block)

  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.route_to_public_instance.id

}

#----security_group-----

#---SG-private-app----
resource "aws_security_group" "app_private_app" {
  name        = "sg_private_app"
  description = "Allow ssg traffic to app from jump_host"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "allow_SSH"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH_to_app_from_jumphost" {
  security_group_id = aws_security_group.app_private_app.id
  cidr_ipv4         = "192.168.0.0/24"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_for_app" {
  security_group_id = aws_security_group.app_private_app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#---sg-public-jumphost----
resource "aws_security_group" "public_jumphost" {
  name        = "public_jumphost"
  description = "allow traffic from intenet and access ec2 in private"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "allow_SSH_and_intenet"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_jumphost" {
  security_group_id = aws_security_group.public_jumphost.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_taffic_from_access_ec2" {
  security_group_id = aws_security_group.public_jumphost.id
  cidr_ipv4         = aws_security_group.app_private_app.id
  ip_protocol       = "-1"

}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.public_jumphost.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_key_pair" "jumphost" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDzp2Ilq48DICbQNy2m/92JBhpYvqUGgUMZCLP6+SSIWQvfuLMOb4kdHJbdsKDkW/lkJSZ5GN5n0xkin12jGBAffz3LXxCTPZpyle/01ARwI+uA4MZjrvtyqtaBxurLtpc1nGnbLP2PK/G7H3o8XtS1Sb03ao9xc6TKLGPKb+LoZ+6seJ4voVqgzxmg4kT0S6n3GpF9+dSJJ7m+8EN5cV1EWLO91XS+iquZK8gUIvUiFmK7EaVqOBlev8yraVxlyFUmFyP9HSIryyswWcBi6uhA89pkcSUwCnnAsWOJMrAgFQo4OM6An31laWsfL97J1s5d5xpHLLOd61C9ujrz7xrxKaH5bXjtmYRz4pVzBhXD3e5wpbb6D4Z+aKjDrsDf/cWJf0ITlv+QQ6sMi4L5QPUYcJvSMoOkXKWBYDt8Y8d0g2XNhb6LcBCFunmkF82X+aYJ3wbitSc2SEZeDcjkZyPA8OhW85YHixpZqgjOcrO/rfGlpUPQJbV/U8qB8yCT2g4xYN0TgPWEeJWhl3/aMlJ1di7YkQ3jXAQN2sKCzPDmT1iSG/UoCb8dEBXUjdGkd4OuOiyASBCr9KqjsAvaabbRTMimmjExaK6Gp+JI/FCV8X7fa5AJPS+0tcQdZkwmJVt8b34fOHbn+3TfEutrA7alxpZ8okxcErqt0g1n1PXP3w== hp@NV-kusalt"

  tags = {
    Name    = "kp-${var.project_reg[var.provider_region]}-${var.project_env}-${var.project_name}"
    Project = var.project_name
  }
}


#-----------AWS INSTANCE-------------------
resource "aws_instance" "pravate_app_ec2" {
  count = 2

  ami           = "ami-005fc0f236362e99f"
  instance_type = "t2.micro"
  /* subnet_id     = aws_subnet.test_01[count.index].id */
  subnet_id              = aws_subnet.private_subnet[count.index].id
  vpc_security_group_ids = [aws_security_group.app_private_app]

  tags = {
    Name    = "private_app-public_${data.aws_availability_zones.us_az_zone.names[count.index]}"
    Project = var.project_name
  }

}
resource "aws_instance" "jumphost_ec2" {
  /* count = length(var.public_subnet_cird_block) */

  ami                    = "ami-005fc0f236362e99f"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet[0].id
  vpc_security_group_ids = [aws_security_group.public_jumphost]
  key_name               = aws_key_pair.jumphost.id

  tags = {
    Name    = "private_app-public_${data.aws_availability_zones.us_az_zone.names[0]}"
    Project = var.project_name
  }

}