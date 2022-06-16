# Set deleteUnattachedDisks=1 if you want to delete unattached Managed Disks
# Set deleteUnattachedDisks=0 if you want to see the Id of the unattached Managed Disks
$deleteUnattachedDisks= Read-Host -Prompt 'Enter 0 to list Disks & 1 for delete'

$disk = @()
$file="$HOME/unattached_Managed_disks.csv"
$managedDisks = Get-AzDisk
foreach ($md in $managedDisks) {
    # ManagedBy property stores the Id of the VM to which Managed Disk is attached to
    # If ManagedBy property is $null then it means that the Managed Disk is not attached to a VM
    if($md.ManagedBy -eq $null){
        if($deleteUnattachedDisks -eq 1){
            Write-Host "Deleting unattached Managed Disk with Id: $($md.Id)"
            $md | Remove-AzDisk -Force
            Write-Host "Deleted unattached Managed Disk with Id: $($md.Id) "
        }else{
            
            $disk += $md | Select Name,DiskSizeGB,ResourceGroupName,@{Name="type"; Expression={$_.Sku.Name}} ,@{Name="Status"; Expression={"Unattached"}} 
            
        }
    }
 }
 
 if($deleteUnattachedDisks -eq 0){
    if($disk.Length -eq 0){

        Write-Host "There is no unattached Managed Disks"

    }else{
        $disk | Format-Table -AutoSize
        $disk | Export-Csv -NoTypeInformation -Path $file
        Write-Host "Unttached disk list written to $file"
    }
 }