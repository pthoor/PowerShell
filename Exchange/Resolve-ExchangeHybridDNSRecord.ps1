<#
.Synopsis
    Check if TXT-record exist for Exchange Hybrid domains
.DESCRIPTION
    Save txt-file from Exchange Hybrid Configuration Wizard, make it comma-seperated CSV-file and 
    then use this PowerShell function to check if the DNS-record exist. 
    The fucntion can ask 1.1.1.1, 8.8.4.4 or 8.8.8.8.
.EXAMPLE
    Resolve-ExchangeHybridDNSRecord -CSVFile C:\Temp\Domains.csv -DNSServer 8.8.8.8
.EXAMPLE
    Resolve-ExchangeHybridDNSRecord -CSVFile C:\Temp\Domains.csv -DNSServer 1.1.1.1
.PARAMETER CSVFile
    Location to CSV file containing the headers 'Domain' and 'Value' from Exchange Hybrid Configuration Wizard
.PARAMETER DNSServer
    External DNS service used to query DNS-records, use between 1.1.1.1, 8.8.4.4 or 8.8.8.8
.OUTPUTS
    Writes to console (Write-Host)
.NOTES
    Version:        1.0
    Author:         Pierre Thoor, AddPro AB
    Creation Date:  2018-06-27
    Purpose/Change: Initial script development
#>
function Resolve-ExchangeHybridDNSRecord{
    Param(
        [Parameter(Position=0,
        HelpMessage="Path to CSV file containing Domain and Value header", 
        Mandatory=$True)]
        [ValidateScript({
        If(Test-Path $_ -PathType "Leaf"){$true}else{Throw "Invalid path given: $_"}
        })]
        [string]$CSVFile,

        [Parameter(Position=1,
        HelpMessage="External DNS service to query, choose between 1.1.1.1 | 8.8.4.4 | 8.8.8.8",
        Mandatory=$True)]
        [ValidateSet("1.1.1.1","8.8.4.4","8.8.8.8")]
        [string]$DNSServer
    )

    $DNSRecords = Import-Csv $CSVFile -Delimiter ","

    $DNSRecords | ForEach-Object{
        $ResolveDNS = Resolve-DnsName -Name $_.Domain -Type TXT -Server $DNSServer -ErrorAction SilentlyContinue
        if($ResolveDNS.Strings -eq $_.Value){
            Write-Host "DNS-Record exist for" $_.Domain -ForegroundColor Green
        }
        else{
            Write-Host " -> Error for" $_.Domain "<- " -ForegroundColor Red
        }
    }
}