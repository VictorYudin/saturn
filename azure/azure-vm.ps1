$VMLocalAdminUser = "<username>"
$VMLocalAdminSecurePassword = ConvertTo-SecureString <password> -AsPlainText -Force

# Virtual Machine
$LocationName = "eastus"
$VMSize = "Standard_B2s"

# These resources shoud exist in Azure
$ResourceGroupName = "VictorResourceGroup"
$NetworkName = "VictorVnet"
$NSName = "VictorSecurityGroup"
$PIPName = "VictorPublicIpAddress"
$SubnetName = "VictorSubnet"

# These resources will be created
$ComputerName = "SixMachine"
$VMName = "SixMachine"
$DiskName = "SixDisk"
$NICName = "SixNIC"

# Create a Virtual Network for the machine
$Vnet = Get-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName
$NS = Get-AzureRmNetworkSecurityGroup -Name $NSName -ResourceGroupName $ResourceGroupName
$PIP = Get-AzureRmPublicIpAddress -Name $PIPName -ResourceGroupName $ResourceGroupName
$NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id -NetworkSecurityGroupId $NS.Id

# Create Username/Password
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

# Configure Virtual Machine
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftVisualStudio' -Offer 'VisualStudio' -Skus 'VS-2017-Comm-Latest-Win10-N' -Version latest
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $DiskName -CreateOption 'FromImage' -Windows -StorageAccountType 'Standard_LRS'

# Create Virtual Machine
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose
