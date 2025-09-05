variable "test_name" {
  description = <<-HEREDOC
    Display name for the test environment and managed environment configuration.
    
    This variable defines the naming for the test resources created to validate
    sequential deployment of environments followed by managed environment enablement.
    
    Example:
    ```hcl
    test_name = "test-seq-validation"
    ```
  HEREDOC
  type        = string
  default     = "test-environment-managed-sequence"

  validation {
    condition     = length(var.test_name) > 0 && length(var.test_name) <= 50
    error_message = "Test name must be between 1 and 50 characters long."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.test_name))
    error_message = "Test name can only contain alphanumeric characters, hyphens, and underscores."
  }
}

variable "location" {
  description = <<-HEREDOC
    Power Platform location for test environment creation.
    
    Specifies the geographic location where the test environment will be provisioned.
    This should match your organization's data residency requirements.
    
    Example:
    ```hcl
    location = "unitedstates"
    ```
  HEREDOC
  type        = string
  default     = "unitedstates"

  validation {
    condition = contains([
      "unitedstates", "europe", "asia", "australia", "india", "japan",
      "canada", "southamerica", "unitedkingdom", "france", "germany",
      "switzerland", "korea", "norway", "singapore"
    ], var.location)
    error_message = "Location must be a valid Power Platform region."
  }
}

variable "security_group_id" {
  description = <<-HEREDOC
    Azure AD security group GUID for Dataverse environment security.
    
    This security group controls access to the test Dataverse environment.
    The group should contain users who need access to the test environment.
    
    Example:
    ```hcl
    security_group_id = "12345678-1234-1234-1234-123456789012"
    ```
  HEREDOC
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.security_group_id))
    error_message = "Security group ID must be a valid GUID format."
  }
}



variable "enable_comprehensive_logging" {
  description = <<-HEREDOC
    Enable comprehensive logging for debugging sequential deployment issues.
    
    When enabled, provides detailed logging of environment states, timing,
    and validation checkpoints to aid in troubleshooting URL and timing errors.
    
    Example:
    ```hcl
    enable_comprehensive_logging = true
    ```
  HEREDOC
  type        = bool
  default     = true
}