resource "random_pet" "solution_storage_name" {
  length    = 2
  separator = "-"
  prefix    = var.app_name
}

resource "google_service_account" "fleetrouting_app" {
  account_id   = var.app_name
  display_name = "Fleet Routing App Service Account"
}

# Optimization IAM
resource "google_project_iam_binding" "cloudoptimization_editor" {
  project = var.project
  role    = "roles/cloudoptimization.editor"

  members = [
    "serviceAccount:${google_service_account.fleetrouting_app.email}",
  ]

  depends_on = [
    google_project_service.x
  ]
}

resource "google_storage_bucket" "app_storage" {
  name                        = random_pet.solution_storage_name.id
  uniform_bucket_level_access = true
  location                    = var.region
  force_destroy               = true
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.app_storage.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.fleetrouting_app.email}"
}

resource "google_project_service" "x" {
  count                      = length(var.service_list)
  service                    = var.service_list[count.index]
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_cloud_run_service" "app-deploy" {
  name     = var.app_name
  location = var.region

  template {
    spec {
      service_account_name = "${google_service_account.fleetrouting_app.email}"
      containers {
        image = var.app_image
        
        env {
          name  = "PROJECT_ID"
          value = var.project
        }
        env {
          name  = "API_ROOT"
          value = "http://localhost:8080/api"
        }
        env {
          name  = "ALLOW_EXPERIMENTAL_FEATURES"
          value = "true"
        }
        env {
          name  = "ALLOW_USER_GCS_STORAGE"
          value = "true"
        }
        env {
          name  = "STORAGE_BUCKET_NAME"
          value = google_storage_bucket.app_storage.name
        }
        env {
          name  = "MAP_API_KEY"
          value = var.api_key
        }        
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = "3"
        "autoscaling.knative.dev/maxScale"      = "100"
        "run.googleapis.com/client-name"        = "terraform"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  autogenerate_revision_name = true
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  depends_on = [ google_cloud_run_service.app-deploy ]
  location = var.region
  service     = var.app_name

  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "null_resource" "edit_cloud_run" {
  depends_on = [ google_cloud_run_service.app-deploy, google_cloud_run_service_iam_policy.noauth ]
  provisioner "local-exec" {
    command = "gcloud run deploy ${var.app_name} --update-env-vars=API_ROOT=${google_cloud_run_service.app-deploy.status[0].url}/api --region ${var.region} --image ${var.app_image}"
  }
}