variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of EC2 key pair in AWS"
  type        = string
}