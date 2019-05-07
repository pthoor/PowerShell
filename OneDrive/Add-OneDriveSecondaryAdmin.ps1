<#
.Synopsis
    Add an secondary administrators to users OneDrive for Business
.DESCRIPTION
    To add an secondary administrators to users OneDrive in your tenant
    for example migrating from Homefolders to OneDrive you need to add
    an Global/SharePoint Admin as an administrator for users OneDrive.  
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -AddAdmin -File "C:\temp\users.txt" -WhatIf
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -AddAdmin -File "C:\temp\users.txt" -Confirm:$false / $true
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -RemoveAdmin -File "C:\temp\users.txt" -WhatIf
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -RemoveAdmin -File "C:\temp\users.txt" -Confirm:$false / $true
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -AddAdmin -WhatIf
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -AddAdmin -Confirm:$false / $true
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -RemoveAdmin -WhatIf
.EXAMPLE
    Add-OneDriveSecondaryAdmin -TenantName "Contoso" -SecondaryAdmin "admin@contoso.onmicrosoft.com" -RemoveAdmin -Confirm:$false / $true
.PARAMETER TenantName
    Name of your tenant
.PARAMETER SecondaryAdmin
    UPN of the admin who will be added to users OneDrive
.PARAMETER AddAdmin
    Parameter switch to add specified admin
.PARAMETER RemoveAdmin
    Parameter switch to remove specified admin
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
                    Version 1.1 | 2019-05-07 | Support for MFA and add switch for adding/removing secondary admin
                    
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
        HelpMessage="UPN of the Global/SharePoint Administrator you want to add as an secondary admin", 
        Mandatory=$True)]
        [string]$SecondaryAdmin,

        [Parameter(Position=2,
        HelpMessage="Adds Secondary Admin specified in SecondaryAdmin parameter", 
        Mandatory=$false)]
        [switch]$AddAdmin,

        [Parameter(Position=3,
        HelpMessage="Removes Secondary Admin specified in SecondaryAdmin parameter", 
        Mandatory=$false)]
        [switch]$RemoveAdmin,

        [Parameter(Position=4,
        HelpMessage="Path to file containing users UPN. E.g. C:\temp\users.txt. If not specified, SecondaryAdmin will be added to all users in the tenant", 
        Mandatory=$false)]
        [ValidateScript({
        If(Test-Path $_ -PathType "leaf"){$true}else{Throw "Invalid path given: $_"}
        })]
        [string]$File
    )

    Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $module = Get-Module -Name Microsoft.Online.SharePoint.PowerShell
    Write-Host "Checking SharePoint Online PowerShell module..."

    if($module){
        Write-Host "Connecting to SharePoint Online..."
        Write-LogEntry -Info "Connecting to SharePoint Online"
        $url = "https://" + $TenantName + ".sharepoint.com"
        try {
            Get-SPOSite -Identity $url | Out-Null
        }
        catch {
            Write-Host "Running Connect-SPOService"
            try {
                Connect-SPOService -Url https://$tenantname-admin.sharepoint.com -ErrorVariable failedAuth -ErrorAction Stop
            }
            catch {
                Write-Host "Failed to authenticate"
            }
            
        }
    
        if($failedAuth){
            $Error[0].Exception.Message
            Write-LogEntry -Error "Failed to authenticate" -ErrorRecord $Error[0]
            break
        }
        else {
            $OneDriveURLs = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'"
            if($File){
                $users = Get-Content -Path $File
                $numUsers = ($users | Measure-Object -Line).Lines
                Write-Host "Found $numUsers users in file"
                Write-LogEntry -Info "Found $numUsers users in file"
                if($AddAdmin -eq $True){
                    Write-Host "AddAdmin switch specified"
                    Write-LogEntry -Info "AddAdmin switch specified"
                    if ($PSCmdlet.ShouldProcess("users specified in $File","Adding $SecondaryAdmin")){
                        Get-Content -Path $File | ForEach-Object{
                            if($OneDriveURLs.Owner -like $_){
                                $NewURL = $_ -replace '\.','_'
                                $NewURL = $NewURL -replace '@','_'
                                $OneDriveSite = Get-SPOSite -IncludePersonalSite $true -Filter "Url -like '-my.sharepoint.com/personal/$newurl'"
                                Set-SPOUser -Site $OneDriveSite -LoginName $SecondaryAdmin -IsSiteCollectionAdmin $true -ErrorAction SilentlyContinue | Out-Null
                                Write-Host "Added secondary admin $SecondaryAdmin to $($OneDriveSite.URL)"
                                Write-LogEntry -Info "Added secondary admin $SecondaryAdmin to $($OneDriveSite.URL)"
                            }
                            else{
                                Write-Host "Couldn't find OneDrive for user $_" -ForegroundColor Red
                                Write-LogEntry -Error "Couldn't find OneDrive for user $_"
                            }
                        }
                    }
                }
                elseif($RemoveAdmin -eq $true){
                    Write-Host "RemoveAdmin switch specified"
                    Write-LogEntry -Info "RemoveAdmin switch specified"
                    if ($PSCmdlet.ShouldProcess("users specified in $File","Removing $SecondaryAdmin")){
                        Get-Content -Path $File | ForEach-Object{
                            if($OneDriveURLs.Owner -like $_){
                                $NewURL = $_ -replace '\.','_'
                                $NewURL = $NewURL -replace '@','_'
                                $OneDriveSite = Get-SPOSite -IncludePersonalSite $true -Filter "Url -like '-my.sharepoint.com/personal/$newurl'"
                                Set-SPOUser -Site $OneDriveSite -LoginName $SecondaryAdmin -IsSiteCollectionAdmin $false -ErrorAction SilentlyContinue | Out-Null
                                Write-Host "Removed secondary admin $SecondaryAdmin for $($OneDriveSite.URL)"
                                Write-LogEntry -Info "Removed secondary admin $SecondaryAdmin for $($OneDriveSite.URL)"
                            }
                            else{
                                Write-Host "Couldn't find OneDrive for user $_" -ForegroundColor Red
                                Write-LogEntry -Error "Couldn't find OneDrive for user $_"
                            }
                        }
                    }
                }
                else{
                    Write-Host "No switch parameter specified, please specify AddAdmin or RemoveAdmin" -ForegroundColor Red
                    Write-LogEntry -Error "No switch parameter specified, please specify AddAdmin or RemoveAdmin"
                    break
                }
                Write-Host "Done."
                $loglocation = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\'))" + "\log.log"
                Write-Host "See logfile at $loglocation"
            }
            else{
                if($AddAdmin -eq $True){
                    if ($PSCmdlet.ShouldProcess("all users in $($TenantName.ToUpper()) tenant","Adding $SecondaryAdmin")){
                        foreach($OneDriveURL in $OneDriveURLs)
                        {
                        Set-SPOUser -Site $OneDriveURL.URL -LoginName $SecondaryAdmin -IsSiteCollectionAdmin $True -ErrorAction SilentlyContinue | Out-Null
                        Write-Host "Added secondary admin $SecondaryAdmin to $($OneDriveURL.URL)"
                        Write-LogEntry -Info "Added secondary admin $SecondaryAdmin to $($OneDriveURL.URL)"
                        }
                    }
                }
                elseif($RemoveAdmin -eq $True){
                    if ($PSCmdlet.ShouldProcess("all users in $($TenantName.ToUpper()) tenant","Removing $SecondaryAdmin")){
                        foreach($OneDriveURL in $OneDriveURLs)
                        {
                        Set-SPOUser -Site $OneDriveURL.URL -LoginName $SecondaryAdmin -IsSiteCollectionAdmin $false -ErrorAction SilentlyContinue | Out-Null
                        Write-Host "Removed secondary admin $SecondaryAdmin for $($OneDriveURL.URL)"
                        Write-LogEntry -Info "Removed secondary admin $SecondaryAdmin for $($OneDriveURL.URL)"
                        }
                    }
                }
                else{
                    Write-Host "No switch parameter specified, please specify AddAdmin or RemoveAdmin" -ForegroundColor Red
                    Write-LogEntry -Error "No switch parameter specified, please specify AddAdmin or RemoveAdmin"
                    break
                }
                Write-Host "Done."
                $loglocation = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\'))" + "\log.log"
                Write-Host "See logfile at $loglocation"
            }
        }
    }
    else{
        Write-Host "SharePoint Online PowerShell Module not installed" -ForegroundColor Red
        Write-LogEntry -Error "SharePoint Online PowerShell Module not installed" -ErrorRecord $Error[0]
    }
}

function Write-LogEntry
{
    [CmdletBinding(DefaultParameterSetName = 'Info',
        SupportsShouldProcess=$true,
        PositionalBinding=$false,
        HelpUri = 'https://github.com/MSAdministrator/WriteLogEntry',
        ConfirmImpact='Medium')]
    [OutputType()]
    Param
    (
        # Information type of log entry
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0,
            ParameterSetName = 'Info')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("information")]
        [System.String]$Info,

        # Debug type of log entry
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0,
            ParameterSetName = 'Debug')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.String]$Debugging,

        # Error type of log entry
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0,
            ParameterSetName = 'Error')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.String]$Error,

        # The error record containing an exception to log
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false,
            Position=1,
            ParameterSetName = 'Error')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("record")]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        # Logfile location
        [Parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            Position=2)]
        [Alias("file", "location")]
        [System.String]$LogFile = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\'))" + "\log.log"
    )

    if (!(Test-Path -Path $LogFile))
    {
        try
        {
            New-Item -Path $LogFile -ItemType File -Force | Out-Null
        }
        catch
        {
            Write-Error -Message 'Error creating log file'
            break
        }
    }

    $mutex = New-Object -TypeName 'Threading.Mutex' -ArgumentList $false, 'MyInterprocMutex'

    switch ($PSBoundParameters.Keys)
    {
        'Error'
        {
            $mutex.waitone() | Out-Null
            Add-Content -Path $LogFile -Value "$((Get-Date).ToString('yyyyMMddThhmmss')) [ERROR]: $Error"

            if ($PSBoundParameters.ContainsKey('ErrorRecord'))
            {
                $Message = '{0} ({1}: {2}:{3} char:{4})' -f $ErrorRecord.Exception.Message,
                                                            $ErrorRecord.FullyQualifiedErrorId,
                                                            $ErrorRecord.InvocationInfo.ScriptName,
                                                            $ErrorRecord.InvocationInfo.ScriptLineNumber,
                                                            $ErrorRecord.InvocationInfo.OffsetInLine

                Add-Content -Path $LogFile -Value "$((Get-Date).ToString('yyyyMMddThhmmss')) [ERROR]: $Message"
            }

            $mutex.ReleaseMutex() | Out-Null
        }
        'Info'
        {
            $mutex.waitone() | Out-Null
            Add-Content -Path $LogFile -Value "$((Get-Date).ToString('yyyyMMddThhmmss')) [INFO]: $Info"
            $mutex.ReleaseMutex() | Out-Null
        }
        'Debugging'
        {
            Write-Debug -Message "$Debugging"
            $mutex.waitone() | Out-Null
            Add-Content -Path $LogFile -Value "$((Get-Date).ToString('yyyyMMddThhmmss')) [DEBUG]: $Debugging"
            $mutex.ReleaseMutex() | Out-Null
        }
    }#End of switch statement
} # end of Write-LogEntry function
