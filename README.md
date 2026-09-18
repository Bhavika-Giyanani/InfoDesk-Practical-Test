# InfoDesk Cloud / DevOps Practical Test

This repository contains my submission for the InfoDesk Cloud Engineer Intern practical test, covering both required tasks: manually provisioning and monitoring an EC2 web server (Question 1), and provisioning the same kind of infrastructure as code with Terraform (Question 2).

## Repository Structure

```
.
├── Q2 files/          # Terraform configuration for Question 2
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── user_data.sh
├── Screenshots/        # Screenshots documenting both questions
└── README.md
```

---

## Question 1 – AWS EC2 + CloudWatch Monitoring

🎥 **Video walkthrough:** [https://youtu.be/by3Ddl82ir4?si=K49ynU28HhK2_E7F](https://youtu.be/by3Ddl82ir4?si=K49ynU28HhK2_E7F)

### What was done

- Launched an EC2 instance (Amazon Linux) named `infodesk-test-question-one`, using an IAM role with **AWS Systems Manager (SSM)** permissions instead of an SSH key pair, so the instance could be managed via **Session Manager** without exposing any SSH access to the internet.
- Restricted the security group to **inbound HTTP (port 80) only** — no SSH port open — reducing the exposed attack surface.
- Connected to the instance through Session Manager, updated OS packages, installed **Nginx**, and enabled it via `systemctl` so it starts automatically on every reboot.
- Verified the default Nginx page was reachable over HTTP, then replaced the default site with a personal portfolio (cloned from GitHub) by swapping out the contents of Nginx's web root, and reloaded Nginx to confirm the deployment.
- Walked through Nginx's on-disk layout: configuration in `/etc/nginx` (`nginx.conf` + `conf.d`), site content in `/usr/share/nginx/html`, logs (`access.log`, `error.log`) in `/var/log/nginx`, and the running process ID in `/run/nginx.pid`.

### CloudWatch monitoring & alarm

- Created an **SNS topic** (`infodesk-test-cpu-alerts`, Standard type) with an email subscription for alert notifications.
- Enabled **detailed monitoring** on the instance (1-minute metric granularity instead of the default 5 minutes) for faster alarm response.
- Created a **CloudWatch alarm** that triggers when CPU utilization exceeds **70%**, wired to the SNS topic and configured to **stop the instance** on alarm (chosen for easy, safe demonstration).
- Generated an artificial CPU spike on the instance, confirmed the alarm state changed, and confirmed the email notification and instance stop both occurred as expected.

### Troubleshooting approach (documented as required)

If CPU usage stays continuously high in a real scenario:
1. Check current resource usage (e.g. `top`) to identify the process driving load.
2. Check Nginx **access logs** for a genuine traffic surge vs. unusual/bot-like request patterns.
3. If a stuck or runaway process is the cause, investigate and restart/stop the affected service.
4. If the load reflects genuine sustained traffic, scale horizontally with an **Auto Scaling Group behind a load balancer** instead of relying on a single instance.
5. Tune the alarm to require multiple consecutive high readings (e.g. 2–3 evaluation periods) before firing, to avoid false positives from short-lived spikes.

---

## Question 2 – Terraform + AWS Infrastructure

🎥 **Video walkthrough:** [https://youtu.be/wBaQxQNPW8k?si=EEk2CHd-aZ9POicz](https://youtu.be/wBaQxQNPW8k?si=EEk2CHd-aZ9POicz)

All Terraform files live in [`Q2 files/`](./Q2%20files).

### Infrastructure provisioned

- **Networking:** a dedicated VPC (`10.0.0.0/16`) with a public subnet (`10.0.1.0/24`), an Internet Gateway, and a route table sending `0.0.0.0/0` traffic out through the gateway.
- **Security group:** inbound HTTP (port 80) only, all outbound allowed — mirroring the least-exposure approach from Question 1.
- **AMI lookup:** a data source that always resolves to the latest Amazon Linux 2023 AMI, rather than hardcoding an AMI ID.
- **IAM role + instance profile for SSM:** so the instance can be managed via Session Manager, again with no SSH key involved.
- **EC2 instance:** launched into the public subnet with the SSM instance profile attached, bootstrapped via `user_data.sh`.
- **`user_data.sh`:** updates packages, installs `git` and `nginx`, enables/starts Nginx, clones the same portfolio repo used in Question 1, and replaces the default web root content — so the server is fully configured automatically on first boot, with no manual steps.
- **SNS topic + email subscription:** for CPU alert notifications, matching Question 1's setup.
- **CloudWatch alarm:** triggers above 70% CPU utilization, notifying via SNS.

### Variables (`variables.tf`)

| Variable | Description | Default |
|---|---|---|
| `aws_region` | AWS region to deploy into | `us-east-1` |
| `instance_type` | EC2 instance type | `t3.micro` |
| `alert_email` | Email to receive CPU alarm notifications | (set to my email) |

### Outputs (`outputs.tf`)

- `instance_id` – ID of the EC2 instance
- `instance_public_ip` – Public IP of the EC2 instance
- `vpc_id` – ID of the VPC
- `alarm_name` – Name of the CloudWatch alarm

### How it was run

```bash
cd "Q2 files"
terraform init
terraform plan
terraform apply
```

After applying, the Nginx page was verified as reachable at the `instance_public_ip` output. A configuration change (e.g. `instance_type`) was then made and `terraform plan` was run again to review the proposed diff before re-applying. Finally, all resources were torn down with:

```bash
terraform destroy
```

---

## Notes

- Both tasks intentionally avoid SSH entirely, using **SSM Session Manager** for instance access and keeping the security group limited to port 80 — a deliberate, security-conscious choice carried through from the manual setup (Q1) into the Terraform code (Q2).
- Screenshots for each step of both questions are available in the [`Screenshots/`](./Screenshots) folder.
