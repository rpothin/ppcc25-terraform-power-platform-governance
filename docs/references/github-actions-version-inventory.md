# GitHub Actions Version Inventory

![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)

> **Comprehensive version tracking for all GitHub Actions used in workflows**  
> *Ensures consistent security posture and facilitates version updates*

## 📋 Current Action Versions

### Core Actions

| Action                      | Current Version | Latest Available | Status    | Security Notes          |
| --------------------------- | --------------- | ---------------- | --------- | ----------------------- |
| `actions/checkout`          | `v4`            | `v4`             | ✅ Current | Pinned to major version |
| `actions/upload-artifact`   | `v4`            | `v4`             | ✅ Current | Pinned to major version |
| `actions/download-artifact` | `v4`            | `v4`             | ✅ Current | Pinned to major version |

### Infrastructure & Cloud Actions

| Action                      | Current Version | Latest Available | Status    | Security Notes               |
| --------------------------- | --------------- | ---------------- | --------- | ---------------------------- |
| `azure/login`               | `v2.3.0`        | `v2.3.0`         | ✅ Current | Pinned to specific version ✅ |
| `hashicorp/setup-terraform` | `v3.1.2`        | `v3.1.2`         | ✅ Current | Pinned to specific version ✅ |

### Security & Analysis Actions

| Action                              | Current Version | Latest Available | Status    | Security Notes                   |
| ----------------------------------- | --------------- | ---------------- | --------- | -------------------------------- |
| `aquasecurity/trivy-action`         | `0.32.0`        | `0.32.0`         | ✅ Current | **Pinned to specific version** ✅ |
| `github/codeql-action/upload-sarif` | `v3`            | `v3`             | ✅ Current | Pinned to major version          |

### Utility Actions

| Action               | Current Version | Latest Available | Status    | Security Notes               |
| -------------------- | --------------- | ---------------- | --------- | ---------------------------- |
| `dorny/paths-filter` | `v3.0.2`        | `v3.0.2`         | ✅ Current | **Updated from v2** ✅        |
| `mikefarah/yq`       | `v4.46.1`       | `v4.46.1`        | ✅ Current | Pinned to specific version ✅ |

## 🔒 Security Compliance Status

### ✅ Recently Completed Security Improvements

1. **Trivy Action Pinning** (Action 1.1.1 - ✅ **COMPLETED**)
   - **Before**: `aquasecurity/trivy-action@master` ❌ (Unpinned, floating reference)
   - **After**: `aquasecurity/trivy-action@0.32.0` ✅ (Pinned to specific version)
   - **Security Impact**: Eliminates supply chain attack vector from floating references

2. **Paths Filter Update** (Action 1.1.2 - ✅ **COMPLETED**)
   - **Before**: `dorny/paths-filter@v2` ⚠️ (Outdated major version)
   - **After**: `dorny/paths-filter@v3.0.2` ✅ (Latest version with security improvements)
   - **Security Impact**: Latest security patches and improved functionality

3. **Comprehensive Version Updates** (Action 1.1.2 - ✅ **COMPLETED**)
   - `hashicorp/setup-terraform@v3` → `hashicorp/setup-terraform@v3.1.2` ✅
   - `azure/login@v2` → `azure/login@v2.3.0` ✅
   - **Security Impact**: Latest security updates and bug fixes

## 🎯 Security Standards Compliance

### ✅ Fully Compliant Areas
- **No Unpinned Actions**: All actions use specific versions or approved major version pins
- **No Deprecated Actions**: All actions are actively maintained and supported
- **Regular Updates**: Actions are kept current with latest security patches

### 📊 Version Strategy

| Pin Type             | Usage                     | Rationale                                       | Examples                           |
| -------------------- | ------------------------- | ----------------------------------------------- | ---------------------------------- |
| **Specific Version** | Security-critical actions | Maximum security, prevents supply chain attacks | `aquasecurity/trivy-action@0.32.0` |
| **Major Version**    | Stable core actions       | Balance of security and maintenance             | `actions/checkout@v4`              |
| **Floating**         | ❌ None                    | Security risk - not used                        | ~~`action@master`~~                |

## 🔄 Update Procedures

### Automated Update Tracking
- Actions are reviewed quarterly for security updates
- Critical security updates are applied immediately
- Breaking changes are tested in development branches first

### Update Checklist Template
When updating an action version:

1. **Security Review**
   - [ ] Check for security advisories
   - [ ] Review changelog for security fixes
   - [ ] Validate digital signatures (if available)

2. **Compatibility Testing**
   - [ ] Test in development environment
   - [ ] Verify all workflows still function
   - [ ] Check for breaking changes

3. **Documentation Updates**
   - [ ] Update this inventory document
   - [ ] Update workflow improvement plan status
   - [ ] Document any configuration changes needed

## 📈 Version History

### January 2025 Updates
- **2025-01-21**: ✅ Pinned Trivy action to `0.32.0` (was `@master`)
- **2025-01-21**: ✅ Updated paths-filter to `v3.0.2` (was `v2`)
- **2025-01-21**: ✅ Updated Terraform setup to `v3.1.2` (was `v3`)
- **2025-01-21**: ✅ Updated Azure login to `v2.3.0` (was `v2`)

## 🚨 Security Alerts Configuration

### Repository Security Settings
- **Dependabot**: Enabled for GitHub Actions dependencies
- **Security Advisories**: Subscribed to all used action repositories
- **Automatic Updates**: Configured for non-breaking security updates

### Monitoring
- Weekly security scan reports
- Quarterly comprehensive version review
- Immediate response to critical security advisories

## 📝 Notes

- **All Critical Security Issues Resolved**: No unpinned or vulnerable action versions
- **AVM Compliance**: Follows Azure Verified Modules security best practices
- **Workflow Improvement Plan**: Addresses Action 1.1.1 completion requirement
- **Maintenance Schedule**: Updated quarterly or on security advisories

---

**Last Updated**: January 21, 2025  
**Next Review**: April 21, 2025  
**Maintained by**: GitHub Workflows Team  
**Status**: ✅ **All security improvements completed and documented**
