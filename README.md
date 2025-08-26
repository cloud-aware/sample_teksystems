Part 1

1. Threat Intelligence Report
    1. Types of attack
1. Zero Day exploit
2. Cross Site scripting
3. SQL injection
    2. Explain how a vulnerability exploited can provide access to the network
1. A vulnerability allows the attack to execute code on server, that code can be used to spawn shells or gain privileges
    3. Preventative measures
1. Regular/Automated patching
2. Vulnerability scanning
3. Use threat intelligence feeds
4. WAF
2. Incident Reponse Plan
    1. Identify the affected web server and block inbound/outbound traffic
    2. Take a snapshot of the EBS volumes
    3. Scan for malware/vulnerabilities
    4. Review Cloudwatch logs for affected EC2 instance, identify what IP addresses it was communicating with (apart from “normal” or expected traffic); block those IP addresses as necessary
    5. Terminate affected web server
    6. Restore web server from last known good backup / AMI image
    7. Patch new web server to prevent attackers from regaining access
    8. Monitor new web server for unusual activity
    9. Send communications out to necessary parties about incident
    10. Test new web server
3. Network Security Measures
    1. Implement AWS GuardDuty & integrate w/ SecurityHub for Intrusion Detection / Intrusion Prevention
    2. Implement AWS Web Application Firewall (WAF)
    3. Network segmentation: use private subnets for all EC2 instances and RDS instances. Web servers can use ELB’s in front for their public IP’s. Create security groups with a deny-all and least privilege the necessary ports and CIDR’s.

Part 2

1. Docker Security Best Practices
    1. 5 best practices:  
1. Use trusted / official images for containers
2. Run containers as non-root user
3. Enable Content Trust
4. Scan images for vulnerabilities
5. Minimize image size
    2. Dockerfile code: (I’m familiar with docker-compose, so I’ll use that)

~~~ 
version: '3.8'  
services:  
web:  
image: httpd:alpine # 1. Use Official/Base Images  
ports:  
\- "80:80"  
\- “443:443”  
volumes:  
\- app-data:/app/data:ro # Mount as read-only  
user: "1000:1000" # Run as non-root user  
depends_on:  
\- postgres  
security_opt:  
\- no-new-privileges:true #prevent container from gaining additional privileges  
environment:  
\- PUID=${PUID} # default user id, defined in .env  
\- PGID=${PGID} # default group id, defined in .env  
\- TZ=${TZ} # timezone, defined in .env  
postgres:  
image: postgres:alpine # Use official, minimized Alpine-based image

user: "1001:1001" # Run as non-root user  
ports:  
\- "5432:5432"  
volumes:  
\- ${ROOT}/pg/data:/config  
\- /etc/timezone:/etc/timezone:ro  
\- /etc/localtime:/etc/localtime:ro  
security_opt:  
\- no-new-privileges:true #prevent container from gaining additional privileges  
environment:  
\- PUID=${PUID} # default user id, defined in .env  
\- PGID=${PGID} # default group id, defined in .env  
\- TZ=${TZ} # timezone, defined in .env  

~~~
1. Kubernetes Security Configuration
    1. Pod Security Admission – enforce rules like disallowing privileged containers
    2. Network Policies – define ingress/egress rules to control traffic between pods
    3. RBAC – limits user and service account permissions to only necessary resources
    4. YAML:  

~~~
apiVersion: v1

kind: Pod

metadata:

name: secure-pod

spec:

containers:

\- name: app-container

image: nginx:latest

securityContext:

runAsUser: 1001 # Non-root user

runAsGroup: 1001

allowPrivilegeEscalation: false

capabilities:

drop:

\- ALL # Drop all capabilities

readOnlyRootFilesystem: true # Mount root FS as read-only

volumeMounts:

\- mountPath: /cache

name: cache-volume

volumes:

\- name: cache-volume

emptyDir: {}
~~~
1. IaaS Security Measures
    1. IaaS is a shared responsibility model where the provider manages the hardware and the user handles the software (operating system, applications, data). The user is responsible for securing their operating systems and applications. The provider is responsible for securing their hardware (physical access)

Part 3

1. Terraform & Ansible playbook to automate the deployment of a web server on an EC2 instance:  
    The terraform creates the EC2 instance, waits for it to be online and available, then executes the Ansible playbook against the newly created EC2 instance to configure the web server as needed
~~~
**main.tf:**  
terraform {

backend "http" {}

required_providers {

aws = {

source = "hashicorp/aws"

version = "~> 5.0"

}

ansible = {

version = "~> 1.3.0"

source = "ansible/ansible"

}

}

}  
**webserver.tf:**  
provider "aws" {

region = "us-east-1"

}

resource "aws_instance" "web-server" {

ami = "ami-abcdef027c9d794b" # Base image

instance_type = "t3.medium"

key_name = "user-key"

availability_zone = "us-east-1a"

subnet_id = "subnet-1234"

vpc_security_group_ids = \["sg-1234", "sg-4567"\]

root_block_device {

volume_size = 128

# device_name = "/dev/sda1"

volume_type = "gp3"

}

tags = {

Name = "web-server"

environment = "web"

}

provisioner "local-exec" { command = "aws ec2 wait instance-status-ok --instance-ids ${self.id}" } # wait for the EC2 instance to up and available

}

resource "ansible_host" "web-server" {

name = aws_instance.web-server.private_dns

groups = \["create-web-server"\]

depends_on = \[aws_instance.web-server\]

}

resource "ansible_playbook" "web-server_playbook" {

playbook = "post-provision.yml"

name = aws_instance.web-server.private_dns

replayable = true

\# verbosity = 3

depends_on = \[aws_instance.web-server\]

}

output "ansible_playbook_stdout" {

value = ansible_playbook.web-server_playbook.ansible_playbook_stdout

}

output "instance_id" {

value = aws_instance.web-server.id

}  
**post-provision.yaml:**  
\---

\- hosts: all

gather_facts: yes

pre_tasks:

\- name: install boto3/botocore

pip:

name:

\- boto3

\- botocore

state: latest

extra_args: --user

tasks:

\- name: Install preliminary packages

dnf:

name:

\- python3-urllib3

\- python3

\- jq

\- wget

\- vim

\- perl-devel

\- make

\- nfs-utils

\- bc

\- ghostscript

state: latest

become: true

\- name: copy httpd.conf

copy:

src: files/httpd.conf

dest: /etc/httpd/conf/httpd.conf

mode: 0644

become: true

\- name: init mount dirs

shell: |

# Assets Mount

mkdir -p /var/www/sites-files

chown apache:apache /var/www/sites-files

chmod 755 /var/www/sites-files

# ebs mount

mkdir -p /var/www/html

chmod 755 /var/www/html

become: true

\- name: Add firewalld rules for ssh,http,https

shell: |

sudo firewall-cmd --add-port=80/tcp --permanent

sudo firewall-cmd --add-port=443/tcp --permanent

sudo firewall-cmd --add-port=22/tcp --permanent

sudo firewall-cmd --add-service=http --permanent

sudo firewall-cmd --add-service=https --permanent

sudo firewall-cmd --add-service=ssh --permanent

sudo firewall-cmd --reload

become: true

\- name: Upgrade all packages

dnf:

name: "\*"

state: latest

become: true  
