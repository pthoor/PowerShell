# Run in Exchange Management Shell On-Premise

$list = @()
$mbs = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox,SharedMailbox
foreach ($mb in $mbs)
{
	$stat = Get-MailboxStatistics $mb
	
	$list += New-Object PSObject -Property @{
		DisplayName = $mb.DisplayName
		PrimarySMTPAddress = $mb.PrimarySMTPAddress
		Lastlogontime = $stat.Lastlogontime
	}
}
$list | Sort-Object Lastlogontime -Descending | Select-Object DisplayName, Lastlogontime, PrimarySMTPAddress | Out-File C:\Temp\ActiveMailboxes_New.txt