---
mode: agent
description: "Creates new Terraform configurations aligned with Azure Verified Modules (AVM) principles and repository standards using a template-based approach."
---

# 🚀 Terraform Configuration Initialization (Strict Template-Based)

You are tasked with creating a new Terraform configuration aligned with Azure Verified Modules (AVM) principles and repository standards. This process **MUST** use the provided template directory for maximum consistency and maintainability. **Never create or overwrite template files from scratch.**

## 📋 Task Definition

**Create a new Terraform configuration using the standardized template, then apply classification-specific customization.**

### Required Information Collection

Before proceeding, **MUST** collect the following information from the user:

1. **AVM Module Classification** (Required):
  - `res-*` - **Resource Module**: Deploy primary Power Platform resources
  - `ptn-*` - **Pattern Module**: Deploy multiple resources as a pattern
  - `utl-*` - **Utility Module**: Implement reusable data sources/functions

2. **Configuration Name** (Required):
  - Must follow naming convention: `{classification}-{descriptive-name}`
  - Examples: `res-dlp-policy`, `ptn-environment`, `utl-export-dlp-policies`

3. **Primary Purpose** (Required):
  - Brief description of what the configuration will accomplish

4. **Environment Support** (Optional):
  - Whether multi-environment support is needed (creates tfvars/ subdirectory)
  - Default: Single environment unless specified

---

## 🏗️ Initialization Workflow

### Phase 1: Template-Based Foundation (MANDATORY)

⚠️ **CRITICAL**: You must NEVER manually create template files. Always use the copy operation below.

1. **MANDATORY: Verify Template Exists**
  - First use `list_dir` to confirm `.github/terraform-configuration-template/` exists
  - Verify template contains: `_header.md`, `_footer.md`, `.terraform-docs.yml`
  - **STOP** if template directory is missing or incomplete

2. **MANDATORY: Copy Template Directory Using Terminal Command**
  - Execute in terminal: `cp -r .github/terraform-configuration-template configurations/{configuration-name}`
  - **NEVER** use create_file or other tools to recreate template content
  - Use `list_dir` to confirm all template files were copied successfully

3. **MANDATORY: Read Copied Template Files**
  - Use `read_file` to read the copied `_header.md` and `_footer.md` from the new configuration directory
  - **DO NOT** read from the template directory - only from the copied files
  - Verify the copied files contain placeholder variables ({{PLACEHOLDER}})

4. **MANDATORY: Inventory All Placeholders**
  - Scan the copied `_header.md` and `_footer.md` for ALL `{{PLACEHOLDER}}` variables
  - List every placeholder found before proceeding
  - **DO NOT** rewrite template content—only replace placeholders

5. **MANDATORY: Replace Placeholders Systematically**
  - Create a mapping of placeholder-to-value using user input and classification logic
  - Replace ALL placeholders in the copied files using editing tools
  - **NEVER** alter the template structure or add/remove sections

6. **Validate Template Copy Process**
  - Confirm `.terraform-docs.yml` contains `header-from: "_header.md"` and `footer-from: "_footer.md"`
  - Verify `_header.md` and `_footer.md` no longer contain placeholder variables
  - **STOP** if template wasn't copied properly or placeholders weren't replaced correctly

### Phase 2: Classification-Specific Customization

5. **Generate Core Files**
  - Create `versions.tf`, `main.tf` based on classification
6. **Add Variables** (res-*, ptn-*, utl-*)
  - Create `variables.tf` with input parameters if needed
7. **Add Outputs** (utl-*, some res-* and ptn-*)
  - Create `outputs.tf` for anti-corruption layer/data export if required
8. **Create tfvars** (res-*, ptn-*)
  - Generate `tfvars/` directory and environment files if multi-environment support is needed
9. **Create Tests**
  - Add `tests/integration.tftest.hcl` with basic validation

### Phase 3: Finalization

10. **Validate Structure**
  - Ensure AVM compliance and repository standards
11. **Update Changelog**
  - Add entry for new configuration

---

## ⚡ Execution Instructions (STRICT)

🚨 **NEVER CREATE TEMPLATE FILES MANUALLY** 🚨

1. **Confirm Understanding**: State the configuration to be created and its classification
2. **Validate Inputs**: Ensure naming follows conventions and requirements are clear
3. **MANDATORY: Copy Template First**: Use `cp -r` command to copy template directory - NEVER create files manually
4. **Verify Copy Success**: Confirm all template files were copied before proceeding
5. **Replace Placeholders Only**: Only modify placeholder values, never alter template structure
6. **Customize for Classification**: Add/modify files as needed for resource, pattern, or utility module
7. **Test and Document**: Validate syntax and update changelog

---

## 📁 File Structure (After Initialization)

```
configurations/{configuration-name}/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md (automatically generated by GitHub Actions when new configuration is pushed)
├── .terraform-docs.yml
├── _header.md
├── _footer.md
├── tests/
│   └── integration.tftest.hcl
└── tfvars/
   ├── dev.tfvars
   ├── staging.tfvars
   └── prod.tfvars
```

---

## 📝 Notes

- The template provides a consistent starting point for all configurations. **Never rewrite or bypass it.**
- Placeholder replacement ensures documentation and metadata are always up to date. **Always inventory and replace all placeholders.**
- Classification-specific logic (resource, pattern, utility) is applied after the template is in place.

---

## 📋 Required Placeholder Inventory

**Configuration Metadata:**
- `{{CONFIGURATION_TITLE}}` - Human-readable title
- `{{CONFIGURATION_NAME}}` - Technical name (e.g., utl-export-connectors)
- `{{PRIMARY_PURPOSE}}` - Brief purpose description

**Use Cases (4 required):**
- `{{USE_CASE_1}}` through `{{USE_CASE_4}}`
- `{{USE_CASE_1_DESCRIPTION}}` through `{{USE_CASE_4_DESCRIPTION}}`

**Workflow Integration:**
- `{{WORKFLOW_TYPE}}` - Type of workflow integration
- `{{TFVARS_EXAMPLE}}` - Example tfvars if applicable

**AVM Compliance:**
- `{{TFFR2_IMPLEMENTATION}}` - Anti-corruption layer implementation
- `{{CLASSIFICATION_PURPOSE}}` - Purpose based on classification
- `{{CLASSIFICATION_DESCRIPTION}}` - Classification-specific description

**Troubleshooting:**
- `{{PERMISSION_CONTEXT}}` - Permission context for the resource type
- `{{TROUBLESHOOTING_SPECIFIC}}` - Configuration-specific troubleshooting

**Documentation:**
- `{{RESOURCE_DOCUMENTATION_TITLE}}` - Official docs title
- `{{RESOURCE_DOCUMENTATION_URL}}` - Official docs URL

---

## 📋 Classification-Specific Placeholder Values

**For utl-* (Utility Modules):**
- `{{CLASSIFICATION_PURPOSE}}`: "Data Export and Analysis"
- `{{CLASSIFICATION_DESCRIPTION}}`: "Provides reusable data sources without deploying resources"
- `{{TFFR2_IMPLEMENTATION}}`: "outputting discrete computed attributes instead of full resource objects"
- `{{WORKFLOW_TYPE}}`: "Data Export Workflows"

**For res-* (Resource Modules):**
- `{{CLASSIFICATION_PURPOSE}}`: "Resource Deployment"
- `{{CLASSIFICATION_DESCRIPTION}}`: "Deploys primary Power Platform resources following WAF best practices"
- `{{TFFR2_IMPLEMENTATION}}`: "outputting resource IDs and computed attributes as discrete outputs"

**For ptn-* (Pattern Modules):**
- `{{CLASSIFICATION_PURPOSE}}`: "Pattern Implementation"
- `{{CLASSIFICATION_DESCRIPTION}}`: "Deploys multiple resources using composable patterns"
- `{{TFFR2_IMPLEMENTATION}}`: "outputting key resource identifiers and computed values from the pattern"

---

## 🔍 Final Validation Checklist

Before considering the task complete, verify:
- [ ] Template directory was copied using `cp -r` command (not manually created)
- [ ] All placeholder variables have been replaced with actual values
- [ ] No template structure was altered (only placeholders replaced)
- [ ] `.terraform-docs.yml` points to the correct header/footer files
- [ ] All required files exist in the new configuration directory

**Ready to proceed? Please provide the module classification, configuration name, and primary purpose.**