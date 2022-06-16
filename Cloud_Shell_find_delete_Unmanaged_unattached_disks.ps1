# Set deleteUnattachedVHDs=1 if you want to delete unattached VHDs
# Set deleteUnattachedVHDs=0 if you want to see the Uri of the unattached VHDs
$deleteUnattachedVHDs=Read-Host "enter 0 for List & 1 for Delete"

$disk = @()
$file="$HOME/unattached_unManaged_disks.csv"

$storageAccounts = Get-AzStorageAccount
foreach($storageAccount in $storageAccounts){
    $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName)[0].Value
    $context = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey
    $containers = Get-AzStorageContainer -Context $context
    foreach($container in $containers){
        $blobs = Get-AzStorageBlob -Container $container.Name -Context $context
        #Fetch all the Page blobs with extension .vhd as only Page blobs can be attached as disk to Azure VMs
        $blobs | Where-Object {$_.BlobType -eq 'PageBlob' -and $_.Name.EndsWith('.vhd')} | ForEach-Object { 
            #If a Page blob is not attached as disk then LeaseStatus will be unlocked
            if($_.ICloudBlob.Properties.LeaseStatus -eq 'Unlocked'){
                    if($deleteUnattachedVHDs -eq 1){
                        Write-Host "Deleting unattached VHD with Uri: $($_.ICloudBlob.Uri.AbsoluteUri)"
                        $_ | Remove-AzStorageBlob -Force
                        Write-Host "Deleted unattached VHD with Uri: $($_.ICloudBlob.Uri.AbsoluteUri)"
                    }
                    else{
                        
                        $disk += $_ | Select @{Name="Blob"; Expression={$_.ICloudBlob.Uri.AbsoluteUri}} ,@{Name="ResourceGroup"; Expression={$storageAccount.ResourceGroupName}} ,@{Name="StorageType"; Expression={$storageAccount.Sku.Name}},@{Name="Size (GB)"; Expression={[math]::Round($_.Length/1GB)}} ,@{Name="Status"; Expression={"Unattached"}}
                    }
            }
        }
    }
}


if($deleteUnattachedVHDs -eq 0){
    if($disk.Length -eq 0){

        Write-Host "There is no Unattached Disks"

    }else{
        $disk | Format-Table -AutoSize
        $disk | Export-Csv -NoTypeInformation -Path $file
        Write-Host "Unttached disk list written to $file"
    }
}