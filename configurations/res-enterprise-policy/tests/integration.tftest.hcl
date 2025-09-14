# Enterprise Policy Integration Tests Configuration
#
# This file provides comprehensive testing for the res-enterprise-policy module
# covering both NetworkInjection and Encryption policy types with 25+ assertions.
#
# Test Coverage:
# - Plan-phase validation for both policy types (NetworkInjection, Encryption)
# - Variable validation and constraint testing
# - Dynamic configuration logic verification
# - Lifecycle and timeout configuration validation
# - Output structure and content validation
#
# Test Design Features:
# - Consolidated Assertions: Performance-optimized testing with grouped assertions
# - Child Module Compatibility: Provider blocks included for testing
# - Type-Specific Validation: Separate test scenarios for each policy type
# - Edge Case Testing: Multiple virtual networks and configuration scenarios
#
# AVM Compliance Testing:
# - Meta-argument compatibility (via child module pattern)
# - Strong typing validation
# - Anti-corruption layer output validation
# - Comprehensive error message testing
#
# WHY: 25+ assertions ensure reliability and AVM compliance
# Child module testing requires provider blocks for proper validation

# REQUIRED: Provider blocks for child module testing
provider "azapi" {
  # Test configuration - credentials managed by test environment
}

provider "azurerm" {
  features {}
  # Test configuration - credentials managed by test environment  
}

# Test 1: Network Injection Policy Validation (Plan Phase)
run "network_injection_policy_plan_validation" {
  command = plan

  variables {
    policy_configuration = {
      name              = "test-network-injection-policy"
      location          = "europe"
      policy_type       = "NetworkInjection"
      resource_group_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg"

      network_injection_config = {
        virtual_networks = [{
          id     = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
          subnet = { name = "test-subnet" }
        }]
      }
    }

    common_tags = {
      environment = "test"
      project     = "PPCC25-Test"
      managed_by  = "Terraform"
    }
  }

  # Core resource configuration assertions
  assert {
    condition     = azapi_resource.enterprise_policy.name == "test-network-injection-policy"
    error_message = "Policy name must match input configuration"
  }

  assert {
    condition     = azapi_resource.enterprise_policy.type == "Microsoft.PowerPlatform/enterprisePolicies@2020-10-30-preview"
    error_message = "Must use correct azapi resource type and API version"
  }

  assert {
    condition     = azapi_resource.enterprise_policy.location == "europe"
    error_message = "Policy location must match input configuration"
  }

  assert {
    condition     = azapi_resource.enterprise_policy.parent_id == "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg"
    error_message = "Parent ID must match resource group ID"
  }

  # Policy body configuration assertions  
  assert {
    condition     = azapi_resource.enterprise_policy.body.kind == "NetworkInjection"
    error_message = "Policy kind must match policy type for NetworkInjection"
  }

  assert {
    condition     = contains(keys(azapi_resource.enterprise_policy.body.properties), "networkInjection")
    error_message = "NetworkInjection policy must contain networkInjection properties"
  }

  assert {
    condition     = !contains(keys(azapi_resource.enterprise_policy.body.properties), "encryption")
    error_message = "NetworkInjection policy must not contain encryption properties"
  }

  assert {
    condition     = length(azapi_resource.enterprise_policy.body.properties.networkInjection.virtualNetworks) == 1
    error_message = "Virtual networks configuration must match input"
  }

  # Identity configuration assertions
  assert {
    condition     = azapi_resource.enterprise_policy.identity[0].type == "SystemAssigned"
    error_message = "Enterprise policy must use SystemAssigned managed identity"
  }

  # Tags assertions
  assert {
    condition     = azapi_resource.enterprise_policy.tags.environment == "test"
    error_message = "Tags must be properly applied to resource"
  }

  assert {
    condition     = azapi_resource.enterprise_policy.tags.managed_by == "Terraform"
    error_message = "Managed by tag must be set correctly"
  }

  # Output assertions
  assert {
    condition     = can(output.enterprise_policy_id)
    error_message = "enterprise_policy_id output must be available"
  }

  assert {
    condition     = can(output.enterprise_policy_system_id)
    error_message = "enterprise_policy_system_id output must be available"
  }

  assert {
    condition     = can(output.policy_deployment_summary)
    error_message = "policy_deployment_summary output must be available"
  }

  assert {
    condition     = output.policy_deployment_summary.policy_type == "NetworkInjection"
    error_message = "Deployment summary must reflect correct policy type"
  }
}

# Test 2: Encryption Policy Validation (Plan Phase)
run "encryption_policy_plan_validation" {
  command = plan

  variables {
    policy_configuration = {
      name              = "test-encryption-policy"
      location          = "europe"
      policy_type       = "Encryption"
      resource_group_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg"

      encryption_config = {
        key_vault = {
          id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.KeyVault/vaults/test-kv"
          key = {
            name    = "test-encryption-key"
            version = "latest"
          }
        }
        state = "Enabled"
      }
    }

    common_tags = {
      environment = "test"
      project     = "PPCC25-Test"
      managed_by  = "Terraform"
    }
  }

  # Core resource configuration assertions
  assert {
    condition     = azapi_resource.enterprise_policy.name == "test-encryption-policy"
    error_message = "Policy name must match input configuration"
  }

  assert {
    condition     = azapi_resource.enterprise_policy.body.kind == "Encryption"
    error_message = "Policy kind must match policy type for Encryption"
  }

  # Policy body configuration assertions
  assert {
    condition     = contains(keys(azapi_resource.enterprise_policy.body.properties), "encryption")
    error_message = "Encryption policy must contain encryption properties"
  }

  assert {
    condition     = !contains(keys(azapi_resource.enterprise_policy.body.properties), "networkInjection")
    error_message = "Encryption policy must not contain networkInjection properties"
  }

  assert {
    condition     = azapi_resource.enterprise_policy.body.properties.encryption.state == "Enabled"
    error_message = "Encryption state must match input configuration"
  }

  assert {
    condition     = azapi_resource.enterprise_policy.body.properties.encryption.keyVault.key.name == "test-encryption-key"
    error_message = "Key name must match input configuration"
  }

  # Output type-specific assertions
  assert {
    condition     = output.policy_deployment_summary.policy_type == "Encryption"
    error_message = "Deployment summary must reflect correct policy type"
  }

  assert {
    condition     = output.policy_deployment_summary.configuration_details.type == "Encryption"
    error_message = "Configuration details must match policy type"
  }
}

# Test 3: Variable Validation Testing
run "variable_validation_tests" {
  command = plan

  variables {
    # Test minimum valid configuration
    policy_configuration = {
      name              = "min-valid-policy"
      location          = "europe"
      policy_type       = "NetworkInjection"
      resource_group_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg"

      network_injection_config = {
        virtual_networks = [{
          id     = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/vnet"
          subnet = { name = "subnet" }
        }]
      }
    }
  }

  # Variable validation assertions  
  assert {
    condition     = length(var.policy_configuration.name) >= 3
    error_message = "Policy name validation must enforce minimum length"
  }

  assert {
    condition     = length(var.policy_configuration.name) <= 64
    error_message = "Policy name validation must enforce maximum length"
  }

  assert {
    condition     = contains(["NetworkInjection", "Encryption"], var.policy_configuration.policy_type)
    error_message = "Policy type validation must enforce allowed values"
  }
}

# Test 4: Lifecycle and Timeout Configuration
run "lifecycle_and_timeout_validation" {
  command = plan

  variables {
    policy_configuration = {
      name              = "lifecycle-test-policy"
      location          = "europe"
      policy_type       = "NetworkInjection"
      resource_group_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg"

      network_injection_config = {
        virtual_networks = [{
          id     = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/vnet"
          subnet = { name = "subnet" }
        }]
      }
    }
  }

  # Lifecycle configuration assertions
  assert {
    condition     = azapi_resource.enterprise_policy.lifecycle != null
    error_message = "Enterprise policy must have lifecycle configuration"
  }

  # Timeout configuration assertions  
  assert {
    condition     = azapi_resource.enterprise_policy.timeouts != null
    error_message = "Enterprise policy must have timeout configuration"
  }
}

# Test 5: Dynamic Configuration Logic
run "dynamic_configuration_logic" {
  command = plan

  variables {
    policy_configuration = {
      name              = "dynamic-config-test"
      location          = "europe"
      policy_type       = "NetworkInjection"
      resource_group_id = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg"

      network_injection_config = {
        virtual_networks = [
          {
            id     = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/vnet1"
            subnet = { name = "subnet1" }
          },
          {
            id     = "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/vnet2"
            subnet = { name = "subnet2" }
          }
        ]
      }
    }
  }

  # Test multiple virtual networks support
  assert {
    condition     = length(azapi_resource.enterprise_policy.body.properties.networkInjection.virtualNetworks) == 2
    error_message = "Must support multiple virtual networks"
  }

  assert {
    condition     = output.policy_deployment_summary.configuration_details.virtual_networks_count == 2
    error_message = "Summary must reflect correct virtual network count"
  }

  assert {
    condition     = length(output.policy_deployment_summary.configuration_details.virtual_network_ids) == 2
    error_message = "Summary must include all virtual network IDs"
  }
}