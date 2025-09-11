---
title: "Known Limitations and Platform Constraints"
description: "Power Platform Terraform integration limitations with practical workarounds for PPCC25 demonstrations"
category: "explanation"
author: "PPCC25 Team"
date: "2025-09-11"
tags: ["limitations", "power-platform", "terraform", "troubleshooting"]
---

# Known Limitations and Platform Constraints

![Explanation](https://img.shields.io/badge/Diataxis-Explanation-purple?style=for-the-badge&logo=lightbulb)

**Purpose**: Document Power Platform limitations that block Terraform automation  
**Audience**: PPCC25 attendees and teams implementing Power Platform IaC  
**Time**: 3-5 minutes reading  

---

## Why This Matters

Power Platform has intentional security controls that sometimes conflict with Infrastructure as Code automation. These aren't bugs—they're platform design decisions that prioritize security over automation convenience.

## 🚫 Current Known Limitations

### Application Admin Resource Teardown Blocking

#### **The Problem**
Terraform destroy fails on `ptn-environment-group` configuration with application admin cleanup errors:

```
Error: Failed to delete system user for application '***' in environment 'd55dae23-ebcf-e76d-b63d-bece332f560c'

Unexpected HTTP status code. Expected: [204 200], received: [403] 403 Forbidden 
{"error":{"code":"0x80040225","message":"The specified user(Id = {0}) is disabled. Consider enabling this user. Additional Details: {1}"}}
```

#### **Why It Happens**
Power Platform requires system users to be in specific states before deletion. Even manual deletion in Power Platform Admin Center fails with:

> *"Failed to delete app user: User with SystemUserId= is not disabled. Please disable the user in the organization before attempting to delete."*

This is **intentional security design** to prevent accidental service disruption.

#### **Impact**
- ❌ Cannot fully automate environment group teardown
- ❌ Demo reset requires manual steps
- ❌ CI/CD cleanup needs manual intervention

#### **Simple Workaround**
**Manual Cleanup (Recommended):**
1. Go to [Power Platform Admin Center](https://admin.powerplatform.microsoft.com/)
2. Navigate to each environment
3. Remove application admin assignments manually
4. Run `terraform destroy -var-file="tfvars/regional-examples.tfvars" -auto-approve`

**Alternative - Remove from State:**
```bash
# Remove problematic resources from Terraform state
terraform state rm 'module.environment_application_admin["0"].powerplatform_environment_application_admin.this'
terraform state rm 'module.environment_application_admin["1"].powerplatform_environment_application_admin.this'
terraform state rm 'module.environment_application_admin["2"].powerplatform_environment_application_admin.this'

# Destroy remaining infrastructure
terraform destroy -var-file="tfvars/regional-examples.tfvars" -auto-approve

# Manual cleanup still needed in Admin Center
```

---

## 📋 Framework for Future Limitations

When encountering new limitations:

### **Quick Assessment**
- **Frequency**: How often will this affect our workflows?
- **Workaround**: Can it be done manually? How complex?
- **Impact**: Does it block critical operations?

### **Decision Matrix**
| Impact          | Low Frequency        | High Frequency               |
| --------------- | -------------------- | ---------------------------- |
| **Low Impact**  | Document only        | Create simple workaround     |
| **High Impact** | Implement workaround | Consider architecture change |

### **Documentation Standard**
For each new limitation:
1. **Clear problem statement** with exact error messages
2. **Why it happens** (platform design vs. bug)
3. **Simple workaround** with step-by-step instructions
4. **Impact assessment** for different use cases