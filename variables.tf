
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "access_key" {
  description = "AWS access key"
  type        = string
}

variable "secret_key" {
  description = "AWS secret key"
  type        = string
}

variable "en_bucket_name" {
  type = string
}

variable "es_bucket_name" {
  type = string
}

variable "pt_bucket_name" {
  type = string
}


variable "codepipeline_bucket_name" {
  type = string
}

variable "github_repository_url" {
  type = string
}

