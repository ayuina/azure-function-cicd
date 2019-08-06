az login --service-principal -t $env:AAD_SP_TENANT -u $env:AAD_SP_APP -p $env:AAD_SP_KEY 
az account list -o table

$rgname = "$env:prefix-rg"
$funcappname = "$env:prefix-func"
$funcname = "thumbnail"
$strname = "{0}str" -f $env:prefix.Replace('-', '')
$container = "images"

###
write-host "retrieving target function app : $funcappname"
az functionapp show -g $rgname -n $funcappname | ConvertFrom-Json | Set-Variable targetFunc

###
write-host "retrieving function keys from $targetFunc.id"
$manageurl = "{0}/host/default/listKeys?api-version=2018-02-01" -f $targetFunc.id
az rest --method post --uri $manageurl | ConvertFrom-Json | Set-Variable funcKeys

###
$endpoint = ("https://{0}.azurewebsites.net/runtime/webhooks/EventGrid?functionName={1}&code={2}" `
                -f $funcappname, $funcname, $funcKeys.systemKeys.eventgrid_extension )
write-host "event grid subscription : $endpoint"

az eventgrid resource event-subscription create -g $rgname `
    --provider-namespace Microsoft.Storage --resource-type storageAccounts `
    --resource-name $strname --name "image-subscription"  `
    --included-event-types Microsoft.Storage.BlobCreated `
    --subject-begins-with "/blobServices/default/containers/$container/blobs/" `
    --endpoint $endpoint