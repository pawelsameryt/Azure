$rg = "rg-pslab"
$location = "westus3"
$network = "psnet"
$AddressPrefix="10.1.0.0/16"
$subName = "SubnetA"
$subPrefix = "10.1.0.0/24"
$networkInterface = "nic1"
$publicIPAdd = "publicIP1"
$networkSG = "NSG1"

#create Resource group
New-AzResourceGroup -name $rg -Location $location
#Create VNet
# configuration
$subnet = New-AzVirtualNetworkSubnetConfig -Name $subName -AddressPrefix $subPrefix 
New-AzVirtualNetwork -Name $network -ResourceGroupName $rg -Location $location -AddressPrefix $AddressPrefix -Subnet $subnet
#Create Subnet
$vn = Get-AzVirtualNetwork -Name $network -ResourceGroupName $rg
Write-Host $vn.AddressSpace.AddressPrefixes
Add-AzVirtualNetworkSubnetConfig -name $subName -VirtualNetwork $vn -AddressPrefix $subPrefix
#$vn | Set-AzVirtualNetwork
$vn = Get-AzVirtualNetwork -Name $network -ResourceGroupName $rg

#Create network interface
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vn -Name $subName
New-AzNetworkInterface -Name $networkInterface -ResourceGroupName $rg -Location $location -SubnetId $subnet.Id -IpConfigurationName "nic1IPconfig"

#Create Public IP
New-AzPublicIpAddress -Name $publicIPAdd -ResourceGroupName $rg -Location $location -AllocationMethod Dynamic

#Create NSG and rules for rdp and http
$networkSG = "NSG1"
$nsrule1 = New-AzNetworkSecurityRuleConfig -Name Allow-RDP -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix 10.1.0.0/24 -DestinationPortRange 3389
$nsrule2 = New-AzNetworkSecurityRuleConfig -Name Allow-http -Access Allow -Protocol Tcp -Direction Inbound -Priority 102 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix 10.1.0.0/24 -DestinationPortRange 80
New-AzNetworkSecurityGroup -Name $networkSG -ResourceGroupName $rg -Location $location -SecurityRules $nsrule1, $nsrule2

#Create VM
$vmName = "VM1"
$vmSize = "Standard_B2s"
$vmImage = "Win2019Datacenter"

Get-azvmsize -location $location
get-azvmsize -location westus3 | where-object {$_.Numberofcores -eq 2}

New-AzVM -ResourceGroupName $rg -Name $vmName -Location $location -SubnetName $subName -Image $vmImage -Size $vmSize -VirtualNetworkName $network -SecurityGroupName $networkSG -Credential (Get-Credential)

#Add disk to vm
$dataDiskName = "data-disk1"
$vmName = "VM1"
#Create DiskConfig
$dataDiskConfig = New-AzDiskConfig -Location $location -CreateOption Empty -DiskSizeGB 16 -SkuName "Standard_LRS"
#Create Disk based on config
$dataDisk = New-AzDisk -ResourceGroupName $rg -DiskName $dataDiskConfig -Disk $dataDiskConfig
#Attach disk to VM
$vm = Get-AzVM -ResourceGroupName $rg -Name $vmName
$vm = Add-AzVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun 0
Update-AzVM -ResourceGroupName $rg -VM $vm

