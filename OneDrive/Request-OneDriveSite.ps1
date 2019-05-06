function Request-OneDriveSite {
    param (
        [Parameter(Position=0,
        HelpMessage="Name of the tenant. E.g. Contoso", 
        Mandatory=$True)]
        [string]$TenantName,

        [Parameter(Position=1,
        HelpMessage="Path to file containing users UPN. E.g. C:\temp\users.txt", 
        Mandatory=$true)]
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
                #Write-Host "Failed to authenticate"
                $Error[0].Exception.Message
                Write-LogEntry -Error "Failed to authenticate" -ErrorRecord $Error[0]
                break
            }
            else {
                if($File){
                    $users = Get-Content -Path $File
                    $numUsers = ($users | Measure-Object -Line).Lines
                    Write-Host "Found $numUsers users in file"
                    Write-LogEntry -Info "Found $numUsers users in file"
                    foreach($user in $users){
                        $email = $user
                        $user = $user.Replace('@','_')
                        $user = $user.Replace('.','_')
                        $currentOneDrive = (Get-SPOSite -IncludePersonalSite $True -Limit All -Filter "Url -like '-my.sharepoint.com/personal/$user'").Url
                        
                        if($currentOneDrive){
                            Write-Host "User $email already provisioned"
                            Write-LogEntry -Info "User $email already provisioned for OneDrive - $currentOneDrive"
                        }
                        else{
                            Write-Host "Pre-provision $email..."
                            Write-LogEntry -Info "Preprovision $email"
                            Request-SPOPersonalSite -UserEmails $email
                            $provision = (Get-SPOSite -IncludePersonalSite $true -Limit all -Filter "Url -like '-my.sharepoint.com/personal/$user").Url
                            if($provision){
                                Write-LogEntry -Info $provision
                            }
                        }
                    }
                    Write-Host "Done."
                    $loglocation = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\'))" + "\log.log"
                    Write-Host "See logfile at $loglocation"
                }
            }  
    }
    else {
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
