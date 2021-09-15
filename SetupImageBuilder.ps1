$sigGalleryName= "testSIG"
$imageDefName ="Windows10AVDMultiuser"
$imageResourceGroup="AVD-ImagebuilderImages" # destination image resource group
$location="westeurope" # location (see possible locations in main docs: https://docs.microsoft.com/en-us/azure/virtual-machines/image-builder-overview#regions)
$imageTemplateName="Windows10VirtualDesktop" # image template name


$templateFilePath = "armTemplateWVD.json"
$runOutputName="sigOutput" # distribution properties object name (runOutput), i.e. this gives you the properties of the managed image on completion


# # Step 1: Import module
Import-Module Az.Accounts
Import-Module Az.ManagedServiceIdentity

# # Step 2: get existing context
# $currentAzContext = Get-AzContext

# your subscription, this will get your current subscription
$subscriptionID=$currentAzContext.Subscription.Id

# create resource group
New-AzResourceGroup -Name $imageResourceGroup -Location $location

# setup role def names, these need to be unique
$timeInt=$(get-date -UFormat "%s")
$imageRoleDefName="Azure Image Builder Image Def1619383055"
$idenityName="aibIdentity"+$timeInt

# ## Add AZ PS modules to support AzUserAssignedIdentity and Az AIB
# 'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object {Install-Module -Name $_ -AllowPrerelease}

# create identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName


$idenityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).Id
$idenityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).PrincipalId


$aibRoleImageCreationPath = "aibRoleImageCreation.json"
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

# create role definition
New-AzRoleDefinition -InputFile ./aibRoleImageCreation.json

$role = Get-AzRoleDefinition -Name "AIB"

# grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $role.Name -Scope "/subscriptions/675d04a1-6ccc-44c4-b679-df78c08d8e96/resourceGroups/WVD-Master"


New-AzGallery -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup  -Location $location

# create gallery definition
New-AzGalleryImageDefinition -GalleryName $sigGalleryName -ResourceGroupName $imageResourceGroup -Location $location -Name $imageDefName -OsState generalized -OsType Windows -Publisher 'ScoreUtica' -Offer 'Windows' -Sku 'WVD'


((Get-Content -path $templateFilePath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<rgName>',$imageResourceGroup) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region>',$location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<runOutputName>',$runOutputName) | Set-Content -Path $templateFilePath

((Get-Content -path $templateFilePath -Raw) -replace '<imageDefName>',$imageDefName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<sharedImageGalName>',$sigGalleryName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region1>',$location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$idenityNameResourceId) | Set-Content -Path $templateFilePath


New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2020-02-14" -imageTemplateName $imageTemplateName -svclocation $location

Start-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName -NoWait