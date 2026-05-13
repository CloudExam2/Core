# 🌐 Global Infrastructure (Core)

This repository serves as the foundational layer for the microservices ecosystem. It follows the **Twelve-Factor App** principles by isolating backing services and environment configuration from application logic.

---

## 🏗️ System Architecture
This repository manages the shared resources that enable communication and routing between independent services:

*   **Networking:** Shared VPC, Subnets, and Security Groups to allow secure internal traffic.
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
├── terraform/          # HCL code for Gateway, SQS, ECR, and VPC
│   ├── gateway.tf      # API Gateway routing
│   ├── sqs.tf          # Message queues
│   ├── ecr.tf          # Image repositories
│   └── monitoring.tf   # Dashboards and Alarms
├── README.md           # Project overview
└── environment.md      # Configuration requirements