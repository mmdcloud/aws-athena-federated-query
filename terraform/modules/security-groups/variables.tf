variable "name" {
  description = "Name of the security group"
  type        = string
}

variable "description" {
  description = "Description of the security group"
  type        = string
  default     = "Security group managed by Terraform"
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    description     = optional(string)
    from_port       = number
    to_port         = number
    protocol        = string
    security_groups = optional(list(string))
    cidr_blocks     = optional(list(string))
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules"
  type = list(object({
    description     = optional(string)
    from_port       = number
    to_port         = number
    protocol        = string
    security_groups = optional(list(string))
    cidr_blocks     = optional(list(string))
  }))
  default = [{
    description     = "Allow all outbound traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = null
  }]
}

variable "tags" {
  description = "Additional tags for the security group"
  type        = map(string)
  default     = {}
}
