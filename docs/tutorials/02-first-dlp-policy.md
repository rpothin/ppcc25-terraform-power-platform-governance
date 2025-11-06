# Tutorial: Working with DLP Policies

![Tutorial](https://img.shields.io/badge/Diataxis-Tutorial-blue?style=for-the-badge&logo=book)

**Estimated Time**: 30 minutes  
**Prerequisites**: Complete [Getting Started Tutorial](01-getting-started.md)  
**You'll Learn**: How to export, create, and onboard Data Loss Prevention policies using Terraform

---

## 🎯 What You'll Build

By the end of this tutorial, you will have:
- ✅ Exported all existing DLP policies for reporting
- ✅ Created a new DLP policy from scratch
- ✅ Onboarded an existing policy into Terraform management
- ✅ Understanding of the complete DLP lifecycle

## 🎓 Learning Objectives

This tutorial teaches you:
- How to export existing DLP policies for documentation
- How to create new DLP policies with Terraform
- How to generate configuration from existing policies
- How to import and manage existing policies

---

## 📚 Background: What is a DLP Policy?

**Data Loss Prevention (DLP) policies** control which connectors your users can combine in apps and flows:

- **Business Connectors**: Can share data with each other (e.g., SharePoint ↔ SQL Server)
- **Non-Business Connectors**: Can share data with each other (e.g., Twitter ↔ Gmail)
- **Blocked Connectors**: Cannot be used at all

**The Rule**: Apps and flows cannot mix connectors from different groups.

💡 **Example**: If SharePoint is "Business" and Gmail is "Non-Business", users cannot create an app that copies SharePoint files to Gmail. This prevents data leakage!

---

## Part 1: Export Existing DLP Policies

Before creating new policies, let's see what already exists in your tenant.

### Step 1: Trigger the Export Workflow

1. **Run the export using GitHub CLI**:
   ```bash
   gh workflow run terraform-output.yml \
     -f configuration=utl-export-dlp-policies \
     -f export_format=json \
     -f include_metadata=true
   ```

2. **Check the workflow status**:
   ```bash
   gh run list --workflow=terraform-output.yml --limit 1
   ```

   Wait until status shows "completed" ✅

3. **View detailed status**:
   ```bash
   gh run list --workflow=terraform-output.yml --limit 1 \
     --json number,url,status,conclusion
   ```

💡 **What's happening?**: The workflow uses Terraform to query the Power Platform API and export all DLP policies to a JSON file.

### Step 2: Review the Export

1. **Pull the generated file**:
   ```bash
   git pull
   ```

2. **View the exported policies**:
   ```bash
   cat configurations/utl-export-dlp-policies/terraform-output-utl-export-dlp-policies.json
   ```

3. **Look at how the export works**:
   ```bash
   cat configurations/utl-export-dlp-policies/main.tf
   ```

Key components:
- `data "powerplatform_data_loss_prevention_policies"` - Queries all policies
- `local_file.dlp_policies_export` - Saves to JSON file

💡 **Success Check**: You should see a JSON file with all your tenant's DLP policies, including display names, connector classifications, and environment assignments.

---

## Part 2: Create a New DLP Policy

Now let's create a brand new DLP policy that allows only Dataverse connectors.

### Step 1: Create the Policy Configuration

1. **Copy the template**:
   ```bash
   cd configurations/res-dlp-policy/tfvars
   cp template.tfvars dataverse-only.tfvars
   ```

2. **Edit the policy**:
   ```bash
   nano dataverse-only.tfvars
   ```

3. **Configure for Dataverse-only access**:
   ```hcl
   # ═══════════════════════════════════════════════════════════════
   # Dataverse Only DLP Policy
   # ═══════════════════════════════════════════════════════════════
   
   # Policy Identity
   display_name = "Dataverse Only DLP Policy"
   description  = "Allows only Dataverse connectors for data access"
   
   # Default: Block everything
   default_connectors_classification = "Blocked"
   
   # Apply to specific environment (replace with your Default environment ID)
   environment_type = "OnlyEnvironments"
   environments     = ["Default-YOUR-GUID-HERE"]
   
   # Business Connectors: Only Dataverse
   business_connectors = [
     {
       id                           = "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps"
       default_action_rule_behavior = ""
       action_rules                 = []
       endpoint_rules               = []
     },
     {
       id                           = "/providers/Microsoft.PowerApps/apis/shared_commondataservice"
       default_action_rule_behavior = ""
       action_rules                 = []
       endpoint_rules               = []
     }
   ]
   
   # Block custom connectors by default
   custom_connectors_patterns = [
     {
       order            = 1
       host_url_pattern = "*"
       data_group       = "Blocked"
     }
   ]
   ```

4. **Save the file** (Ctrl+X, Y, Enter in nano)

### Step 2: Deploy the Policy

1. **Commit your configuration**:
   ```bash
   git add configurations/res-dlp-policy/tfvars/dataverse-only.tfvars
   git commit -m "feat: add Dataverse-only DLP policy configuration"
   git push
   ```

2. **Deploy via GitHub Actions**:
   ```bash
   gh workflow run terraform-plan-apply.yml \
     -f configuration=res-dlp-policy \
     -f tfvars_file=dataverse-only \
     -f apply=true \
     -f extract_outputs=false
   ```

3. **Monitor the deployment**:
   ```bash
   # Check status
   gh run list --workflow=terraform-plan-apply.yml --limit 1
   
   # View details
   gh run list --workflow=terraform-plan-apply.yml --limit 1 \
     --json number,url,status,conclusion
   ```

### Step 3: Understand What Happened

1. **Review the main resource**:
   ```bash
   cat configurations/res-dlp-policy/main.tf
   ```

Key components:
- `resource "powerplatform_data_loss_prevention_policy"` - Creates the policy
- `for_each` loops for connectors - Handles multiple connectors efficiently
- Validation blocks - Ensures configuration is correct

2. **Check the deployment logs** in GitHub Actions to see Terraform's output

💡 **Success Check**: 
- GitHub Actions shows successful deployment ✅
- You can see the new policy in the [Power Platform Admin Center](https://admin.powerplatform.microsoft.com/security/dataprotection)
- The policy is applied to your specified environment

---

## Part 3: Onboard an Existing Policy

The most common scenario: You have existing policies created via ClickOps, and you want to manage them with Terraform.

### Step 1: Generate Configuration from Existing Policy

1. **Run the generation workflow** (replace with your policy name):
   ```bash
   gh workflow run terraform-output.yml \
     -f configuration=utl-generate-dlp-tfvars \
     -f terraform_variables="-var='source_policy_name=YOUR EXISTING POLICY NAME'" \
     -f export_format=json \
     -f include_metadata=true
   ```

2. **Wait for completion**:
   ```bash
   gh run list --workflow=terraform-output.yml --limit 1
   ```

3. **Pull the generated configuration**:
   ```bash
   git pull
   ```

💡 **What's happening?**: The utility reads your existing policy from Power Platform and generates a matching Terraform configuration file.

### Step 2: Review and Move the Generated File

1. **Check the generated file**:
   ```bash
   cat configurations/utl-generate-dlp-tfvars/generated-dlp-policy.tfvars
   ```

2. **Move it to the DLP policy configuration**:
   ```bash
   mv configurations/utl-generate-dlp-tfvars/generated-dlp-policy.tfvars \
      configurations/res-dlp-policy/tfvars/imported-policy.tfvars
   ```

3. **Optional: Clean up blocked connectors** (if the list is large):
   ```bash
   # Remove the blocked_connectors section if it's very long
   sed -i '/^blocked_connectors = \[$/,/^]$/d' \
     configurations/res-dlp-policy/tfvars/imported-policy.tfvars
   ```

### Step 3: Import the Existing Policy

1. **Get the policy ID** from the export in Part 1, or from the generated file

2. **Commit the configuration**:
   ```bash
   git add configurations/res-dlp-policy/tfvars/imported-policy.tfvars
   git commit -m "feat: add generated tfvars for imported DLP policy"
   git push
   ```

3. **Import the policy into Terraform state**:
   ```bash
   gh workflow run terraform-import.yml \
     -f configuration=res-dlp-policy \
     -f tfvars_file=imported-policy \
     -f resource_type=powerplatform_data_loss_prevention_policy \
     -f resource_name=this \
     -f resource_id=YOUR-POLICY-GUID \
     -f backup_state=true
   ```

4. **Wait for import to complete**:
   ```bash
   gh run list --workflow=terraform-import.yml --limit 1
   ```

### Step 4: Verify No Changes Needed

1. **Run a plan to check**:
   ```bash
   gh workflow run terraform-plan-apply.yml \
     -f configuration=res-dlp-policy \
     -f tfvars_file=imported-policy \
     -f apply=false \
     -f extract_outputs=false
   ```

2. **Check the plan output**:
   ```bash
   gh run list --workflow=terraform-plan-apply.yml --limit 1
   ```

💡 **Success Check**: The plan should show "No changes" - Terraform recognizes the existing policy and the configuration matches perfectly!

---
   
   # OPTIONAL: Default classification for all connectors
   # "Blocked" is the most secure - only allow what you explicitly permit
   default_connectors_classification = "Blocked"
   
   # OPTIONAL: Apply to all environments (recommended for learning)
   environment_type = "AllEnvironments"
   
   # Business Connectors - These are ALLOWED and can share data
   # WHY: These are trusted Microsoft services essential for work
   business_connectors = [
     {
       id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
       default_action_rule_behavior = "Allow"
     },
     {
       id = "/providers/Microsoft.PowerApps/apis/shared_office365users"
       default_action_rule_behavior = "Allow"
     },
     {
       id = "/providers/Microsoft.PowerApps/apis/shared_teams"
       default_action_rule_behavior = "Allow"
     }
   ]
   
   # Everything else is BLOCKED (because of default_connectors_classification above)
   ```

4. **Save the file**:
   - In `nano`: `Ctrl+X`, `Y`, `Enter`

---

## Step 3: Plan Your Deployment

Before we create anything, let's see what Terraform will do.

1. **Go to GitHub Actions**:
   - Open your repository in a browser
   - Click "Actions" tab
   - Click "Terraform Plan and Apply" workflow

2. **Run a plan**:
   - Click "Run workflow"
   - Fill in:
     - **Configuration**: `res-dlp-policy`
     - **Terraform vars file**: `my-first-policy.tfvars`
     - **Environment**: (leave empty)
     - **Apply changes**: ☐ **UNCHECKED** (important!)
   - Click "Run workflow"

3. **Review the plan**:
   - Click on the workflow run
   - Wait for completion (~1-2 minutes)
   - Read the plan output carefully

**What to look for in the plan**:
```
Terraform will perform the following actions:

  # powerplatform_data_loss_prevention_policy.policy will be created
  + resource "powerplatform_data_loss_prevention_policy" "policy" {
      + display_name       = "My First DLP Policy - Learning"
      + default_connectors = "Blocked"
      + business_connectors = [
          + {
              + id = ".../shared_sharepointonline"
            },
          # ... more connectors
        ]
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

💡 **Success Check**: 
- Plan shows "1 to add"
- No errors in the workflow
- You understand what will be created

---

## Step 4: Apply Your Policy

Now that we've reviewed the plan, let's create the actual policy!

1. **Run the workflow again**:
   - Go back to "Terraform Plan and Apply"
   - Click "Run workflow"
   - Same settings as before, BUT:
     - **Apply changes**: ☑ **CHECKED** (this time!)
   - Click "Run workflow"

2. **Watch the deployment**:
   - Click on the new workflow run
   - Watch as Terraform:
     - Plans the changes (again)
     - Asks for approval (automatic in this setup)
     - Creates the DLP policy
     - Shows completion

3. **Wait for the green checkmark** ✅

**Expected Duration**: 2-3 minutes

💡 **Success Check**: Workflow completes with "Apply complete! Resources: 1 added, 0 changed, 0 destroyed."

---

## Step 5: Verify Your Policy

Let's confirm your policy exists and works correctly!

### Method 1: Power Platform Admin Center

1. **Open the Admin Center**:
   - Go to https://admin.powerplatform.microsoft.com
   - Sign in with your admin account

2. **Navigate to DLP Policies**:
   - In the left menu, click "Policies"
   - Click "Data policies"

3. **Find your policy**:
   - Look for "My First DLP Policy - Learning"
   - Click on it to view details

4. **Verify the configuration**:
   - **Business data group**: Should show SharePoint, Office 365 Users, Teams
   - **Non-business data group**: Should be empty
   - **Blocked**: Should show all other connectors

### Method 2: Workflow Outputs

1. **Check the workflow outputs**:
   - In your workflow run, find the "Terraform Apply" step
   - Look for the "Outputs:" section
   - You should see your policy ID

💡 **Success Check**: You can see your policy in the Admin Center exactly as you configured it!

---

## Step 6: Test Your Policy

Let's prove the policy works by trying to create an app that violates it.

1. **Open Power Apps**:
   - Go to https://make.powerapps.com
   - Select any environment

2. **Create a new Canvas app**:
   - Click "Create" → "Canvas app from blank"
   - Give it any name
   - Choose "Tablet" format

3. **Try to add SharePoint** (allowed):
   - Click "Data" in the left panel
   - Click "Add data"
   - Search for "SharePoint"
   - ✅ This should work - SharePoint is in Business group

4. **Try to add Gmail** (blocked):
   - Click "Add data" again
   - Search for "Gmail"
   - ❌ This should be blocked or show a warning

💡 **Understanding the result**: 
- You CAN add Business connectors (SharePoint, Teams, Office 365)
- You CANNOT add blocked connectors (Gmail, Twitter, etc.)
- This is your DLP policy in action!

---

## Step 7: Make a Change

Now let's modify the policy to see how updates work.

1. **Edit your policy file**:
   ```bash
   nano tfvars/my-first-policy.tfvars
   ```

2. **Add another connector**:
   ```hcl
   business_connectors = [
     {
       id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
       default_action_rule_behavior = "Allow"
     },
     {
       id = "/providers/Microsoft.PowerApps/apis/shared_office365users"
       default_action_rule_behavior = "Allow"
     },
     {
       id = "/providers/Microsoft.PowerApps/apis/shared_teams"
       default_action_rule_behavior = "Allow"
     },
     # NEW: Add Outlook email connector
     {
       id = "/providers/Microsoft.PowerApps/apis/shared_office365"
       default_action_rule_behavior = "Allow"
     }
   ]
   ```

3. **Save and commit**:
   ```bash
   git add tfvars/my-first-policy.tfvars
   git commit -m "Add Outlook to DLP policy"
   git push
   ```

4. **Run the workflow again**:
   - Plan first (Apply unchecked)
   - Review the changes: "Plan: 0 to add, 1 to change, 0 to destroy"
   - Apply the change (Apply checked)

💡 **Understanding the change**:
- Terraform detected you modified an existing resource
- It will UPDATE the policy, not recreate it
- This is safe and non-disruptive!

---

## 🎉 Congratulations!

You've successfully:
- ✅ Created your first DLP policy with Terraform
- ✅ Deployed it through GitHub Actions
- ✅ Verified it in the Power Platform Admin Center
- ✅ Tested that it actually works
- ✅ Made and applied changes safely

## 🎓 What You Learned

In this tutorial, you learned:
- **DLP Policy Structure**: How policies are organized in Terraform
- **Connector Classification**: Business vs Blocked connectors
- **Safe Deployment**: Plan before apply
- **Verification**: Multiple ways to confirm success
- **Change Management**: How to update policies safely

---

## 🚀 What's Next?

### Next Tutorial
**[Environment Management](03-environment-management.md)** - Learn how to create and configure Power Platform environments (25 minutes)

### Go Deeper with DLP
- **[DLP Policy Management Guide](../guides/dlp-policy-management.md)** - Advanced DLP patterns and techniques
- **[Configuration Catalog](../reference/configuration-catalog.md)** - See all DLP configuration options

### Try These Challenges

1. **Add endpoint filtering**:
   - Restrict SharePoint to specific sites
   - Block SQL connections to production servers

2. **Create environment-specific policies**:
   - One policy for Production environments
   - A different policy for Development

3. **Add action rules**:
   - Allow most SQL actions
   - Block DELETE operations

---

## 📖 Reference: Connector IDs

Common connector IDs you might use:

```hcl
# Microsoft 365 Services
shared_sharepointonline    # SharePoint Online
shared_office365           # Office 365 Outlook
shared_teams              # Microsoft Teams
shared_office365users     # Office 365 Users
shared_onedrive           # OneDrive for Business

# Data & Databases
shared_sql                # SQL Server
shared_azureblob          # Azure Blob Storage
shared_commondataservice  # Microsoft Dataverse

# Communication
shared_outlook            # Outlook.com
shared_gmail              # Gmail

# External Services
shared_twitter            # Twitter
shared_facebook           # Facebook
```

💡 **Tip**: To get the complete list of connectors in your tenant, deploy the `utl-export-connectors` configuration!

---

## 🆘 Need Help?

**Common Issues**:

**Policy not showing in Admin Center**
- Wait 1-2 minutes for replication
- Refresh your browser
- Check workflow logs for errors

**Can't add Business connectors in Power Apps**
- Make sure you're testing in the correct environment
- Policy may take a few minutes to take effect
- Verify connector ID is correct (case-sensitive!)

**Workflow fails with "Policy already exists"**
- You may have created it manually before
- Use a different display_name
- Or remove the manual policy first

**More help**: [Troubleshooting Guide](../guides/troubleshooting.md)
