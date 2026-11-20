variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Versioning status for the bucket (bool or Enabled/Suspended)"
  type        = any
  default     = "Enabled"
}

variable "kms_key_arn" {
  description = "KMS Key ARN for bucket server side encryption (default AES256 if null)"
  type        = string
  default     = null
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Number of days after which incomplete multipart uploads are aborted"
  type        = number
  default     = 7
}

variable "expiration_days" {
  description = "Days after which objects expire (0 to disable)"
  type        = number
  default     = 0
}

variable "objects" {
  description = "List of objects to upload to S3"
  type = list(object({
    source = string
    key    = string
  }))
  default = []
}

variable "cors" {
  description = "CORS rules for S3 bucket"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    max_age_seconds = number
  }))
  default = []
}

variable "bucket_policy" {
  description = "Bucket policy in JSON format"
  type        = string
  default     = ""
}

variable "bucket_notification" {
  description = "Map of bucket notifications"
  type = object({
    queue = list(object({
      queue_arn = string
      events    = list(string)
    }))
    lambda_function = list(object({
      lambda_function_arn = string
      events              = list(string)
    }))
  })
  default = {
    queue           = []
    lambda_function = []
  }
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to the bucket"
  type        = map(string)
  default     = {}
}
