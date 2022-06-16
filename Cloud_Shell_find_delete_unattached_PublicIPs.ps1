# Set deleteUnattachedPublicIPs=1 if you want to delete unattached PublicIPs
# Set deleteUnattachedPublicIPs=0 if you want to see the Id(s) of the unattached PublicIPs
$deleteUnattachedPublicIPs=Read-Host "enter 0 for List & 1 for Delete"

$PublicIP_Table = @()
$file="$HOME/unattached_PublicIPs.csv"

$unattachedPublicIPs = Get-AzPublicIpAddress | Where-Object IpConfigurationText -EQ null 

foreach ($PublicIP in $unattachedPublicIPs) {

    if($deleteUnattachedPublicIPs -eq 1){

        Write-Host "Deleting unattached PublicIP with Id: $($PublicIP.Id)"
        $PublicIP | Remove-AzPublicIpAddress -Force
        Write-Host "Deleted unattached PublicIP with Id: $($PublicIP.Id) "

    }else{

        $PublicIP_Table += $PublicIP | Select Name,ResourceGroupName,Id,IpAddress, PublicIpAllocationMethod,@{Name="Status"; Expression={"Unattached"}} 

    }

}


if($deleteUnattachedPublicIPs -eq 0){
    if($PublicIP_Table.Length -eq 0){

        Write-Host "There is no unattached Public IPs"

    }else{
        $PublicIP_Table | Format-Table -AutoSize
        $PublicIP_Table | Export-Csv -NoTypeInformation -Path $file
        Write-Host "Unttached Public IPs written to $file"
    }
}