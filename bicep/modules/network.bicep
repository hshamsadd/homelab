param location string
param vnetName string

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.20.0.0/16'] }
    subnets: [
      {
        name: 'snet-vm'
        properties: { addressPrefix: '10.20.1.0/24' }
      }
    ]
  }
}

output subnetId string = vnet.properties.subnets[0].id
