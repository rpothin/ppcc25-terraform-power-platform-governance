# Reusable Terraform Base Workflow - Usage Examples

This document provides examples of how to use the `reusable-terraform-base.yml` workflow in your existing terraform workflows.

## Basic Usage Examples

### Example 1: Simple Plan Operation
```yaml
jobs:
  terraform-plan:
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'plan'
      configuration: '02-dlp-policy'
      tfvars-file: 'dlp-finance'
      timeout-minutes: 15
    secrets: inherit
```

### Example 2: Apply with Plan File
```yaml
jobs:
  terraform-plan:
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'plan'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
      plan-file-name: 'deployment-plan'
    secrets: inherit
  
  terraform-apply:
    needs: terraform-plan
    if: needs.terraform-plan.outputs.has-changes == 'true'
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'apply'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
      plan-file-name: 'deployment-plan'
      timeout-minutes: 30
    secrets: inherit
```

### Example 3: Destroy with Auto-approval
```yaml
jobs:
  terraform-destroy:
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'destroy'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
      auto-approve: true
      timeout-minutes: 25
    secrets: inherit
```

### Example 4: Import Operation
```yaml
jobs:
  terraform-import:
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'import'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
      additional-options: 'powerplatform_environment.example ${{ github.event.inputs.resource_id }}'
      timeout-minutes: 15
    secrets: inherit
```

## Output Usage Examples

### Using Outputs in Subsequent Jobs
```yaml
jobs:
  terraform-plan:
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'plan'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
    secrets: inherit
  
  conditional-apply:
    needs: terraform-plan
    if: |
      needs.terraform-plan.outputs.operation-successful == 'true' &&
      needs.terraform-plan.outputs.has-changes == 'true'
    runs-on: ubuntu-latest
    steps:
      - name: Display Plan Results
        run: |
          echo "Plan was successful: ${{ needs.terraform-plan.outputs.operation-successful }}"
          echo "Changes detected: ${{ needs.terraform-plan.outputs.has-changes }}"
          echo "State key used: ${{ needs.terraform-plan.outputs.state-key-used }}"
          echo "Metadata: ${{ needs.terraform-plan.outputs.operation-metadata }}"
```

## Migration Guide

### Before (Original terraform-plan-apply.yml structure):
```yaml
jobs:
  terraform-plan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
      
      - name: Azure Login with OIDC
        uses: azure/login@v2.3.0
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          # ... extensive setup code ...
      
      - name: Add JIT Network Access
        uses: ./.github/actions/jit-network-access
        # ... more duplicate code ...
      
      - name: Initialize Terraform
        # ... initialization logic ...
      
      - name: Terraform Plan
        # ... plan execution ...
```

### After (Using reusable workflow):
```yaml
jobs:
  terraform-plan:
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'plan'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
      timeout-minutes: 15
    secrets: inherit
  
  terraform-apply:
    needs: terraform-plan
    if: |
      needs.terraform-plan.outputs.operation-successful == 'true' &&
      github.event.inputs.apply == 'true'
    uses: ./.github/workflows/reusable-terraform-base.yml
    with:
      operation: 'apply'
      configuration: ${{ github.event.inputs.configuration }}
      tfvars-file: ${{ github.event.inputs.tfvars_file }}
      plan-file-name: 'terraform-plan'
      timeout-minutes: 30
    secrets: inherit
```

## Benefits Achieved

1. **Massive code reduction**: From 380+ lines to ~30 lines per workflow
2. **Consistent behavior**: All operations use the same initialization, authentication, and error handling
3. **Standardized outputs**: All workflows provide the same output format
4. **Better maintainability**: Changes to common patterns require only 1 file update
5. **Improved reliability**: Uses your proven composite actions as building blocks

## Next Steps

1. Update existing terraform-* workflows to use this reusable workflow
2. Test with different configurations and tfvars files
3. Validate that all existing functionality is preserved
4. Monitor performance to ensure no regression
