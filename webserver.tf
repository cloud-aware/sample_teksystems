provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web-server" {
  ami                         = "ami-abcdef027c9d794b" # Base image
  instance_type     = "t3.medium"
  key_name          = "user-key"
  availability_zone = "us-east-1a"

  subnet_id = "subnet-1234"
  vpc_security_group_ids = ["sg-1234", "sg-4567"]

  root_block_device {
    volume_size = 128
    #device_name = "/dev/sda1"
    volume_type = "gp3"
  }

  tags = {
    Name           = "web-server"
    environment    = "web"
  }

  provisioner "local-exec" { command = "aws ec2 wait instance-status-ok --instance-ids ${self.id}" } # wait for the EC2 instance to up and available
}

resource "ansible_host" "web-server" {
  name   = aws_instance.web-server.private_dns
  groups = ["create-web-server"]

  depends_on = [aws_instance.web-server]
}

resource "ansible_playbook" "web-server_playbook" {
  playbook   = "post-provision.yml"
  name       = aws_instance.web-server.private_dns
  replayable = true
  # verbosity           = 3

  depends_on = [aws_instance.web-server]
}

output "ansible_playbook_stdout" {
  value = ansible_playbook.web-server_playbook.ansible_playbook_stdout
}

output "instance_id" {
  value = aws_instance.web-server.id
}
