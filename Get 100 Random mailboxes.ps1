#Get All Mailboxes and Sort a hundred Random and Output to a CSV File
$OutputPath = "C:\100Mailboxes.csv"
$Rnum = 100
Get-Mailbox -ResultSize unlimited | Get-Random -Count $Rnum | Export-Csv -Path $OutputPath -Encoding UTF8 -Delimiter ';'

#End
