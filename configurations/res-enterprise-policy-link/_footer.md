## 🔍 Examples

See the [`tfvars/`](./tfvars/) directory for complete configuration examples:

- [`network-injection-example.tfvars`](./tfvars/network-injection-example.tfvars) - VNet integration policy assignment
- [`encryption-example.tfvars`](./tfvars/encryption-example.tfvars) - Customer-managed key encryption policy

## 🧪 Testing

This module includes comprehensive integration tests:

```bash
# Run all tests
terraform test

# Run format validation
terraform fmt -check -recursive

# Run syntax validation
terraform validate
```

## 🚨 Common Issues

### Policy Assignment Fails

**Symptoms**: Policy assignment returns permission errors or invalid environment

**Solutions**:
1. Verify environment exists and is accessible
2. Check Azure RBAC permissions for enterprise policy assignment
3. For NetworkInjection: Ensure VNet and subnet are properly configured
4. For Encryption: Verify managed environment configuration

### Timeout Errors

**Symptoms**: Operations timeout during create/update/delete

**Solutions**:
1. Increase timeout values in the `timeouts` variable
2. Check Azure and Power Platform service health
3. Verify network connectivity and authentication

### System ID Format Errors

**Symptoms**: Invalid system_id format validation errors

**Solutions**:
1. Verify system_id follows exact ARM format
2. Check region matches environment's Azure region
3. Confirm enterprise policy exists in Azure

## 📚 Learn More

### Microsoft Documentation
- [Power Platform Enterprise Policies](https://docs.microsoft.com/power-platform/admin/managed-environment-overview)
- [VNet Integration for Power Platform](https://docs.microsoft.com/power-platform/admin/managed-environment-sharing-limits)
- [Customer-Managed Keys](https://docs.microsoft.com/power-platform/admin/customer-managed-key)

### PPCC25 Resources
- [Session Materials](../../docs/)
- [Demo Scripts](../../scripts/)
- [Configuration Examples](../)

### Terraform Resources
- [Power Platform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest)
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## 🤝 Contributing

This module is part of the PPCC25 demonstration repository. For improvements or issues:

1. Check existing [issues](../../../../issues) and [pull requests](../../../../pulls)
2. Follow the [contribution guidelines](../../../../CONTRIBUTING.md)
3. Test changes using the included test suite
4. Update documentation for any new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../../../../LICENSE) file for details.

---

**⚡ Power Platform + Terraform = Governance at Scale**

*Part of the PPCC25 "Enhancing Power Platform Governance Through Terraform" demo series*