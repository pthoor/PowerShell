$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@


$Date = (Get-Date).AddDays(-10)
$DateOutput = Get-Date -Format "yyyyMMddHHmm"
$ResultPath = "C:\Temp\FilesToBeDeletedLogs"

[string[]]$Path = "C:\Temp"
$Target = "C:\Temp2"
$PathToExclude = [regex]'^C:\\Temp\\Zabbix|^C:\\Temp\\Intel Components'
$FoldersExcluded = $PathToExclude -replace '[|]',','
$FoldersExcluded = $FoldersExcluded -replace '\^'
$FoldersExcluded = $FoldersExcluded.Replace('\\','\')
$FoldersExcluded = $FoldersExcluded.Replace(',','</br>')

$Error.Clear()
$ErrorActionPreference = 'SilentlyContinue'

try {
    $i = 1
    $FilesToDelete = Get-ChildItem -Path $Path -Recurse | Where-Object {! $_.PSIsContainer -and $_.FullName -notmatch $PathToExclude -and $_.LastWriteTime -lt $Date}
       
    $FilesToDelete | ForEach-Object {
        Write-Progress -Activity "Checking $($_.name)" -Status "File $i of $($FilesToDelete.Count)" -CurrentOperation "Checking files to be deleted" -PercentComplete (($i / $FilesToDelete.Count) * 100)
        $i++
    }
    
    $LogFilesToDelete = $FilesToDelete | Sort-Object FullName | Select-Object FullName,DirectoryName,CreationTime,LastWriteTime,@{Name="Owner";Expression={ (Get-Acl $_.FullName).Owner }},@{Name="AccessPermissions";Expression={(Get-Acl $_.FullName).AccessToString}}
    $LogFilesToDelete | ConvertTo-Html -Head $Header -PreContent "Folders excluded: </br> $FoldersExcluded" | Out-File $ResultPath\"Report_HomeFolders $($DateOutput).html"
    $LogFilesToDelete | Export-Csv -Path $ResultPath\"Report_HomeFolders $($DateOutput).csv" -NoTypeInformation -Encoding UTF8 -Delimiter ";"

    $i = 1

    $FilesToDelete | ForEach-Object {
        Write-Progress -Activity "Moving $($_.name)" -Status "File $i of $($FilesToDelete.Count)" -CurrentOperation "Moving files to $($Target)" -PercentComplete (($i / $FilesToDelete.Count) * 100)
        $i++
        $NewPath = join-path $Target $_.DirectoryName.SubString($Path.length).Replace(':','')
        New-Item $NewPath -type Directory -ErrorAction SilentlyContinue
        Move-Item $_.FullName -Destination $NewPath -Verbose *>&1 | Out-File $ResultPath\"MoveItemLog $($DateOutput).txt" -Append            
    }
   

}
catch {

}
finally {
    $ErrorLog = $Error | ForEach-Object { $_.Exception.Message }
    $ErrorLog | Out-File -FilePath $ResultPath\"Errors_HomeFolders $($DateOutput).txt" -Encoding utf8
}
