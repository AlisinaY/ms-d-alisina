variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  default     = "msdemo-dev-eks"
}

# --- Database ---
variable "db_host" {
  description = "Postgres DB Host"
  type        = string
  # wird glöscht
  default = "shopping-assistant-db.czcmm4esc0mr.eu-central-1.rds.amazonaws.com"
}

variable "db_name" {
  description = "Postgres DB Name"
  type        = string
  default = "shoppingdb"
}

variable "db_user" {
  description = "Postgres DB Username"
  type        = string
  # wird gelöscht
  default = "postgres"
}

variable "db_password" {
  description = "Postgres DB Password"
  type        = string
  sensitive   = true
  # default wird gelöscht, wenn das Projekt zu Ende ist.
  default = "MySecurePass123!"
}

# --- OpenAI ---
variable "openai_api_key" {
  description = "OpenAI API Key"
  type        = string
  sensitive   = true
  # wird gelöscht 
  default = "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"
}
