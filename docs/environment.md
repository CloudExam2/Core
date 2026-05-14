
These variables are required for the Terraform provider and the GitHub Actions runner to manage the global AWS environment.

| Variable | Description | Source |
| :--- | :--- | :--- |
| **AWS_ACCESS_KEY_ID** | IAM credentials for provisioning. | GitHub Secrets |
| **AWS_SECRET_ACCESS_KEY** | IAM credentials for provisioning. | GitHub Secrets |
| **AWS_SESSION_TOKEN** | Required for temporary/lab accounts. | GitHub Secrets |
| **AWS_REGION** | Default region (e.g., us-east-1). | Static Config |
| **GH_PAT** | Personal Access Token for GitHub API. | GitHub Secrets |
| **TF_STATE_BUCKET** | S3 bucket for remote terraform state. | providers.tf |

---

## Service repositories (Catalog, Sales, etc.)

**RDS master passwords are not configured in Core.** Each repo that runs its own Terraform for RDS (for example **Catalog**) must define **`DB_PASSWORD`** in **that repository’s** GitHub **Secrets**.

For **Amazon RDS PostgreSQL**, the master password must be **8–128** characters and **cannot** contain `/`, `@`, `"` (double quote), or spaces. If CI fails with `Invalid master password`, update the secret in the **service** repo to meet those rules and run the pipeline again.
