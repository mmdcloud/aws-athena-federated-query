variable "name" {
  description = "The display name of the alias and Name tag"
  type        = string
}

variable "description" {
  description = "The description of the key as viewed in AWS console"
  type        = string
  default     = "KMS Customer Managed Key"
}

variable "deletion_window_in_days" {
  description = "Duration in days after which the key is deleted upon destruction"
  type        = number
  default     = 30
}

variable "enable_key_rotation" {
  description = "Specifies whether key rotation is enabled"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to the KMS key"
  type        = map(string)
  default     = {}
}
