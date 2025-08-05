
# Required Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider for the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  type        = string
}

# EBS CSI Driver Configuration
variable "addon_version" {
  description = "Version of the EBS CSI driver addon (leave empty for latest)"
  type        = string
  default     = ""
}

variable "use_most_recent_version" {
  description = "Use the most recent version of the EBS CSI driver addon"
  type        = bool
  default     = true
}

variable "resolve_conflicts_on_create" {
  description = "How to resolve conflicts when creating the addon"
  type        = string
  default     = "OVERWRITE"
  validation {
    condition     = contains(["NONE", "OVERWRITE"], var.resolve_conflicts_on_create)
    error_message = "resolve_conflicts_on_create must be one of: NONE, OVERWRITE."
  }
}

variable "resolve_conflicts_on_update" {
  description = "How to resolve conflicts when updating the addon"
  type        = string
  default     = "OVERWRITE"
  validation {
    condition     = contains(["NONE", "OVERWRITE", "PRESERVE"], var.resolve_conflicts_on_update)
    error_message = "resolve_conflicts_on_update must be one of: NONE, OVERWRITE, PRESERVE."
  }
}

variable "configuration_values" {
  description = "Configuration values for the EBS CSI driver addon"
  type        = string
  default     = ""
}

variable "create_custom_policy" {
  description = "Create additional custom IAM policy for EBS operations"
  type        = bool
  default     = false
}

# Storage Class Configuration
variable "create_gp2_storage_class" {
  description = "Create gp2 storage class"
  type        = bool
  default     = true
}

variable "create_gp3_storage_class" {
  description = "Create gp3 storage class"
  type        = bool
  default     = false
}

variable "set_gp2_as_default" {
  description = "Set gp2 storage class as default"
  type        = bool
  default     = true
}

variable "set_gp3_as_default" {
  description = "Set gp3 storage class as default"
  type        = bool
  default     = false
}

variable "volume_binding_mode" {
  description = "Volume binding mode for storage classes"
  type        = string
  default     = "WaitForFirstConsumer"
  validation {
    condition     = contains(["Immediate", "WaitForFirstConsumer"], var.volume_binding_mode)
    error_message = "volume_binding_mode must be either 'Immediate' or 'WaitForFirstConsumer'."
  }
}

variable "allow_volume_expansion" {
  description = "Allow volume expansion for storage classes"
  type        = bool
  default     = true
}

variable "reclaim_policy" {
  description = "Reclaim policy for storage classes"
  type        = string
  default     = "Delete"
  validation {
    condition     = contains(["Delete", "Retain"], var.reclaim_policy)
    error_message = "reclaim_policy must be either 'Delete' or 'Retain'."
  }
}

variable "filesystem_type" {
  description = "Default filesystem type for volumes"
  type        = string
  default     = "ext4"
  validation {
    condition     = contains(["ext2", "ext3", "ext4", "xfs"], var.filesystem_type)
    error_message = "filesystem_type must be one of: ext2, ext3, ext4, xfs."
  }
}

# GP2 Parameters
variable "gp2_parameters" {
  description = "Additional parameters for gp2 storage class"
  type        = map(string)
  default     = {}
}

# GP3 Parameters
variable "gp3_parameters" {
  description = "Additional parameters for gp3 storage class"
  type        = map(string)
  default = {
    iops       = "3000"
    throughput = "125"
  }
}

# Custom Storage Classes
variable "custom_storage_classes" {
  description = "Custom storage classes to create"
  type = map(object({
    set_as_default         = bool
    volume_binding_mode    = string
    allow_volume_expansion = bool
    reclaim_policy        = string
    parameters            = map(string)
    labels                = map(string)
  }))
  default = {}
}

variable "storage_class_labels" {
  description = "Labels to apply to all storage classes"
  type        = map(string)
  default     = {}
}

# Volume Snapshot Configuration
variable "create_volume_snapshot_class" {
  description = "Create volume snapshot class"
  type        = bool
  default     = false
}

variable "volume_snapshot_class_name" {
  description = "Name of the volume snapshot class"
  type        = string
  default     = "ebs-csi-aws-vsc"
}

variable "set_volume_snapshot_class_as_default" {
  description = "Set volume snapshot class as default"
  type        = bool
  default     = true
}

variable "volume_snapshot_deletion_policy" {
  description = "Deletion policy for volume snapshots"
  type        = string
  default     = "Delete"
  validation {
    condition     = contains(["Delete", "Retain"], var.volume_snapshot_deletion_policy)
    error_message = "volume_snapshot_deletion_policy must be either 'Delete' or 'Retain'."
  }
}

# Common Tags
variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}