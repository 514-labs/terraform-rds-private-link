# List of variables that the user would need to change
# The name of the NLB to be created
variable "nlb_name" {
  description = "The name of the NLB to be created"
  type        = string
  default     = "rds-lb"
}

# The VPC ID of the existing RDS instance
variable "vpc_id" {
  description = "The VPC ID of the existing RDS instance"
  type        = string
}

# The name of the existing RDS cluster
variable "rds_cluster_details" {
  description = "Object containing RDS cluster name and port"
  type = object({
    name = string
    port = number
  })
}

# Enable cross zone load balancing
variable "cross_zone_load_balancing" {
  description = "Enables cross zone load balancing for the NLB"
  type        = bool
  default     = true
}

# List of principals that are allowed to connect to the RDS cluster
variable "allowed_principals" {
  description = "List of principals that are allowed to connect to the RDS cluster"
  type        = list(string)
  default     = ["arn:aws:iam::620936554363:root"]
}

# Endpoint Service Acceptance Required (true/false)
variable "acceptance_required" {
  description = "Endpoint Service Manual Acceptance Required (true/false)"
  default     = true
  type        = bool
}

# Schedule expression for how often to run the Lambda function
variable "schedule_expression" {
  description = "Schedule expression for how often to run the Lambda function"
  type        = string
  default     = "rate(5 minutes)"
}

# Default tags to be applied to the resources
variable "default_tags" {
  description = "Default tags to be applied to the resources"
  type        = map(string)
  default     = {}
}

# For cross-region access, add the regions to the list where you want to connect to your RDS cluster from.
# Empty list means only same-region access is allowed.
variable "supported_regions" {
  description = "The set of regions that will be allowed to create a privatelink connection to the RDS cluster."
  type        = list(string)
  default     = []
}