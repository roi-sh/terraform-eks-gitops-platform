output "public_subnets" {
  value = aws_subnet.public_subnet[*].id
}

output "private_subnets" {
  value = aws_subnet.private_subnet[*].id
}

output "sg_group" {
  value = aws_security_group.sg_group.id
}

output "vpc" {
  value = aws_vpc.my_vpc
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg_group.id
}