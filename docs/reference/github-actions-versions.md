# GitHub Actions Version Inventory

![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)

**Purpose**: Track GitHub Actions versions for security and maintenance  
**Audience**: Repository maintainers and security teams  
**Last Review**: July 21, 2025  
**Next Review**: October 21, 2025

---

## Overview

This document tracks all GitHub Actions used in workflows to ensure consistent security posture and facilitate version updates.

---

## Current Action Versions

### Core Actions

| Action | Version | Latest | Status | Used In |
|--------|---------|--------|--------|---------|
| `actions/checkout` | `v4` | `v4.2.0` | ✅ Current | All workflows |
| `actions/upload-artifact` | `v4` | `v4.4.3` | ✅ Current | terraform-test, terraform-plan-apply, terraform-destroy, terraform-output |
| `actions/download-artifact` | `v4` | `v4.1.8` | ✅ Current | terraform-plan-apply, terraform-destroy |
| `actions/github-script` | `v7` | `v7.0.1` | ✅ Current | terraform-docs |

### Infrastructure & Cloud Actions

| Action | Version | Latest | Status | Security Notes |
|--------|---------|--------|--------|----------------|
| `azure/login` | `v2.3.0` | `v2.3.0` | ✅ Current | Pinned to specific version |
| `hashicorp/setup-terraform` | `v3.1.2` | `v3.1.2` | ✅ Current | Pinned to specific version |

### Security & Analysis Actions

| Action | Version | Latest | Status | Security Notes |
|--------|---------|--------|--------|----------------|
| `aquasecurity/trivy-action` | `0.32.0` | `0.32.0` | ✅ Current | Pinned to specific version |
| `github/codeql-action/upload-sarif` | `v3` | `v3.27.5` | ✅ Current | Pinned to major version |

### Utility Actions

| Action | Version | Latest | Status | Notes |
|--------|---------|--------|--------|-------|
| `dorny/paths-filter` | `v3.0.2` | `v3.0.2` | ✅ Current | Updated from v2 |
| `mikefarah/yq` | `v4.46.1` | `v4.46.1` | ✅ Current | Pinned to specific version |

---

## Workflow Distribution

| Workflow | Actions Count | Most Critical Actions |
|----------|---------------|----------------------|
| `terraform-test.yml` | 7 | `aquasecurity/trivy-action`, `dorny/paths-filter` |
| `terraform-plan-apply.yml` | 5 | `hashicorp/setup-terraform`, `azure/login` |
| `terraform-destroy.yml` | 5 | `hashicorp/setup-terraform`, `azure/login` |
| `terraform-output.yml` | 4 | `mikefarah/yq`, `hashicorp/setup-terraform` |
| `terraform-import.yml` | 3 | `hashicorp/setup-terraform`, `azure/login` |
| `terraform-docs.yml` | 3 | `dorny/paths-filter`, `actions/github-script` |

---

## Security Compliance Status

### ✅ Current Status: Excellent

All GitHub Actions are up to date with latest available versions.

### Recent Security Improvements (January 2025)

**1. Trivy Action Pinning**:
- Before: `aquasecurity/trivy-action@master` ❌
- After: `aquasecurity/trivy-action@0.32.0` ✅
- Impact: Eliminated supply chain attack vector

**2. Paths Filter Update**:
- Before: `dorny/paths-filter@v2` ⚠️
- After: `dorny/paths-filter@v3.0.2` ✅
- Impact: Latest security patches applied

**3. Comprehensive Updates**:
- `hashicorp/setup-terraform@v3` → `v3.1.2` ✅
- `azure/login@v2` → `v2.3.0` ✅
- All actions current with latest versions ✅

---

## Version Strategy

| Pin Type | Usage | Rationale | Example |
|----------|-------|-----------|---------|
| **Specific Version** | Security-critical | Maximum security | `aquasecurity/trivy-action@0.32.0` |
| **Major Version** | Stable core | Balance of security and maintenance | `actions/checkout@v4` |
| **Floating** | ❌ Never | Security risk | ~~`action@master`~~ |

---

## Update Schedule

| Priority | Timeframe | Criteria | Current Status |
|----------|-----------|----------|----------------|
| **Critical** | < 24h | Security vulnerabilities | ✅ None pending |
| **High** | 1 week | Major version updates | ✅ None pending |
| **Medium** | Monthly | Minor updates, bug fixes | ✅ None pending |
| **Low** | Quarterly | Patch updates | ✅ None pending |

---

## Update Checklist

When updating action versions:

### Security Review
- [ ] Check for security advisories
- [ ] Review changelog for security fixes
- [ ] Validate digital signatures (if available)

### Compatibility Testing
- [ ] Test in development environment
- [ ] Verify all workflows still function
- [ ] Check for breaking changes

### Documentation
- [ ] Update this inventory
- [ ] Document configuration changes
- [ ] Update workflow improvement plan

---

## Version History

### July 2025 Updates
- **2025-07-21**: Comprehensive inventory review
- **2025-07-21**: Confirmed all actions current
- **2025-07-21**: Enhanced documentation
- **2025-07-21**: Added usage matrix

### January 2025 Updates
- **2025-01-21**: Pinned Trivy to `0.32.0`
- **2025-01-21**: Updated paths-filter to `v3.0.2`
- **2025-01-21**: Updated Terraform setup to `v3.1.2`
- **2025-01-21**: Updated Azure login to `v2.3.0`

---

## Security Alerts Configuration

### Repository Settings
- **Dependabot**: Enabled for GitHub Actions
- **Security Advisories**: Subscribed to all action repos
- **Automatic Updates**: Configured for security patches

### Monitoring
- Weekly security scan reports
- Quarterly comprehensive reviews
- Immediate response to critical advisories

---

## Related Documentation

- **[GitHub Automation Standards](/.github/instructions/github-automation.instructions.md)** - Workflow standards
- **[Troubleshooting Guide](../guides/troubleshooting.md)** - Workflow issues
- **[Architecture Decisions](../explanations/architecture-decisions.md)** - Design rationale

---

**Status**: ✅ Perfect security posture - all actions current  
**Maintained By**: GitHub Workflows Team  
**Contact**: [Repository Issues](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/issues)
