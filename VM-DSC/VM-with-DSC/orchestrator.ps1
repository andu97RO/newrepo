
Param(

    [Parameter(Mandatory=$True)]
    [string]$resourceGroup,

    [Parameter(Mandatory=$True)]
    [string]$resourceGroupLocation,

    [Parameter(Mandatory=$True)]
    [string]$storageAccountName,

    [Parameter(Mandatory=$True)]
    [string]$vmDNS

)

##login
Import-AzureRmContext -Path .\context.json

#this will be parametrized
#$resourceGroup = "bucharest-intern-alex"
#$storageAccountName = "sonarquubeaccelerator"

$containerName = "sonarquubedsccontainer"
$blobName = "DSC.zip"
$blobLocation = ".\" + $blobName

$dscResourceFolder = ".\DSC\*"
$templateFile = ".\azuredeploy.json"
$templateParametersFile = ".\azureparameters.json"

$OptionalParameters = New-Object -TypeName Hashtable

#optional indexes
$artifactsLocation = "artifactsLocation"
$artifactsLocationSasToken = "artifactsLocationSasToken"
$newDatabasePasswordIndex = "new-serverAdminLoginPassword"
$newDatabaseAccountIndex = "new-serverAdminLogin"
$newDatabaseNameIndex = "new-databaseName"
$vmDNSIndex = "dnsName"


#database parameters
$newDatabasePassword = "Password123##asf!"
$newDatabaseAccount = "devops1admin"
$newDatabaseName = "devops-database-1"


#create or retrieve a Resource Group
Try{
    $resourceGroupInstance = Get-AzureRmResourceGroup -Name $resourceGroup -ErrorAction Stop
}
Catch{
    Write-Host "Creating Resource Group"
    New-AzureRmResourceGroup -Name $resourceGroup -Location $resourceGroupLocation
}



##create or retrieve a storage account
Try{
    $storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName -ErrorAction Stop
}
Catch{
    Write-Host "Creating Storage Account"
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName -Location $resourceGroupLocation -SkuName Standard_GRS -Kind Storage
    $storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName
}



#save Storage Context and concatenate Storage Account's resource dns
$storageContext = $storageAccount.Context
$dscURI = $storageAccount.Context.BlobEndPoint + $containerName + "/" + $blobName



#create archive for dsc folder and upload it to the storage account
Compress-Archive -Path $dscResourceFolder -CompressionLevel Fastest -DestinationPath $blobName -Force
Try{
    $checkContainer = Get-AzureStorageContainer -Name $containerName -Context $storageContext -ErrorAction Stop
}
Catch{
    Write-Host "Creating Container"
    New-AzureStorageContainer -Name $containerName -Context $storageContext -Permission Off
    Set-AzureStorageBlobContent -File $blobLocation -Container $containerName  -Blob $blobName -Context $storageContext 
}



#create saskey and append needed ARM parameters
$saskey = New-AzureStorageBlobSASToken -Container $containerName -Permission r -Blob $blobName -Context $storageContext -ExpiryTime (Get-Date).AddHours(4) | ConvertTo-SecureString -AsPlainText -Force
$OptionalParameters[$artifactsLocation] = $dscURI
$OptionalParameters[$artifactsLocationSasToken] = $saskey
$OptionalParameters[$newDatabasePasswordIndex] = $newDatabasePassword | ConvertTo-SecureString -AsPlainText -Force
$OptionalParameters[$newDatabaseAccountIndex] = $newDatabaseAccount
$OptionalParameters[$newDatabaseNameIndex] = $newDatabaseName
$OptionalParameters[$vmDNSIndex] = $vmDNS



##deploy the ARM Template
Write-Host "Deploying the ARM Template"
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup -TemplateFile $templateFile -TemplateParameterFile $templateParametersFile @OptionalParameters -Force



Write-Host "ARM was deployed!"


#Generate user token and create a project with selenium
$resourceGroupLocation = $resourceGroupLocation.Replace(" ","")
$resourceGroupLocation = $resourceGroupLocation.ToLower()

$seleniumTestURL = $vmDNS + "." + $resourceGroupLocation + ".cloudapp.azure.com"