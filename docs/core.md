# 🌐 Global Infrastructure (Core)

This repository serves as the foundational layer for the microservices ecosystem. It follows the **Twelve-Factor App** principles by isolating backing services and environment configuration from application logic.

## AWS student lab constraint

**Outbound internet from workloads:** Student lab accounts often **do not allow** application instances to reach the **public internet** for arbitrary traffic (generic HTTP/HTTPS egress, public package indexes, Docker Hub at runtime, etc.). Treat the lab as **private-by-default**: use **VPC endpoints** (or other AWS-documented private integration) for **ECR, SSM, S3, SQS**, and similar, unless your instructor explicitly permits open egress.

**Internet Gateway (optional in Terraform):** In `terraform/vpc.tf` the **internet gateway and default `0.0.0.0/0` route are commented out** so workloads do not rely on the public internet. **PrivateLink-style access** is provided by **VPC interface endpoints** in `terraform/vpc_endpoints.tf` (ECR API/DKR, SSM, SSM Messages, EC2 Messages) plus an **S3 gateway endpoint**, so traffic to those AWS APIs stays **inside the VPC**. To browse **`http://<public-EC2-IP>/` from your laptop**, you normally need an IGW (or another edge design); without it, use **Session Manager port forwarding** or **API Gateway / VPN** as documented below.

### How PrivateLink / VPC endpoints work (short)

**AWS PrivateLink** is the product name for private connectivity to services. Here we use **VPC interface endpoints** (`Interface` type): AWS creates **elastic network interfaces** inside your subnets with **private IPs**. With **`private_dns_enabled = true`**, names like `ecr.us-east-1.amazonaws.com` resolve to those private IPs **inside the VPC**, so the instance talks to ECR/SSM **without** traversing the public internet. A **gateway endpoint** for **S3** adds a **prefix list route** on the route table (no extra ENI). This does **not** expose your FastAPI port to the internet by itself; it only replaces **internet egress for selected AWS APIs**.

**Reaching your backend from your machine without an IGW:** GitHub Actions runners are **outside** your VPC, so CI **cannot** curl your instance over PrivateLink the same way your laptop would. The Catalog workflow instead runs **`curl` on the instance via SSM** (traffic stays inside AWS). From your laptop, use **`aws ssm start-session`** with **port forwarding** to `localhost`, or put **API Gateway** in front when you build that layer.

---

## 🏗️ System Architecture
This repository manages the shared resources that enable communication and routing between independent services:

*   **Networking:** Shared **VPC** (`10.0.0.0/16`), **two subnets** (two AZs), route table **without** a default internet route by default, optional **IGW commented** in `vpc.tf`, and **VPC endpoints** in `vpc_endpoints.tf` for ECR, SSM, and S3. Outputs `vpc_id` and `public_subnet_ids` are consumed by service repos (e.g. Catalog) via `terraform_remote_state`.
*   **API Gateway (Unified Entry):** Acts as the single entry point. It routes external traffic (e.g., `/catalog/*` or `/sales/*`) to the respective EC2 instances.
*   **Message Broker (SQS):** The asynchronous bridge between services:
    *   `catalog-updates-queue`: For syncing Catalog data to the Sales service.
    *   `sales-events-queue`: For triggering the Notification service upon a sale.
*   **Container Registry (ECR):** Centralized storage for Docker images for all services.

## 📊 Global Observability
*   **Unified Dashboard:** A CloudWatch dashboard aggregating metrics from all repositories.
*   **Performance Tracking:** Monitors **p50, p90, and p99** latency across the entire system.
*   **Behavioral Health:** Visualizes HTTP status distributions (2xx, 4xx, 5xx) to detect system-wide failures.

## 📂 Repository Structure
```text
.
├── .github/workflows/  # Global Infra CI/CD (Terraform Apply)
├── terraform/          # HCL: VPC, SQS, ECR, etc.
│   ├── vpc.tf              # Shared VPC, subnets, route table (IGW optional / commented)
│   ├── vpc_endpoints.tf    # Interface + S3 gateway endpoints (PrivateLink-style AWS access)
│   ├── sqs.tf          # Message queues
│   ├── ecrs.tf         # Image repositories
├── README.md           # Project overview
└── environment.md      # Configuration requirements
```