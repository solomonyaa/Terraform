output "vpc_id" {
  value = aws_vpc.my-vpc.id
}
output "public_subnet_1_id" {
  value = aws_subnet.public-sub-1.id
}
output "public_subnet_2_id" {
  value = aws_subnet.public-sub-2.id
}