variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  default     = "my-eks-cluster"
}


variable "db_user" {
  description = "Postgres DB Username"
  type = string
}

variable "db_password" {
  description = "Postgres DB Password"
  type = string
  sensitive = true
}

variable "db_host" {
  description = "Postgres DB Host"
  type        = string
}

variable "db_name" {
  description = "Postgres DB Name"
  type        = string
}

variable "db_user" {
  description = "Postgres DB Username"
  type        = string
}

variable "db_password" {
  description = "Postgres DB Password"
  type        = string
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API Key"
  type        = string
  sensitive   = true
}
