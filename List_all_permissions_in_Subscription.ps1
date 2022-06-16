$user_permission = @()
$file="$HOME/Users_permissions.csv"
$roleAssignments = Get-AzRoleAssignment -IncludeClassicAdministrators

foreach ($role in $roleAssignments) {
    if($role.ObjectType -ne "Unknown"){
        $user_permission += $role | Select @{Name="Name"; Expression={$_.DisplayName}},  @{Name="Type"; Expression={$_.ObjectType}}, @{Name="Permission"; Expression={$_.RoleDefinitionName}}, Scope
    }

}

$user_permission | Format-Table -AutoSize
$user_permission | Export-Csv -NoTypeInformation -Path $file
Write-Host "User permissions written to $file"