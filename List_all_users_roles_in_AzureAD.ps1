$roleUsers = @() 
$roles=Get-AzureADDirectoryRole
$file="$HOME/Users_Assigned_roles_in_AzureAD.csv"
 
ForEach($role in $roles) {
  $users=Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId
  ForEach($user in $users) {
    $obj = New-Object PSCustomObject
    $obj | Add-Member -type NoteProperty -name Name -value ""
    $obj | Add-Member -type NoteProperty -name Role -value ""
    $obj | Add-Member -type NoteProperty -name IsAdSynced -value false
    
    $obj.Name=$user.DisplayName

    if ($role.DisplayName -eq "Company Administrator" ){
        $obj.Role="Global administrator"
    }else{
        $obj.Role=$role.DisplayName
    }
    
    $obj.IsAdSynced=$user.DirSyncEnabled -eq $true
    $roleUsers+=$obj
  }
}


$roleUsers | Format-Table -AutoSize
$roleUsers | Export-Csv -NoTypeInformation -Path $file
Write-Host "Users assigned roles written to $file"