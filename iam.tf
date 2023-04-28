resource "google_project_iam_custom_role" "storagetransfer_serviceaccount_project" {
  role_id     = "${local.security_prefix}.storageTransfer.serviceAccount"
  title       = "Storage Transfer Service Account for ${var.name}"
  description = "Grants additional permissions necessary for Storage Transfer"
  permissions = ["storage.buckets.list"]
}

resource "google_project_iam_custom_role" "storagetransfer_bucket_get" {
  role_id     = "${local.security_prefix}.storageTransfer.bucket.get"
  title       = "Storage Transfer Get Bucket for ${var.name}"
  description = "Grants additional permissions necessary for Storage Transfer"
  permissions = ["storage.buckets.get"]
}