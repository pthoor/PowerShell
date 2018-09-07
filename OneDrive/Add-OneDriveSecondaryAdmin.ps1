<#
.Synopsis
    Add an secondary administrators to users OneDrive for Business
.DESCRIPTION
    To add an secondary administrators to users OneDrive in your tenant
    for example migrating from Homefolders to OneDrive you need to add
    an Global Admin as an administrator for users OneDrive.  
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -GlobalAdmin "admin@contoso.onmicrosoft.com" -File "C:\temp\users.txt"
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -GlobalAdmin "admin@contoso.onmicrosoft.com" -File "C:\temp\users.txt" -WhatIf
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -GlobalAdmin "admin@contoso.onmicrosoft.com" -File "C:\temp\users.txt" -Confirm
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -GlobalAdmin "admin@contoso.onmicrosoft.com" -WhatIf
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -GlobalAdmin "admin@contoso.onmicrosoft.com" -Confirm
.PARAMETER TenantName
    Name of your tenant
.PARAMETER SecondaryAdmin
    UPN of the admin who will be added to users OneDrive
.PARAMETER GlobalAdmin
    UPN of the Global Admin who will connect via PowerShell to Office 365 (Connect-SPOService)
.PARAMETER File
    Path to file containing UPN of users we want to add an secondary administrator. If this is not specified the function will run on all users in the tenant.
.OUTPUTS
    Write-Host in current console
.NOTES
    Version:        1.0
    Author:         Pierre Thoor
    Creation Date:  2018-09-07
    Purpose/Change: Initial script development

    Updates:        Version 1.0 | 2018-09-07 | Initial script development
                    
#>
Function Add-OneDriveSecondaryAdmin
{
    [CmdletBinding(
        SupportsShouldProcess=$True,
        ConfirmImpact='High'
    )]
    Param(
        [Parameter(Position=0,
        HelpMessage="Name of the tenant. E.g. Contoso", 
        Mandatory=$True)]
        [string]$TenantName,

        [Parameter(Position=1,
        HelpMessage="UPN of the Global Administrator you want to add as an secondary admin", 
        Mandatory=$True)]
        [string]$SecondaryAdmin,

        [Parameter(Position=2,
        HelpMessage="Username of an Global Administrator who will connect using Connect-SPOService", 
        Mandatory=$True)]
        [string]$GlobalAdmin,

        [Parameter(Position=3,
        HelpMessage="Path to file containing users UPN. E.g. C:\temp\users.txt. If not specified, SecondaryAdmin will be added to all users in the tenant", 
        Mandatory=$false)]
        [ValidateScript({
        If(Test-Path $_ -PathType "leaf"){$true}else{Throw "Invalid path given: $_"}
        })]
        [string]$File
    )

    $Credential = Get-Credential -UserName $GlobalAdmin -Message "User must be a Global Admin"
    Connect-SPOService -Url https://$TenantName-admin.sharepoint.com $credential

    $OneDriveURLs = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'"

    if($File){
        if ($PSCmdlet.ShouldProcess("users specified in $File","Adding $SecondaryAdmin")){
            Get-Content -Path $File | ForEach-Object{
                if($OneDriveURLs.Owner -like $_){
                    $NewURL = $_ -replace '\.','_'
                    $NewURL = $NewURL -replace '@','_'
                    $OneDriveSite = Get-SPOSite -IncludePersonalSite $true -Filter "Url -like '-my.sharepoint.com/personal/$newurl'"
                    Set-SPOUser -Site $OneDriveSite -LoginName $SecondaryAdmin -IsSiteCollectionAdmin $false -ErrorAction SilentlyContinue | Out-Null
                    Write-Host "Updated secondary admin $SecondaryAdmin to $($OneDriveSite.URL)"
                }
                else{
                    Write-Host " -> Couldn't find OneDrive for user $_" -ForegroundColor Red
                }
            }
        }
    }
    else{
        if ($PSCmdlet.ShouldProcess("all users in $($TenantName.ToUpper()) tenant","Adding $SecondaryAdmin")){
            foreach($OneDriveURL in $OneDriveURLs)
            {
            Set-SPOUser -Site $OneDriveURL.URL -LoginName $SecondaryAdmin -IsSiteCollectionAdmin $True -ErrorAction SilentlyContinue | Out-Null
            Write-Host "Updated secondary admin $SecondaryAdmin to $($OneDriveURL.URL)" 
            }
        }
    }
}
