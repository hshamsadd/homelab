targetScope = 'subscription'

param location string = 'westeurope'
param rgName string = 'rg-bicep-foundation-prod'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}

module aks 'modules/aks.bicep' = {
  scope: rg
  name: 'aksDeployment'
  params: {
    location: location
    clusterName: 'aks-bicep-prod-01'
  }
}
// Trigger GitHub Actions OIDC test
