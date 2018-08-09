$users = Get-ADGroupMember -Identity "OneDrive for Business Users" | select SamAccountName
foreach ($user in $users){
    $HomeFolders = Get-ADUser $user.SamAccountName -Properties homedirectory | select Homedirectory
        foreach ($HomeFolder in $HomeFolders) {
            $Path = $HomeFolder.Homedirectory
            $Acl = (Get-Item $Path).GetAccessControl('Access')
            $Username = $user.SamAccountName
            $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($Username, 'Read', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
            $Acl.SetAccessRule($Ar)
            Set-Acl -path $Path -AclObject $Acl
            Write-Host "Replacing $Username's Full Control permission to Read on $Path."
        }
}