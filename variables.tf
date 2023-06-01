variable "uniform_bucket_level_access" {
  description = "Allow using object ACLs (false) or not (true, this is the recommended behavior) , defaults to true (which is the recommended practice, but not the behavior of storage API)."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Optional map to set force destroy keyed by name, defaults to false."
  type        = bool
  default     = false
}

variable "iam" {
  description = "IAM bindings in {ROLE => [MEMBERS]} format."
  type        = map(list(string))
  default     = {}
}

variable "encryption_key" {
  description = "KMS key that will be used for encryption."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to be attached to all buckets."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Bucket location."
  type        = string
  default     = "US"
}

variable "logging_config" {
  description = "Bucket logging configuration."
  type = object({
    log_bucket        = string
    log_object_prefix = string
  })
  default = null
}

variable "name" {
  description = "Bucket name suffix."
  type        = string
}

variable "prefix" {
  description = "Prefix used to generate the bucket name."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Bucket project id."
  type        = string
}

variable "retention_policy" {
  description = "Bucket retention policy."
  type = object({
    retention_period = number
    is_locked        = bool
  })
  default = null
}

variable "lifecycle_rule" {
  description = "Bucket lifecycle rule."
  type = object({
    action = object({
      type          = string
      storage_class = optional(string, null)
    })
    condition = object({
      age                = optional(number, null)
      created_before     = optional(string, null)
      num_newer_versions = optional(number, null)
      with_state         = optional(string, null)
    })
  })
  default = null
}

variable "storage_class" {
  description = "Bucket storage class."
  type        = string
  default     = "MULTI_REGIONAL"
  validation {
    condition     = contains(["STANDARD", "MULTI_REGIONAL", "REGIONAL", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be one of STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "versioning" {
  description = "Enable versioning, defaults to false."
  type        = bool
  default     = false
}

variable "autoclass" {
  description = "Automatically transitions objects in your bucket to appropriate storage classes based on each object's access pattern.  Defaults to false."
  type        = bool
  default     = false
}

variable "public_access_prevention" {
  description = "Prevents public access to a bucket. Acceptable values are inherited or enforced. If inherited, the bucket uses public access prevention, only if the bucket is subject to the public access prevention organization policy constraint."
  type        = string
  default     = "inherited"
}

variable "source_bucket_name" {
  description = "Name of the bucket to backup."
  type        = string
}

variable "schedule" {
  description = "Schedule for the backup job."
  type = object({
    schedule_start_date = object({
      year  = number
      month = number
      day   = number
    })
    schedule_end_date = object({
      year  = number
      month = number
      day   = number
    })
    start_time_of_day = object({
      hours   = number
      minutes = number
      seconds = number
      nanos   = number
    })
    repeat_interval = string
  })
  default = {
    schedule_start_date = {
      year  = 2021
      month = 1
      day   = 1
    }
    schedule_end_date = null
    start_time_of_day = null
    repeat_interval   = null
  }
}