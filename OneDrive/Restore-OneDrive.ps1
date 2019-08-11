function Restore-OneDrive
{
    Param(
    [Parameter(Position=0,
        HelpMessage="Name of the tenant. E.g. Contoso", 
        Mandatory=$True)]
        [string]$TenantName,

        [Parameter(Position=1,
        HelpMessage="UPN of the user you want to restore OneDrive content", 
        Mandatory=$True)]
        [string]$UserEmail,

        [Parameter(Position=2,
        HelpMessage="Restore all objects in specified users recycle bin", 
        Mandatory=$false)]
        [switch]$RestoreAll
    
    )

    if(Get-Module -Name SharePointPnPPowerShellOnline){
        Import-Module SharePointPnPPowerShellOnline
        # Trim username
        $User = $UserEmail
        $User = $User.Replace('@','_')
        $User = $User.Replace('.','_')
        $OneDriveUrl = "https://$TenantName-my.sharepoint.com/personal/$User"
        Write-Output "Connecting to $OneDriveUrl"
        Connect-PnPOnline -Url $OneDriveUrl -UseWebLogin -Verbose
        if(Get-PnPConnection){
            $Count = Get-PnPRecycleBinItem
            Write-Output "User $userEmail has $($Count.count) objects in OneDrive Recycle Bin"
            if($RestoreAll){
                Write-Verbose "Starting restore..."
                $RecycleBinItem = Get-PnPRecycleBinItem
                $i = 0
                foreach ($item in $RecycleBinItem)
                {
                    $i++
                    Write-Progress -Activity “Restoring OneDrive” -Status "Restore file $i of $($count.count)" -PercentComplete (($i / $Count.count)*100)
                    Restore-PnPRecycleBinItem -Identity $item -Force
                }
                Write-Output "Done with restore of $($Count.count) objects"
            }
            else{
                Write-Output "Filter restore will be in a future update..."
            }
        }
        else{
            Write-Output "You do not have permissions to specified users OneDrive, add your admin account as secondary admin"
        }
    }
    else{
        if(Test-Administrator){
        Install-Module SharePointPnPPowerShellOnline -SkipPublisherCheck -AllowClobber
        }
        else{
        Write-Output "Run the function with administrative rights"
        }
    }

}

function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}