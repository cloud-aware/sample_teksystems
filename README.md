Part 1
1.	Threat Intelligence Report
a.	Types of attack
i.	Zero Day exploit
ii.	Cross Site scripting
iii.	SQL injection
b.	Explain how a vulnerability exploited can provide access to the network
i.	A vulnerability allows the attack to execute code on server, that code can be used to spawn shells or gain privileges
c.	Preventative measures
i.	Regular/Automated patching
ii.	Vulnerability scanning
iii.	Use threat intelligence feeds
iv.	WAF
2.	Incident Reponse Plan
a.	Identify the affected web server and block inbound/outbound traffic
b.	Take a snapshot of the EBS volumes
c.	Scan for malware/vulnerabilities
d.	Review Cloudwatch logs for affected EC2 instance, identify what IP addresses it was communicating with (apart from “normal” or expected traffic); block those IP addresses as necessary
e.	Terminate affected web server
f.	Restore web server from last known good backup / AMI image
g.	Patch new web server to prevent attackers from regaining access
h.	Monitor new web server for unusual activity
i.	Send communications out to necessary parties about incident
j.	Test new web server
3.	Network Security Measures
a.	Implement AWS GuardDuty & integrate w/ SecurityHub for Intrusion Detection / Intrusion Prevention
b.	Implement AWS Web Application Firewall (WAF)
c.	Network segmentation: use private subnets for all EC2 instances and RDS instances.  Web servers can use ELB’s in front for their public IP’s.  Create security groups with a deny-all and least privilege the necessary ports and CIDR’s.
 
Part 2
1.	Docker Security Best Practices
a.	5 best practices:
I came up with the first 2 and had to look up the others because, while I’m familiar with Docker, their best practices were not at the top of my mind.
i.	Use trusted / official images for containers
ii.	Run containers as non-root user
iii.	Enable Content Trust
iv.	Scan images for vulnerabilities
v.	Minimize image size
b.	Dockerfile code: (I’m familiar with docker-compose, so I’ll use that)

version: '3.8'

services:
  web: 
    image: httpd:alpine  # 1. Use Official/Base Images
    ports:
      - "80:80"
      - “443:443”
    volumes:
      - app-data:/app/data:ro # Mount as read-only
    user: "1000:1000" # Run as non-root user
    depends_on:
      - postgres
    security_opt:
      - no-new-privileges:true #prevent container from gaining additional privileges 
    environment:
            - PUID=${PUID} # default user id, defined in .env
            - PGID=${PGID} # default group id, defined in .env
            - TZ=${TZ} # timezone, defined in .env

  postgres: 
    image: postgres:alpine # Use official, minimized Alpine-based image
    user: "1001:1001" # Run as non-root user
    ports:
      - "5432:5432"
    volumes:
      - ${ROOT}/pg/data:/config
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    security_opt:
      - no-new-privileges:true #prevent container from gaining additional privileges
    environment:
            - PUID=${PUID} # default user id, defined in .env
            - PGID=${PGID} # default group id, defined in .env
            - TZ=${TZ} # timezone, defined in .env


2.	Kubernetes Security Configuration
a.	Pod Security Admission – enforce rules like disallowing privileged containers
b.	Network Policies – define ingress/egress rules to control traffic between pods
c.	RBAC – limits user and service account permissions to only necessary resources
d.	YAML:

apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  containers:
  - name: app-container
    image: nginx:latest
    securityContext:
      runAsUser: 1001  # Non-root user
      runAsGroup: 1001
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL  # Drop all capabilities
      readOnlyRootFilesystem: true  # Mount root FS as read-only
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir: {}
3.	IaaS Security Measures
a.	IaaS is a shared responsibility model where the provider manages the hardware and the user handles the software (operating system, applications, data).  The user is responsible for securing their operating systems and applications.  The provider is responsible for securing their hardware (physical access)
