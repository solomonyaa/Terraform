
resource "aws_s3_bucket" "s3-test-bucket" {
  bucket = "solomon-tf-test-bucket"

  tags = {
    Name = "My bucket"
  }
}

resource "aws_s3_object" "my-html" {
  bucket       = aws_s3_bucket.s3-test-bucket.id
  key          = "index.html"
  content_type = "text/html"
  source       = "${path.module}/example.html"
}

resource "aws_s3_object" "my-image" {
  bucket = aws_s3_bucket.s3-test-bucket.id
  key = "my-test-image.jpg"
  content_type = "image/jpeg"
  source       = "${path.module}/sample-image.jpg"
}

resource "aws_efs_file_system" "my-efs" {
  # This prevents duplicate EFS creation
  creation_token = "my-efs"

  tags = {
    Name = "shared-filesystem"
  }
}

resource "aws_efs_mount_target" "mount_target_subnet-1" {
  file_system_id = aws_efs_file_system.my-efs.id
  subnet_id      = var.public_subnet_1_id
  security_groups = [aws_security_group.my_security_group.id]
}

resource "aws_efs_mount_target" "mount_target_subnet-2" {
  file_system_id = aws_efs_file_system.my-efs.id
  subnet_id      = var.public_subnet_2_id
  security_groups = [aws_security_group.my_security_group.id]
}


####################################################################


resource "aws_security_group" "my_security_group" {
  name        = "my_security_group"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.my_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.my_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_efs" {
  security_group_id = aws_security_group.my_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 2049
  ip_protocol       = "tcp"
  to_port           = 2049
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.my_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


resource "aws_instance" "ec2-1" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t2.micro"
  subnet_id              = var.public_subnet_1_id
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
  key_name = "solomon's-key-pair"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<EOF
#!/bin/bash
yum install -y amazon-efs-utils
mkdir /mnt/efs
pip3 install botocore
for i in 1 2 3 4 5; do
  mount -t efs ${aws_efs_file_system.my-efs.id}:/ /mnt/efs && break
  sleep 30
done
if [ ! -f /mnt/efs/index.html ]; then
  aws s3 cp s3://${aws_s3_bucket.s3-test-bucket.bucket}/index.html /mnt/efs/index.html
fi
yum install -y docker
systemctl start docker
systemctl enable docker
docker run -d -p 80:80 -v /mnt/efs:/usr/share/nginx/html:ro nginx
EOF

  tags = {
    Name = "Instance A"
  }
}

resource "aws_instance" "ec2-2" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  subnet_id = var.public_subnet_2_id
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
  key_name = "solomon's-key-pair"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<EOF
#!/bin/bash
yum install -y amazon-efs-utils
mkdir /mnt/efs
pip3 install botocore
for i in 1 2 3 4 5; do
  mount -t efs ${aws_efs_file_system.my-efs.id}:/ /mnt/efs && break
  sleep 30
done
amazon-linux-extras install -y nginx1
systemctl start nginx
systemctl enable nginx
rm -rf /usr/share/nginx/html
ln -s /mnt/efs /usr/share/nginx/html
EOF

  tags = {
    Name = "Instance B"
  }
}


resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.s3-test-bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.s3-test-bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.s3-test-bucket.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-read-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-read-profile"
  role = aws_iam_role.ec2_role.name
}