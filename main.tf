locals {
  prefix = (
    var.prefix == null || var.prefix == "" # keep "" for backward compatibility
    ? ""
    : join("-", [var.prefix, lower(var.location), ""])
  )
  name_title = replace(title(var.name), "-", "")
  security_prefix = "${lower(substr(local.name_title, 0, 1))}${substr(local.name_title, 1, 120)}"
  iam_roles = merge([
    for role_name, members in var.iam : {
      for member in members :
          "${role_name}-${member}" => {
            role_name = rolename
            member    =  member
          }
    }
   ])
}

resource "google_storage_bucket" "bucket" {
  name                        = "${local.prefix}${lower(var.name)}"
  project                     = var.project_id
  location                    = var.location
  storage_class               = var.storage_class
  public_access_prevention    = var.public_access_prevention
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = var.uniform_bucket_level_access
  versioning {
    enabled = var.versioning
  }
  labels = merge(var.labels, {
    location      = lower(var.location)
    storage_class = lower(var.storage_class)
  })

  dynamic "autoclass" {
    for_each = var.autoclass == false ? [] : [""]
    content {
      enabled = var.autoclass
    }
  }

  dynamic "encryption" {
    for_each = var.encryption_key == null ? [] : [""]
    content {
      default_kms_key_name = var.encryption_key
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy == null ? [] : [""]
    content {
      retention_period = var.retention_policy.retention_period
      is_locked        = var.retention_policy.is_locked
    }
  }

  dynamic "logging" {
    for_each = var.logging_config == null ? [] : [""]
    content {
      log_bucket        = var.logging_config.log_bucket
      log_object_prefix = var.logging_config.log_object_prefix
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rule == null ? [] : [""]
    content {
      action {
        type          = var.lifecycle_rule.action.type          // "Delete" or "SetStorageClass"
        storage_class = var.lifecycle_rule.action.storage_class // "NEARLINE", "COLDLINE", "ARCHIVE", or "STANDARD"
      }
      condition {
        age                = var.lifecycle_rule.condition.age                // number of days
        created_before     = var.lifecycle_rule.condition.created_before     // RFC 3339 date/time string
        num_newer_versions = var.lifecycle_rule.condition.num_newer_versions // number of versions
        with_state         = var.lifecycle_rule.condition.with_state         // "LIVE", "ARCHIVED", or "ANY"
      }
    }
  }
}

resource "google_storage_bucket_iam_member" "members" {
  for_each = local.iam_roles
  bucket   = google_storage_bucket.bucket.name
  role     = each.value.role_name
  member   = each.value.member
}

resource "google_project_iam_member" "transfer_buckets_list" {
  project = data.google_project.project.name
  role    = google_project_iam_custom_role.storagetransfer_serviceaccount_project.id
  member  = "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}"
  depends_on = [
    google_project_iam_custom_role.storagetransfer_serviceaccount_project
  ]
}

resource "google_storage_bucket_iam_member" "transfer_backup_bucket" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}"
}

resource "google_storage_bucket_iam_member" "transfer_backup_bucket_get" {
  bucket = google_storage_bucket.bucket.name
  role   = google_project_iam_custom_role.storagetransfer_bucket_get.id
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}"
  depends_on = [
    google_project_iam_custom_role.storagetransfer_bucket_get
  ]
}

resource "google_storage_bucket_iam_member" "transfer_source_bucket" {
  bucket = var.source_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}"
}

resource "google_storage_bucket_iam_member" "transfer_source_bucket_get" {
  bucket = var.source_bucket_name
  role   = google_project_iam_custom_role.storagetransfer_bucket_get.id
  member = "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}"
  depends_on = [
    google_project_iam_custom_role.storagetransfer_bucket_get
  ]
}

resource "google_storage_transfer_job" "bucket_nightly_backup" {
  description = "Nightly backup of a bucket"
  project     = data.google_project.project.name

  transfer_spec {
    gcs_data_source {
      bucket_name = var.source_bucket_name
    }
    gcs_data_sink {
      bucket_name = google_storage_bucket.bucket.name
    }
    transfer_options {
      overwrite_objects_already_existing_in_sink = true
      overwrite_when                             = "DIFFERENT"
    }
  }

  schedule {
    schedule_start_date {
      year  = 2023
      month = 4
      day   = 1
    }
    start_time_of_day {
      hours   = 23
      minutes = 30
      seconds = 0
      nanos   = 0
    }
  }

  depends_on = [
    google_project_iam_member.transfer_buckets_list,
    google_storage_bucket_iam_member.transfer_backup_bucket,
    google_storage_bucket_iam_member.transfer_backup_bucket_get,
    google_storage_bucket_iam_member.transfer_source_bucket,
    google_storage_bucket_iam_member.transfer_source_bucket_get
  ]
}