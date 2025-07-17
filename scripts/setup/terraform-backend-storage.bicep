@description('Name of the Storage Account. Must be lower-case.')
param storageAccountName string

@description('Name of the blob container for Terraform state.')
param containerName string

@description('Service principal client ID for role assignments.')
param servicePrincipalClientId string

@description('Resource tags.')
param tags object = {}

// Deploy the storage account using AVM module
module storageAccount 'br/public:avm/res/storage/storage-account:0.25.0' = {
  name: 'storageAccountDeployment'
  params: {
    name: storageAccountName
    
    // Configure network ACLs to deny all access by default (JIT access will be managed dynamically)
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
    }
    
    // Configure blob services with the Terraform state container
    blobServices: {
      containerDeleteRetentionPolicyEnabled: true
      containerDeleteRetentionPolicyDays: 7
      deleteRetentionPolicyEnabled: true
      deleteRetentionPolicyDays: 7
      containers: [
        {
          name: containerName
          publicAccess: 'None'
        }
      ]
    }
    
    // Configure role assignments for the service principal
    roleAssignments: [
      {
        principalId: servicePrincipalClientId
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
        principalType: 'ServicePrincipal'
      }
    ]
    
    tags: tags
  }
}

// Output the storage account details
output storageAccountName string = storageAccount.outputs.name
output storageAccountId string = storageAccount.outputs.resourceId
output primaryBlobEndpoint string = storageAccount.outputs.primaryBlobEndpoint
output containerName string = containerName
