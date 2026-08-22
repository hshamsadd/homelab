targetScope = 'subscription'

param location string = 'germanywestcentral'
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

module vnet 'modules/network.bicep' = {
  scope: rg
  name: 'vnetDeployment'
  params: {
    location: location
    vnetName: 'vnet-bicep-prod-01'
  }
}

module vm 'modules/ubuntu-vm.bicep' = {
  scope: rg
  name: 'vmDeployment'
  params: {
    location: location
    vmName: 'vm-bicep-prod-01'
    subnetId: vnet.outputs.subnetId
    adminUsername: 'azureadmin'
    sshPubKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... (mock-key-for-testing)' 
  }
}
