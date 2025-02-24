variable "cube_image" {
  type        = string
  description = "Image for cube api and refresh worker"
  default     = "cubejs/cube:dev"
}

variable "cubestore_image" {
  type        = string
  description = "Image for cube store and cube store router"
  default     = "cubejs/cubestore"
}
