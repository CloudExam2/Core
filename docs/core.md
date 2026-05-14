# 🌐 Global Infrastructure (Core)

This repository serves as the foundational layer for the microservices ecosystem. It follows the **Twelve-Factor App** principles by isolating backing services and environment configuration from application logic.

## AWS student lab constraint

**Outbound internet from workloads:** Some lab accounts restrict arbitrary egress; others allow full internet. This repo’s **VPC uses an Internet Gateway** and a **default `0.0.0.0/0` route** on the shared public route table so EC2 can reach the public internet when your account policy allows it. If your course forbids that, tighten security groups and routing separately.

**First-time setup:** If Terraform cannot run because the **S3 state bucket** does not exist, follow **`docs/bootstrap-lab.md`** (AWS CLI commands).

---

## 🏗️ System Architecture

This repository manages the shared resources that enable communication and routing between independent services:

* **Networking:** Shared **VPC** (`10.0.0.0/16`), **Internet Gateway**, **two public subnets** (two AZs), public route table with **default route to the IGW**. Outputs **`vpc_id`** and **`public_subnet_ids`** are consumed by service repos (e.g. Catalog) via `terraform_remote_state`.
* **API Gateway:** **Regional** REST API in **`terraform/gateway.tf`**. After Catalog has a public URL, set Terraform variable **`catalog_backend_url`** (e.g. `http://1.2.3.4:80`) and re-apply Core so **`/catalog/{proxy+}`** HTTP-proxies to the Catalog EC2. Invoke URL is output as **`api_gateway_invoke_url`**. (A fully private “API inside VPC only” pattern would use NLB + VPC Link; this stack uses the standard regional invoke URL.)
* **Message Broker (SQS):** The asynchronous bridge between services:
  * `catalog-updates-queue`: For syncing Catalog data to the Sales service.
  * `sales-events-queue`: For triggering the Notification service upon a sale.
* **Container Registry (ECR):** Centralized storage for Docker images for all services.

## 📊 Global Observability

* **Unified Dashboard:** A CloudWatch dashboard aggregating metrics from all repositories.
* **Performance Tracking:** Monitors **p50, p90, and p99** latency across the entire system.
* **Behavioral Health:** Visualizes HTTP status distributions (2xx, 4xx, 5xx) to detect system-wide failures.

## 📂 Repository Structure

```text
.
├── .github/workflows/  # Global Infra CI/CD (Terraform Apply)
├── terraform/          # HCL: VPC, API Gateway, SQS, ECR, etc.
│   ├── vpc.tf          # Shared VPC, IGW, public subnets, routes
│   ├── gateway.tf      # Regional REST API + optional /catalog proxy
│   ├── sqs.tf          # Message queues
│   ├── ecrs.tf         # Image repositories
├── README.md           # Project overview
└── docs/
    ├── bootstrap-lab.md # CLI: S3 state bucket and first-run order
    ├── core.md          # Architecture overview
    └── environment.md   # GitHub / TF variables
```
