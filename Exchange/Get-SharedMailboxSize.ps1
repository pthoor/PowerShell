<#
.Synopsis
    Check if Shared Mailboxes need Exchange Online Plan 2 license
.DESCRIPTION
    Get sizes of all Shared Mailboxes in Office 365 tenant to check if a Shared Mailbox need
    Exchange Online Plan 2 license. If the mailbox exceeds 50GB in size, that mailbox need
    a license. You need to run the function in Exchange Online PowerShell module or PowerShell ISE
.EXAMPLE
    Get-SharedMailboxSize -FilePath C:\Temp\
.PARAMETER FilePath
    Location to save the HTML file
.OUTPUTS
    Will open the HTML file with Invoke-Expression $FilePath\SharedMailboxSizes.html
.NOTES
    Version:        1.0
    Author:         Pierre Thoor, AddPro AB
    Creation Date:  2018-06-28
    Purpose/Change: Initial script development
#>

function Get-SharedMailboxSize{
    Param(
        [Parameter(Position=0,
        HelpMessage="Path to save HTML file. E.g. C:\temp", 
        Mandatory=$True)]
        [ValidateScript({
        If(Test-Path $_ -PathType "container"){$true}else{Throw "Invalid path given: $_"}
        })]
        [string]$FilePath
    )

Write-Host "Checking if Exchange Online PowerShell Module is installed..." -ForegroundColor Yellow

$ExoPsSession = (Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter CreateExoPSSession.ps1 -Recurse | sort LastWriteTime).FullName | Select-Object -Last 1

if($ExoPsSession)
{
    Write-Host "Module found, importing the module..." -ForegroundColor Green
    Start-Sleep -Seconds 2
    Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter CreateExoPSSession.ps1 -Recurse | sort LastWriteTime).FullName | Select-Object -Last 1)
    Start-Sleep -Seconds 5
    Connect-EXOPSSession
}
else
{
    Write-Host "You need to install Exchange Online PowerShell Module..." -ForegroundColor Red
    Write-Host "Going to http://aka.ms/exopspreview to download the module..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    Start-Process "http://aka.ms/exopspreview"
    Write-Host "Install the module and run the PowerShell function again" -ForegroundColor Red
}

$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@


$SharedMailboxesOver48 = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited -ErrorAction SilentlyContinue | Get-MailboxStatistics -ErrorAction SilentlyContinue | Select-Object DisplayName,
    @{
        name       = "TotalItemSize(MB)"
        expression = {
          [Math]::floor(
            [int]($_.TotalItemSize.value.ToString() -replace '[A-Z0-9.\s]+\(' -replace '\sbytes\)' -replace ',') / 1MB
          )
        }
    },
    ItemCount |
    Where-Object {$_."TotalItemSize(MB)" -gt 48GB/1MB} | Sort-Object "TotalItemSize(MB)" -Descending | ConvertTo-Html -fragment -PreContent '<h2>Shared Mailboxes that needs Exchange Online Plan 2 license</h2>'


$SharedMailboxesBelow48 = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited -ErrorAction SilentlyContinue | Get-MailboxStatistics -ErrorAction SilentlyContinue | Select-Object DisplayName,
    @{
        name       = "TotalItemSize(MB)"
        expression = {
          [Math]::floor(
            [int]($_.TotalItemSize.value.ToString() -replace '[A-Z0-9.\s]+\(' -replace '\sbytes\)' -replace ',') / 1MB
          )
        }
    },
    ItemCount |
    Where-Object {$_."TotalItemSize(MB)" -lt 48GB/1MB} | Sort-Object "TotalItemSize(MB)" -Descending | ConvertTo-Html -fragment -PreContent '<h2>Shared Mailboxes that does not need license</h2>'



if($SharedMailboxesOver48 -and $SharedMailboxesBelow48)
{
    ConvertTo-Html -Head $Header -body "$SharedMailboxesOver48 $SharedMailboxesBelow48" | Out-File C:\temp\SharedMailboxSizes.HTML
}
elseif($SharedMailboxesBelow48)
{
       ConvertTo-Html -Head $Header -body "$SharedMailboxesBelow48" | Out-File C:\temp\SharedMailboxSizes.HTML 
}
else{
    Write-Host "Generic error" -ForegroundColor Red
}


Write-Host "Testing if $FilePath\SharedMailboxSizes.HTML exists..." -ForegroundColor Yellow
if (Test-Path -Path $FilePath\SharedMailboxSizes.HTML)
{
    Write-Host "File found! Opening in 5 seconds..." -ForegroundColor Green
    Start-Sleep -Seconds 5
    Invoke-Expression $FilePath\SharedMailboxSizes.html
}
else{
    Write-Host "File not found, script couldn't run properly" -ForegroundColor Red
}

}