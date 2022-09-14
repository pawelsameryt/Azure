#Get VNET attributes
$resourceGroup = "exam-grp"
$network="exam-network"

$virtualNetwork=Get-AzVirtualNetwork -Name $network -ResourceGroupName $resourceGroup

#Print value of Location attribute
Write-Host $virtualNetwork.Location
#Print value of AddressPrefix attribute
Write-Host $virtualNetwork.AddressSpace.AddressPrefixes