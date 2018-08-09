$users = Get-Content .\users.txt
$tenantname = "Contoso"

foreach($user in $users){
   $TOCsv = Get-ADUser -Filter {UserPrincipalName -eq $user} -properties homedirectory | select UserPrincipalName, Homedirectory
   $user = $user.Replace('@','_')
   $user = $user.Replace('.','_')
   Add-Content .\BulkUsers.csv "$($ToCSV.Homedirectory),,,https://$tenantname-my.sharepoint.com/personal/$user/,Documents,"

}

ii .\BulkUsers.csv