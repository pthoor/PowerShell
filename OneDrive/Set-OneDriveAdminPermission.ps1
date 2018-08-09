#----
#Set LogfilePath
$LogFilePath = "C:\Users\Administrator\Desktop\AdminUpdate-$(get-date -uformat '%Y-%m-%d-%H_%M').csv"

#----

#Set Variables- AdminUPN must be a global admin account
$adminUPN="admin@contoso.onmicrosoft.com"
$TennantName="contoso"
$secondaryadmin1 = "admin@contoso.onmicrosoft.com"
#$secondaryadmin2 = "admin2@contoso.onmicrosoft.com"

#----

$Credential = Get-Credential -UserName $adminUPN -Message "User Must be a Global Admin"
Connect-SPOService -Url https://$TennantName-admin.sharepoint.com $credential

# Specify your organisation admin central url

$AdminURI = "https://$TennantName-admin.sharepoint.com"
$siteURI = "https://$TennantName-my.sharepoint.com"

$loadInfo1 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
$loadInfo2 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")
$loadInfo3 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.UserProfiles")

$creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials ($credential.UserName, $credential.Password)

# Add the path of the User Profile Service to the SPO admin URL, then create a new webservice proxy to access it

$proxyaddr = "$AdminURI/_vti_bin/UserProfileService.asmx?wsdl"
$UserProfileService= New-WebServiceProxy -Uri $proxyaddr -UseDefaultCredential False
$UserProfileService.Credentials = $creds

# Set variables for authentication cookies

$strAuthCookie = $creds.GetAuthenticationCookie($AdminURI)
$uri = New-Object System.Uri($AdminURI)
$container = New-Object System.Net.CookieContainer
$container.SetCookies($uri, $strAuthCookie)
$UserProfileService.CookieContainer = $container

# Sets the first User profile, at index -1

$UserProfileResult = $UserProfileService.GetUserProfileByIndex(-1)
Write-Output "Starting- This could take a while."
$NumProfiles = $UserProfileService.GetUserProfileCount()
$i = 1

# As long as the next User profile is NOT the one we started with (at -1)...

While ($UserProfileResult.NextValue -ne -1)

{

Write-Output "Examining profile $i of $NumProfiles"

"Examining profile $i of $NumProfiles" | Out-File $LogFilePath -Append

# Look for the Personal Space object in the User Profile and retrieve it

# (PersonalSpace is the name of the path to a user's OneDrive for Business site.

# Users who have not yet created a OneDrive for Business site might not have this property set.)

$Prop = $UserProfileResult.UserProfile | Where-Object { $_.Name -eq "PersonalSpace" }

$Url= $Prop.Values[0].Value

# If OneDrive is activated for the user, then set the secondary admin

if ($Url) {

$sitename = $siteURI + $Url

  try

  {

  #If you change the $false to $true this will add a secondary user rather than remove it

    $temp1 = Set-SPOUser -Site $sitename -LoginName $secondaryadmin1 -IsSiteCollectionAdmin $true

    #$temp2 = Set-SPOUser -Site $sitename -LoginName $secondaryadmin2 -IsSiteCollectionAdmin $true

    Write-Output "Updated Secondary Admins for:" $sitename

    "Updated Secondary Admin for: $sitename" | Out-File $LogFilePath -Append

  }

  catch [System.Exception]

  {

   Write-Output $Error[0].Exception

   $Error[0].Exception| Out-File $LogFilePath -Append

  }

}

# And now we check the next profile the same way...

$UserProfileResult = $UserProfileService.GetUserProfileByIndex($UserProfileResult.NextValue)

$i++

}

Write-Output "Completed assigning secondary admin to all users"