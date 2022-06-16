# Set deleteUnattachedNics=1 if you want to delete unattached NICs
# Set deleteUnattachedNics=0 if you want to see the Id(s) of the unattached NICs
$deleteUnattachedNics= Read-Host "Enter 0 to list Disks & 1 for delete"

$Nic_Table = @()
$file="$HOME/unattached_NICs.csv"

$unattachedNics = Get-AzNetworkInterface |  Where-Object {$_.VirtualMachine -eq $null}

foreach ($Nic in $unattachedNics) {

    if($deleteUnattachedNics -eq 1){

        Write-Host "Deleting unattached NIC with Id: $($Nic.Id)"
        $Nic | Remove-AzNetworkInterface -Force
        Write-Host "Deleted unattached NIC with Id: $($Nic.Id) "

    }else{

        $Nic_Table += $Nic | Select Name,ResourceGroupName,Id,@{Name="Status"; Expression={"Unattached"}} 

    }

}


if($deleteUnattachedNics -eq 0){
    if($Nic_Table.Length -eq 0){

        Write-Host "There is no unattached NICs"

    }else{
        $Nic_Table | Format-Table -AutoSize
        $Nic_Table | Export-Csv -NoTypeInformation -Path $file
        Write-Host "Unttached NICs written to $file"
    }
}