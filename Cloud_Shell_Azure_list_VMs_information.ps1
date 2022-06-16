
        $vmobjs = @()
        
        $vms = Get-AzVM 
        $NICs=Get-AzNetworkInterface
        $PublicIPs=Get-AzPublicIpAddress

        foreach ($vm in $vms)
        {
            $vmInfo = [pscustomobject]@{
                
                'Location' = $vm.Location
                'ResourceGroupName' = $vm.ResourceGroupName
                'Name'=$vm.Name
                'ComputerName' = $vm.OSProfile.ComputerName
                'VMSize' = $vm.HardwareProfile.VMsize
                'OsType'= $vm.StorageProfile.OsDisk.OsType
                'Status' = (Get-AzVM -Status -name $vm.Name -ResourceGroupName $vm.ResourceGroupName).Statuses[1].DisplayStatus
                'DataDiskCount' = $vm.StorageProfile.DataDisks.Count
                'Admin' = $vm.OSProfile.AdminUsername
                'Virtual_Network'= $null
                'Subnet'= $null
                'Private_IP_Address'= $null
                'PublicIP_name' = $null
                'PublicIP_address' = $null
                'ProvisioningState' = $vm.ProvisioningState
                'Publisher' = $vm.StorageProfile.ImageReference.Publisher
                'Offer' = $vm.StorageProfile.ImageReference.Offer
                'SKU' = $vm.StorageProfile.ImageReference.Sku
                'Version' = $vm.StorageProfile.ImageReference.Version  
                
                 }
        
            #$vmStatus = $vm | Get-AzureRmVM -Status
            #$vmInfo.Status = $vmStatus.Statuses[1].DisplayStatus

            $nic=$NICs | where { $_.Id -eq $vm.NetworkProfile.NetworkInterfaces.Id }
            $vmInfo.Virtual_Network=(($nic.IpConfigurations.Subnet.Id).split('/') | Select-Object -Last 3)[0]
            $vmInfo.Subnet=(($nic.IpConfigurations.Subnet.Id).split('/') | Select-Object -Last 3)[2]
            $vmInfo.Private_IP_Address=$nic.IpConfigurations.privateipaddress


             try
                {
                        #$pos = $nic.IpConfigurations.PublicIpAddress.ID.IndexOf("/publicIPAddresses/")
                        #$vmInfo.PublicIP_name =  $nic.IpConfigurations.PublicIpAddress.ID.Substring($pos+19)
                        
                        
                        #$vmInfo.PublicIP_name =  ($nic.IpConfigurations.PublicIpAddress.ID).split('/') | Select-Object -Last 1
                        #$vmInfo.PublicIP_address = (Get-AzPublicIpAddress -Name $vmInfo.PublicIP_name -ResourceGroupName $vm.ResourceGroupName).IpAddress

                        $PublicIP = $PublicIPs | where { $_.Id -eq $nic.IpConfigurations.PublicIpAddress.ID }
                        $vmInfo.PublicIP_name = $PublicIP.Name
                        $vmInfo.PublicIP_address = $PublicIP.IpAddress


                }
             catch
                {
                        $vmInfo.PublicIP_name = "Disabled"
                        $vmInfo.PublicIP_address =  "Disabled"
                }

            
            
            $vmobjs += $vmInfo
}

 $vmobjs | Format-Table -AutoSize
 #$file="C:\Azure-ARM-VMs.csv"
 $file="$HOME/Azure-ARM-VMs.csv"

 $vmobjs | Export-Csv -NoTypeInformation -Path $file
Write-Host "VM list written to $file"
#Invoke-Item $file
