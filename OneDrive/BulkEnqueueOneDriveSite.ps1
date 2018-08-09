<#
.SYNOPSIS
 This script adds an entry for each user specified in the input file 
 into the OneDrive provisioning queue.
 
 
.DESCRIPTION
 This script reads a text file with a line for each user. 
 Provide the User Principal Name of each user on a new line.
 An entry will be made in the OneDrive provisioning queue for each
 user up to 200 users.

.EXAMPLE

 .\BulkEnqueueOneDriveSite.ps1 -SPOAdminUrl https://contoso-admin.sharepoint.com -InputfilePath C:\users.txt 

.PARAMETER SPOAdminUrl
 The URL for the SharePoint Admin center
 https://contoso-admin.sharepoint.com

.PARAMETER InputFilePath
 The path to the input file.
 The file must contain 1 to 200 users
 C:\users.txt

.NOTES
 This script needs to be run by a SharePoint Online Tenant Administrator
 This script will prompt for the username and password of the Tenant Administrator
#>

param
(
    #Must be SharePoint Administrator URL
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SPOAdminUrl,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $InputFilePath
)

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.UserProfiles") | Out-Null

$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SPOAdminUrl)

$Users = Get-Content -Path $InputFilePath

if ($Users.Count -eq 0 -or $Users.Count -gt 200)
{
    Write-Host $("Unexpected user count: [{0}]" -f $Users.Count) -ForegroundColor Red
    return 
}

$web = $ctx.Web
Write-Host "Please enter a Tenant Admin username" -ForegroundColor Green
$username = Read-Host

Write-Host "Please enter your password" -ForegroundColor Green
$password = Read-Host -AsSecureString

$ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username,$password )
$ctx.Load($web)
$ctx.ExecuteQuery()

$loader = [Microsoft.SharePoint.Client.UserProfiles.ProfileLoader]::GetProfileLoader($ctx)
$ctx.ExecuteQuery()

$loader.CreatePersonalSiteEnqueueBulk($Users)
$loader.Context.ExecuteQuery()

Write-Host "Script Completed"