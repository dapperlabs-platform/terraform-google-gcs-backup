data "google_project" "project" {
  project_id = var.project_id
}

data "google_storage_transfer_project_service_account" "default" {
  project = data.google_project.project.name
}