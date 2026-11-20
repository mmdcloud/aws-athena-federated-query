variable "role_name" {
  description = "The name of the IAM role"
  type        = string
}

variable "role_description" {
  description = "The description of the IAM role"
  type        = string
  default     = ""
}

variable "assume_role_policy" {
  description = "The policy that grants an entity permission to assume the role"
  type        = string
}

variable "policy_name" {
  description = "The name of the IAM policy"
  type        = string
}

variable "policy_description" {
  description = "The description of the IAM policy"
  type        = string
  default     = ""
}

variable "policy" {
  description = "The JSON policy document"
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the role and policy"
  type        = map(string)
  default     = {}
}
