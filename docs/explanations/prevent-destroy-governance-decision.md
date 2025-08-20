# Governance Decision: Should We Enforce `prevent_destroy` in Terraform Configurations?

![Explanation](https://img.shields.io/badge/Diataxis-Explanation-purple?style=for-the-badge&logo=lightbulb)

---

## Context

This page documents the strategic discussion and decision regarding the use of Terraform's `prevent_destroy` lifecycle rule in Power Platform governance modules, specifically in the context of the PPCC25 demonstration and our production workflows.

### Current Protections (as of August 2025)
- **GitHub Actions workflow (`terraform-destroy.yml`)** implements:
  - Manual workflow dispatch (no auto-destroy)
  - Explicit, case-sensitive confirmation ("DESTROY")
  - Production environment protection
  - Pre-destroy validation and resource existence checks
  - State backup before destructive actions
  - OIDC authentication (no stored credentials)
  - JIT network access
  - Comprehensive audit trail

## Analysis: Value of `prevent_destroy`

### Where `prevent_destroy` Adds Value
- **Local CLI execution**: Protects against accidental `terraform destroy` outside CI/CD
- **State drift or corruption**: Prevents unintended resource deletion during recovery
- **Operator error**: Final safeguard against manual mistakes
- **Defense in depth**: Adds a technical control layer beyond process/workflow

### Where Current Protections Are Sufficient
- **All destructive actions go through the workflow**
- **Manual confirmation and audit trail are enforced**
- **Production environment is protected by workflow environment settings**

## Decision for PPCC25 Demonstration

- **Do NOT enforce `prevent_destroy` in demo modules.**
  - Reason: The workflow already demonstrates robust governance and protection.
  - Focus: Keep the demo simple and focused on workflow-based governance.
  - Educational Value: Audience benefits more from seeing process controls than technical redundancy.

## Recommendation for Production Adoption

- **Implement `prevent_destroy` for production modules post-demo.**
  - Reason: Adds defense in depth for real-world operator scenarios.
  - Compliance: Satisfies audit and security requirements for enterprise environments.
  - Implementation: Use conditional logic to enable for production environments only.

## Example Implementation (for future reference)

```hcl
resource "powerplatform_environment" "this" {
  lifecycle {
    prevent_destroy = var.environment.environment_type == "Production"
    # ...existing lifecycle rules...
  }
}
```

## Summary Table

| Context         | Enforce `prevent_destroy`? | Rationale                                      |
|----------------|----------------------------|------------------------------------------------|
| Demo (PPCC25)  | No                         | Workflow protections are sufficient             |
| Production     | Yes                        | Adds defense in depth, protects against errors  |

## Next Steps
- Revisit this decision after PPCC25 based on feedback and operational needs.
- Document any future changes to governance controls in this page.

---

**Maintained by:** Power Platform Governance Team
**Last updated:** August 20, 2025
