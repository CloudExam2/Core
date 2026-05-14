# Bootstrap a new AWS account / lab (CLI)

Use this when Terraform fails on **`terraform init`** because the **remote state bucket** (or other names in this repo) do not exist yet. Replace the bucket name if `iteso-terraform-state-inaki-69` is already taken globally (S3 bucket names are worldwide unique).

## 1. Prerequisites

- AWS CLI v2 configured (`aws configure` or environment variables).
- Region **`us-east-1`** (must match `providers.tf` / workflows unless you change them everywhere).

## 2. Terraform state bucket (required for Core, Catalog, Sales, …)

```bash
set AWS_REGION=us-east-1

aws s3api create-bucket ^
  --bucket iteso-terraform-state-inaki-69 ^
  --region %AWS_REGION%

aws s3api put-bucket-versioning ^
  --bucket iteso-terraform-state-inaki-69 ^
  --versioning-configuration Status=Enabled
```

On **Linux / macOS** (bash):

```bash
export AWS_REGION=us-east-1

aws s3api create-bucket \
  --bucket iteso-terraform-state-inaki-69 \
  --region "${AWS_REGION}"

aws s3api put-bucket-versioning \
  --bucket iteso-terraform-state-inaki-69 \
  --versioning-configuration Status=Enabled
```

If **`create-bucket`** returns “bucket already exists”, either reuse that bucket or pick a **new unique name** and update **`bucket = "..."`** in every repo’s `terraform/providers.tf` backend block (Core, Catalog, Sales, Notifications, etc.).

## 3. Optional: DynamoDB table for state locking

Terraform backend here uses **S3 only** (no `dynamodb_table` in `backend "s3"`). If you add locking later, create a table and add `dynamodb_table` to the backend block per [HashiCorp docs](https://developer.hashicorp.com/terraform/language/settings/backends/s3).

Example (optional, not wired in this repo by default):

```bash
aws dynamodb create-table \
  --table-name iteso-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## 4. ECR repositories

Core Terraform creates **`catalog-service`**, **`sales-service`**, **`notification-service`** ECR repos when you **apply Core** (see `terraform/ecrs.tf`). Nothing to create manually unless you skip Core.

## 5. API Gateway + Catalog URL (Core)

After **Catalog** is deployed and you know **`http://<EC2_PUBLIC_IP>:80`**:

1. Set GitHub Actions variable **`CATALOG_BACKEND_URL`** on the Core repo (or export locally), **or** pass **`-var='catalog_backend_url=http://x.x.x.x:80'`** when running Terraform.
2. Re-apply **Core** so `gateway.tf` wires **`/catalog/{proxy+}`** to that URL.

Invoke URL is in Terraform output **`api_gateway_invoke_url`**.

## 6. Order of operations (typical)

1. Create S3 state bucket (this doc).
2. **Apply Core** (VPC, ECR, SQS, API shell, …).
3. **Apply Catalog** (reads Core remote state).
4. Set **`catalog_backend_url`** and **apply Core** again for the Catalog proxy route.
