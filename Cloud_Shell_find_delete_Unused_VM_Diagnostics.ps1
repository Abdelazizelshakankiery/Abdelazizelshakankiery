# Set deleteUnusedDiagnostics=1 if you want to delete unattached DiagnosticBlobs
# Set deleteUnusedDiagnostics=0 if you want to see the Uri of the unattached DiagnosticBlobs
$deleteUnusedDiagnostics=Read-Host "enter 0 for List & 1 for Delete"

$UnusedDiagnosticBlobs = @()
$file="$HOME/Unused_DiagnosticBlobs.csv"
$VM_names_list = (Get-AzVM).Name


$storageAccounts = Get-AzStorageAccount
foreach($storageAccount in $storageAccounts){
    $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName)[0].Value
    $context = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey
    $containers = Get-AzStorageContainer -Context $context
    foreach($container in $containers){
        if($container.Name.StartsWith("bootdiagnostics")){
            $blobs = Get-AzStorageBlob -Container $container.Name -Context $context
            #Fetch all VMs Diagnostics blobs with extension ".screenshot.bmp" OR ".serialconsole.log"
            $blobs | Where-Object {$_.Name.EndsWith('.screenshot.bmp') -Or $_.Name.EndsWith('.serialconsole.log')} | ForEach-Object { 
                #extract VM name from Blob's Name
                $VM_name=$_.Name.split('.') | Select-Object -First 1
                #if VM doesn't exist then Diagnostic blobs are considered unattached
                if($VM_names_list -notcontains $VM_name){
                        if($deleteUnusedDiagnostics -eq 1){
                            Write-Host "Deleting Unused bootdiagnostics blob with Uri: $($_.ICloudBlob.Uri.AbsoluteUri)"
                            $_ | Remove-AzStorageBlob -Force
                            Write-Host "Deleted Unused bootdiagnostics blob with Uri: $($_.ICloudBlob.Uri.AbsoluteUri)"
                            # Delete also Container if it is empty i.e. has no any blobs
                            $Container_blobs_list = Get-AzStorageBlob -Container $container.Name -Context $context
                            if($Container_blobs_list.Length -eq 0){
                                Write-Host "Deleting Empty Container: $($container.Name)"
                                $container | Remove-AzStorageContainer -Force
                                Write-Host "Deleted Empty Container: $($container.Name)"
                            }
                        }
                        else{
                        
                            $UnusedDiagnosticBlobs += $_ | Select  Name, @{Name="VM Name"; Expression={$VM_name}} ,@{Name="ResourceGroup"; Expression={$storageAccount.ResourceGroupName}} , @{Name="Storage Account"; Expression={$storageAccount.StorageAccountName}} , @{Name="Container"; Expression={$container.Name}},@{Name="StorageType"; Expression={$storageAccount.Sku.Name}}, ContentType,@{Name="Size (KB)"; Expression={[math]::Round($_.Length/1KB)}} ,@{Name="Status"; Expression={"Unused"}}, @{Name="Blob URL"; Expression={$_.ICloudBlob.Uri.AbsoluteUri}}
                        }
                }
            }
        }
    }
}


if($deleteUnusedDiagnostics -eq 0){
    if($UnusedDiagnosticBlobs.Length -eq 0){

        Write-Host "There is no Unused bootdiagnostics blobs"

    }else{
        $UnusedDiagnosticBlobs | Format-Table -AutoSize
        $UnusedDiagnosticBlobs | Export-Csv -NoTypeInformation -Path $file
        Write-Host "Unused bootdiagnostics blobs written to $file"
    }
}