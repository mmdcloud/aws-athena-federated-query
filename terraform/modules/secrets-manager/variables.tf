variable "name" {
  description = "Friendly name of the new secret"
  type        = string
}

variable "description" {
  description = "Description of the secret"
  type        = string
  default     = ""
}

variable "recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret"
  type        = number
  default     = 0
}

variable "kms_key_id" {
  description = "ARN or Id of the AWS KMS key to be used to encrypt the secret values"
  type        = string
  default     = null
}

variable "secret_string" {
  description = "Specifies text data that you want to encrypt and store in this version of the secret"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "A mapping of tags to assign to the secret"
  type        = map(string)
  default     = {}
}

variable "replica" {
  description = "A set of replica configurations for the secret"
  type = set(object({
    region     = string
    kms_key_id = optional(string)
  }))
  default = []
}
