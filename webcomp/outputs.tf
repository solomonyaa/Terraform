output "server_a_public_ip" {
  value = aws_instance.ec2-1.public_ip
}
output "server_b_public_ip" {
  value = aws_instance.ec2-2.public_ip
}
output "s3_image_url" {
  value = "https://${aws_s3_bucket.s3-test-bucket.bucket}.s3.us-east-1.amazonaws.com/${aws_s3_object.my-image.key}"
}
