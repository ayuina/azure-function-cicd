# Connect-AzAccount
# Set-AzContext -Subscription "subscription-guid"
param(
    [string]$region = "southeastasia",
    [string]$prefix = "ayuina"
)

function Main()
{
    #####
    $rgname = ("$prefix-{0:MMdd}-arm-rg" -f [DateTime]::Now)
    $rg = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -eq $rgname}
    if($null -eq $rg)
    {
        Write-Host "creating new resource group"
        $rg = New-AzResourceGroup -Name $rgname -Location $region
    }

    #####
    $deploymentName = "deploy-{0:yyyyMMdd-HHmmss}" -f [DateTime]::Now
    Write-Host "start deployment : $deploymentName"
    New-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName -Name $deploymentName -TemplateFile ".\azuredeploy.json"  `
        -location $region -prefix $prefix

    #####
    $funcappname = "$prefix-func"
    Write-Host "publishing function : $funcappname"
    cd .\image-processor\
    func azure functionapp publish $funcappname
    cd ..

    #####
    Write-Host "setting up event grid trigger : $funcappname"
    #https://markheath.net/post/managing-azure-functions-keys-2
    #https://github.com/Azure/azure-functions-host/wiki/Key-management-API
    #https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-event-grid#create-a-subscription
    
    az functionapp show -g $rgname -n $funcappname | ConvertFrom-Json | Set-Variable targetFunc
    # $manageurl = "https://management.azure.com{0}/functions/thumbnail/listKeys?api-version=2018-02-01" -f $targetFunc.id
    $manageurl = "{0}/host/default/listKeys?api-version=2018-02-01" -f $targetFunc.id
    az rest --method post --uri $manageurl | ConvertFrom-Json | Set-Variable funcKeys
    
    #####
    $deploymentName = "deploy-{0:yyyyMMdd-HHmmss}-evt" -f [DateTime]::Now
    Write-Host "start deployment : $deploymentName"
    New-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName -Name $deploymentName -TemplateFile ".\eventsubscribe.json"  `
        -prefix $prefix -apikey $funcKeys.systemKeys.eventgrid_extension
}

Main