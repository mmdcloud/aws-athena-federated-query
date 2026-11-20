variable "name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "Controls how you are charged for read and write throughput and how you manage capacity"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  description = "The number of read units for this table"
  type        = number
  default     = null
}

variable "write_capacity" {
  description = "The number of write units for this table"
  type        = number
  default     = null
}

variable "hash_key" {
  description = "The attribute to use as the hash and primary key"
  type        = string
}

variable "range_key" {
  description = "The attribute to use as the range and secondary key"
  type        = string
  default     = null
}

variable "attributes" {
  description = "List of nested attribute definitions: only action for sort and partition keys"
  type = list(object({
    name = string
    type = string
  }))
}

variable "ttl_attribute_name" {
  description = "The name of the table attribute to store the TTL timestamp in"
  type        = string
  default     = null
}

variable "ttl_attribute_enabled" {
  description = "Indicates whether TTL is enabled"
  type        = bool
  default     = false
}

variable "pitr_enabled" {
  description = "Enable Point In Time Recovery"
  type        = bool
  default     = true
}

variable "server_side_encryption_enabled" {
  description = "Whether to enable server-side encryption"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "The ARN of the CMK that should be used for the AWS KMS encryption"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to populate on the table"
  type        = map(string)
  default     = {}
}
