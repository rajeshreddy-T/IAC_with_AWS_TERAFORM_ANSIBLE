# Create A VPC resource with 2 AZs

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my_vpc"
  }
}

# Create 2 availability zones
data "aws_availability_zones" "available" {}

# Create 2 public subnets and 1 private subnet in each availability zone
resource "aws_subnet" "public_subnet_az1" {
  vpc_id = aws_vpc.my_vpc.id

  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "public_subnet_az1"
  }
}

resource "aws_subnet" "public_subnet_az2" {
  vpc_id = aws_vpc.my_vpc.id

  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "public_subnet_az2"
  }
}

resource "aws_subnet" "private_subnet_az1" {
  vpc_id = aws_vpc.my_vpc.id

  cidr_block = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private_subnet_az1"
  }
}

resource "aws_subnet" "private_subnet_az2" {
  vpc_id = aws_vpc.my_vpc.id

  cidr_block = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private_subnet_az2"
  }
}

# Create a security group for the EC2 instances
resource "aws_security_group" "ec2_security_group" {
  name_prefix = "ec2_sg"
  description = "Security group for EC2 instances in the public subnets"

  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an RDS instance
resource "aws_db_instance" "rds_instance" {
  identifier = "my-rds-instance"
  engine = "mysql"
  engine_version = "5.7.22"
  instance_class = "db.t2.micro"
  username = "admin"
  password = "my-password"

  # Put the RDS instance in the private subnet in AZ1
  subnet_group_name = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_az1.id]
}

# Create an EC2 instance in each public subnet
resource "aws_instance" "ec2_instance_az1" {
  ami = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  key_name = "my_key_pair"

  # Put the EC2 instance in the public subnet in AZ1
  subnet_id = aws_subnet.public_subnet_az1.id

  # Attach the EC2 instance to the security group
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  tags = {
    Name = "ec2_instance_az1"
  }
}

resource "aws_instance" "ec2_instance_az2" {
  ami = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  key_name = "my_key_pair"

  # Put the EC2 instance in the public subnet in AZ2
  subnet_id = aws_subnet.public_subnet_az2.id

  # Attach the EC2 instance to the security group
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  tags = {
    Name = "ec2_instance_az2"
  }
}

# Create an internet gateway and attach it to the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw"
  }
}

# Create a route table for the public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Associate the public subnets with the public route table
resource "aws_route_table_association" "public_subnet_az1_association" {
  subnet_id = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_az2_association" {
  subnet_id = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a route table for the private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "private_route_table"
  }
}

# Associate the private subnet with the private route table
resource "aws_route_table_association" "private_subnet_az1_association" {
  subnet_id = aws_subnet.private_subnet_az1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_az2_association" {
  subnet_id = aws_subnet.private_subnet_az2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Add a route to the private subnet route table for the RDS instance
resource "aws_route" "rds_route" {
  route_table_id = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  instance_id = aws_db_instance.rds_instance.id
}

# Create an Application Load Balancer
resource "aws_lb" "my_lb" {
  name = "my-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.ec2_security_group.id]
  subnets = [aws_subnet.public_subnet_az1.id, aws_subnet.public_subnet_az2.id]
}

# Create a target group for the EC2 instances
resource "aws_lb_target_group" "my_target_group" {
  name = "my-target-group"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = aws_vpc.my_vpc.id
}

# Register the EC2 instances with the target group
resource "aws_lb_target_group_attachment" "ec2_instance_az1_attachment" {
 
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id = aws_instance.ec2_instance_az1.id
  port = 80
}

resource "aws_lb_target_group_attachment" "ec2_instance_az2_attachment" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id = aws_instance.ec2_instance_az2.id
  port = 80
}

# Create an API Gateway
resource "aws_api_gateway_rest_api" "my_rest_api" {
  name = "my-rest-api"
}

# Create a resource for the API Gateway
resource "aws_api_gateway_resource" "my_resource" {
  rest_api_id = aws_api_gateway_rest_api.my_rest_api.id
  parent_id = aws_api_gateway_rest_api.my_rest_api.root_resource_id
  path_part = "my-resource"
}

# Create a method for the API Gateway
resource "aws_api_gateway_method" "my_method" {
  rest_api_id = aws_api_gateway_rest_api.my_rest_api.id
  resource_id = aws_api_gateway_resource.my_resource.id
  http_method = "GET"
}

# Create an integration for the API Gateway
resource "aws_api_gateway_integration" "my_integration" {
  rest_api_id = aws_api_gateway_rest_api.my_rest_api.id
  resource_id = aws_api_gateway_resource.my_resource.id
  http_method = aws_api_gateway_method.my_method.http_method
  type = "HTTP"
  integration_http_method = "GET"
  uri = "http://${aws_lb.my_lb.dns_name}/my-app"
}

# Create a deployment for the API Gateway
resource "aws_api_gateway_deployment" "my_deployment" {
  rest_api_id = aws_api_gateway_rest_api.my_rest_api.id
  stage_name = "prod"
}

# Output the public and private subnet IDs, EC2 instance IDs, and RDS instance endpoint
output "public_subnet_ids" {
  value = [aws_subnet.public_subnet_az1.id, aws_subnet.public_subnet_az2.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_subnet_az1.id, aws_subnet.private_subnet_az2.id]
}

output "ec2_instance_ids" {
  value = [aws_instance.ec2_instance_az1.id, aws_instance.ec2_instance_az2.id]
}

output "rds_endpoint" {
  value = aws_db_instance.rds_instance.endpoint
}

output "lb_dns_name" {
  value = aws_lb.my_lb.dns_name
}

output "api_gateway_invoke_url" {
  value = "https://${aws_api_gateway_rest_api.my_rest_api.id}.execute-api.${var.aws_region}.amazonaws.com/prod/my-resource"
}
