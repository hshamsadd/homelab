param location string
param clusterName string

resource aks 'Microsoft.ContainerService/managedClusters@2023-08-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 1
        vmSize: 'Standard_D2ds_v7'
        mode: 'System'
      }
    ]
  }
}
