variable "project" {
  type        = string
  description = "Project to deploy resources to"
}

variable "region" {
  type        = string
  description = "Deployment region"
  default = "europe-west1"
}

variable "api_key" {
  type        = string
  description = "API Key"
}

variable "app_name" {
  default = "fleetrouting-app"
}

variable "app_image" {
  default = "us-docker.pkg.dev/fleetrouting-app-ops/fleetrouting-app/release:4.4.1"
}

variable "service_list" {
  type = list(string)
  default = [
    "orgpolicy.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "mapsfleetrouting.googleapis.com",
    "cloudoptimization.googleapis.com",
    "maps-backend.googleapis.com",
    "static-maps-backend.googleapis.com",
    "distance-matrix-backend.googleapis.com",
    "geocoding-backend.googleapis.com",
    "places-backend.googleapis.com",
    "run.googleapis.com",
    "iap.googleapis.com",
    "secretmanager.googleapis.com",
    "vpcaccess.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "apikeys.googleapis.com",
    "apikeys.googleapis.com"
  ]
}