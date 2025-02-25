variable "cubestore_image" {
  type        = string
  description = "Image for cube store and cube store router"
  default     = "cubejs/cubestore"
}

variable "aws_account_id" {
  description = "Target AWS Account ID"
  type        = string
}