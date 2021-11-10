param location string
param tags object
param storageId string
param workspaceId string
param workspaceRegion string
param workspaceResourceId string
param retentionInDays int
param nsgControlPlaneId string
param nsgControlPlaneName string
param nsgDataPlaneId string
param nsgDataPlaneName string
param nsgPrivateLinkId string
param nsgPrivateLinkName string

resource nsgControlPlane_flowLogs 'Microsoft.Network/networkWatchers/flowLogs@2020-08-01' = {
  name: 'NetworkWatcher_${location}/${nsgControlPlaneName}'
  location: location
  tags: tags
  properties: {
    targetResourceId: nsgControlPlaneId
    storageId: storageId
    enabled: true
    retentionPolicy: {
      days: retentionInDays
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceId: workspaceId
        workspaceRegion: workspaceRegion
        workspaceResourceId: workspaceResourceId
        //trafficAnalyticsInterval: int
      }
    }
  }
}

resource nsgDataPlane_flowLogs 'Microsoft.Network/networkWatchers/flowLogs@2020-08-01' = {
  name: 'NetworkWatcher_${location}/${nsgDataPlaneName}'
  location: location
  tags: tags
  properties: {
    targetResourceId: nsgDataPlaneId
    storageId: storageId
    enabled: true
    retentionPolicy: {
      days: retentionInDays
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceId: workspaceId
        workspaceRegion: workspaceRegion
        workspaceResourceId: workspaceResourceId
        //trafficAnalyticsInterval: int
      }
    }
  }
}

resource nsgPrivateLink_flowLogs 'Microsoft.Network/networkWatchers/flowLogs@2020-08-01' = {
  name: 'NetworkWatcher_${location}/${nsgPrivateLinkName}'
  location: location
  tags: tags
  properties: {
    targetResourceId: nsgPrivateLinkId
    storageId: storageId
    enabled: true
    retentionPolicy: {
      days: retentionInDays
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceId: workspaceId
        workspaceRegion: workspaceRegion
        workspaceResourceId: workspaceResourceId
        //trafficAnalyticsInterval: int
      }
    }
  }
}
