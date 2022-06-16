# Set deleteUnattachedNSGs=1 if you want to delete unattached NSGs
# Set deleteUnattachedNSGs=0 if you want to see the Id(s) of the unattached NSGs
$deleteUnattachedNSGs=Read-Host "enter 0 for List & 1 for Delete"

$NSG_Table = @()
$file="$HOME/unattached_NSGs.csv"

$unattachedNSGs = Get-AzNetworkSecurityGroup | Where-Object {$_.subnets.id -eq $null -and $_.networkinterfaces.id -eq $null}

foreach ($NSG in $unattachedNSGs) {

    if($deleteUnattachedNSGs -eq 1){

        Write-Host "Deleting unattached NSG with Id: $($NSG.Id)"
        $NSG | Remove-AzNetworkSecurityGroup -Force
        Write-Host "Deleted unattached NSG with Id: $($NSG.Id) "

    }else{

        $NSG_Table += $NSG | Select Name,ResourceGroupName,Id,@{Name="Status"; Expression={"Unattached"}} 

    }

}


if($deleteUnattachedNSGs -eq 0){
    if($NSG_Table.Length -eq 0){

        Write-Host "There is no unattached NSGs"

    }else{
        $NSG_Table | Format-Table -AutoSize
        $NSG_Table | Export-Csv -NoTypeInformation -Path $file
        Write-Host "Unttached NSGs written to $file"
    }
}