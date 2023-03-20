output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_1a_subnet_id" {
  value = aws_subnet.public_1a.id
}

output "public_1c_subnet_id" {
  value = aws_subnet.public_1c.id
}
