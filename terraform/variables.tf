
variable "project" {
  description = "<Your Project ID>"
  type        = string
}
variable "region" {
  description = "europe-west1"
  type        = string
}

variable "repository_id" {
  description = "my-artifact-repo"
  type        = string
}
variable "location" {
  description = "europe"
  type        = string
}
variable "format" {
  description = "DOCKER"
  type        = string
}

variable "cluster_name" {
  description = "my-autopilot-clus"
  type        = string
}
variable "network" {
  description = "my-default-vpc"
  type        = string
}
variable "subnetwork" {
  description = "my-default-subnet"
  type        = string
}

variable "deployment_name" {
  description = "my-app"
  type        = string
}
variable "replicas" {
  description = 1
  type        = number
}
variable "image_url" {
  description = "nginx:latest"
  type        = string
}
variable "container_port" {
  description = 80
  type        = number
}

variable "service_name" {
  description = "my-service"
  type        = string
}
variable "service_port" {
  description = 80
  type        = number
}
variable "target_port" {
  description = 80
  type        = number
}
variable "service_type" {
  description = "NodePort"
  type        = string
}

variable "policy_name" {
  type    = string
  default = "my-policy"
}
variable "policy_type" {
  type    = string
  default = "CLOUD_ARMOR"
}