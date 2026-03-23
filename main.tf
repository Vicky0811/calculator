provider "aws"{
    profile="${var.profile}"
    region = "${var.region}"
}
resource "aws_instance" "Jenkins-server"{
    ami = "${var.amis}"
    instance_type= "t3.small"
    tags = {Name="Jenkins-server"}
    key_name = "project-arovm"
    vpc_security_group_ids=["sg-03041bf59a541bfef"]
}

resource "aws_instance" "K8S_master"{
    ami = "${var.amis}"
    instance_type= "c7i-flex.large"
    tags = {Name="Cal-K8S-Master"}
    key_name = "project-arovm"
    vpc_security_group_ids=["sg-0d0d16ea201f54d62"]
}

resource "aws_instance" "K8S_Worker"{
    ami = "${var.amis}"
    instance_type= "c7i-flex.large"
    tags = {Name="Cal-K8S-Worker"}
    key_name = "project-arovm"
    vpc_security_group_ids=["sg-0d0d16ea201f54d62"]
}

output "jenkins_ip" {
  value = aws_instance.Jenkins-server.public_ip
}

output "master_ip" {
  value = aws_instance.K8S_master.public_ip
}

output "worker_ip" {
  value = aws_instance.K8S_Worker.public_ip
}
