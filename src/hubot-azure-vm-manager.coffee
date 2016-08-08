async = require('async')
jsYaml = require('js-yaml')
fs = require('fs')
msrestAzure = require('ms-rest-azure')
computeManagementClient = require('azure-arm-compute')

config = 
  clientId:       process.env.AZURE_CLIENT_ID;
  clientSecret:   process.env.AZURE_CLIENT_SECRET;
  tenantId:       process.env.AZURE_TENANT_ID;
  subscriptionId: process.env.AZURE_SUBSCRIPTION_ID;

getPowerState = (instansStatuses) ->
  state = undefined
  for status in instansStatuses
    if status.code.match(/PowerState/)
      state = status.displayStatus
  state

module.exports = (robot) ->
  robot.respond /azure vm list/, (msg) ->
    msrestAzure.loginWithServicePrincipalSecret config.clientId, config.clientSecret, config.tenantId, (err, credentials) ->
      if err 
        msg.send "#{err}"
        return
      client = new computeManagementClient(credentials, config.subscriptionId)
      options =
        expand: "instanceView"
      client.virtualMachines.listAll (err, result) ->
        for machine in result
          params = machine.id.match(/subscriptions\/([a-z0-9\-]+)\/resourceGroups\/([A-Z0-9\-]+)\//)
          resourceGroupName = params[2]
          client.virtualMachines.get resourceGroupName, machine.name, options, (err, result) ->
            powerState = getPowerState(result.instanceView.statuses)
            msg.send "#{machine.name}@#{machine.location} in #{resourceGroupName} is #{powerState}"
            
