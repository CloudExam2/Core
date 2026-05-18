variable "github_token" {
  description = "GitHub Personal Access Token for managing repository secrets"
  type        = string
  sensitive   = true
}

variable "catalog_backend_url" {
  type        = string
  description = "Catalog on EC2, e.g. http://1.2.3.4:80 (no trailing slash). Leave empty on first apply; set after Catalog EC2 exists, then re-apply Core."
  default     = ""
}

variable "sales_backend_url" {
  type        = string
  description = "Sales on EC2, e.g. http://1.2.3.4:80 (no trailing slash). Leave empty on first apply; set after Sales EC2 exists, then re-apply Core."
  default     = ""
}