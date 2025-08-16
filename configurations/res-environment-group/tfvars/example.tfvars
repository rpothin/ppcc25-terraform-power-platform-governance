# Example Environment Group Configuration for Power Platform Governance
#
# This file demonstrates environment group configuration patterns for organizing
# Power Platform environments with consistent governance policies at scale.
# Choose the example that best matches your use case and customize accordingly.
#
# Usage:
#   terraform plan -var-file="example.tfvars"
#   terraform apply -var-file="example.tfvars"

# =============================================================================
# Example 1: DEVELOPMENT ENVIRONMENT GROUP (Recommended Starting Point)
# =============================================================================
# This example creates a basic environment group for development environments

display_name = "Development Environment Group"
description  = "Centralized group for all development environments with standardized governance policies and automated routing for developer-created environments"

# =============================================================================
# Example 2: PRODUCTION ENVIRONMENT GROUP
# =============================================================================
# Use this pattern for production workloads with strict governance

# display_name = "Production Environment Group"
# description  = "Production-grade environment group with enhanced security policies, compliance monitoring, and strict access controls for business-critical workloads"

# =============================================================================
# Example 3: DEPARTMENT-SPECIFIC ENVIRONMENT GROUP
# =============================================================================
# Use this pattern for organizing environments by business unit or department

# display_name = "Finance Department Environment Group"
# description  = "Dedicated environment group for Finance department with specialized compliance requirements, data residency rules, and department-specific governance policies"

# =============================================================================
# Example 4: PROJECT-BASED ENVIRONMENT GROUP
# =============================================================================
# Use this pattern for organizing environments by project or initiative

# display_name = "Customer Portal Project Group"
# description  = "Project-specific environment group for customer portal initiative including development, testing, and production environments with coordinated ALM processes"

# =============================================================================
# Example 5: GEOGRAPHIC ENVIRONMENT GROUP
# =============================================================================
# Use this pattern for organizing environments by geographic region or compliance zone

# display_name = "European Union Environment Group"
# description  = "Geographic environment group for EU operations ensuring GDPR compliance, data residency within EU boundaries, and region-specific governance policies"

# =============================================================================
# Configuration Guidelines
# =============================================================================

# 1. Display Name Best Practices:
#    - Use descriptive names that clearly indicate the group's purpose
#    - Maximum 100 characters for Power Platform compatibility
#    - Consider including organization/department context
#    - Examples: "Finance Dept Environments", "Project Alpha Group", "EU Compliance Group"

# 2. Description Requirements:
#    - Provide detailed context about the group's purpose and scope
#    - Maximum 500 characters for optimal readability
#    - Include governance policies, target environments, and usage guidelines
#    - Mention any special compliance or security requirements

# 3. Environment Group Use Cases:
#    - Organizational Structure: Group by department, team, or business unit
#    - Project Management: Group environments for specific initiatives or applications
#    - Lifecycle Management: Separate groups for dev, test, and production environments
#    - Compliance: Group by geographic region or regulatory requirements
#    - Governance: Apply consistent policies across related environments

# 4. Integration Considerations:
#    - Environment groups can be referenced in tenant settings for automatic routing
#    - Compatible with environment group rule sets for governance policies
#    - Provides discrete outputs for use in downstream Terraform configurations
#    - Supports centralized administration of multiple environments

# 5. Security and Governance:
#    - Environment groups enable consistent policy application at scale
#    - Simplify administration by grouping related environments
#    - Support automated environment routing for developer-created environments
#    - Facilitate compliance monitoring and reporting across environment groups

# =============================================================================
# Common Validation Patterns
# =============================================================================

# Valid Display Names (1-100 characters):
# ✅ "Development Team Alpha"
# ✅ "Finance Department Production Environments"
# ✅ "Customer Portal Project - All Lifecycle Stages"
# ✅ "EU Compliance Environment Group"

# Valid Descriptions (1-500 characters):
# ✅ "Centralized group for development environments with automated testing policies"
# ✅ "Production environment group with enhanced security, audit logging, and compliance monitoring for business-critical applications"
# ✅ "Department-specific group ensuring data governance, user access controls, and specialized workflow approvals"

# Invalid Examples:
# ❌ "" (empty display name)
# ❌ "   " (whitespace-only display name)
# ❌ "This is an extremely long display name that exceeds the one hundred character limit and will fail validation during terraform plan" (> 100 chars)
# ❌ "" (empty description)