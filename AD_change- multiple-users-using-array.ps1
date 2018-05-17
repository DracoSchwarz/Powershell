#Import Modules for the running script
Import-Module ActiveDirectory

##--END Modules--

#Variables Set
$myArray = @(
#Put the entries under '' and , for multiple values
)

##--END Variables--

#Loop Structure
foreach ($element in $myArray) {
#Script for the loop

    $User = $element
    Get-ADUser -Identity $User | Set-ADObject -ProtectedFromAccidentalDeletion:$false 
    Start-Sleep 1
	Get-ADUser -Identity $User | move-ADObject -TargetPath "OU=Users,OU=ADM PAM,OU=Admins,OU=Global,DC=localiza,DC=corp" 
    Start-Sleep 2
	Get-ADUser -Identity $User | Set-ADObject -ProtectedFromAccidentalDeletion:$true
Write-Output "Usuario $User Alterado"

##--END Script for the loop--
}
##--END Loop Structure--