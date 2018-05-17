#define as variaveis para criacao de pasta e grupos
$path = "\\srv-file4\g$\Compartilhado\"
$newFolderName = Read-Host -Prompt "Digite o Nome da nova pasta"
$newFolderFull = $path + $newFolderName


#pergunta se Deseja realmente criar a pasta
Write-Output "A nova Pasta Sera: $newFolderFull"
$confirm = Read-Host "Nome da pasta Correta? Y/N"
If(($confirm) -ne "y")
{
 #termina o script
 Write-Output "Encerrando Script"
}
Else
{
#Criacao dos grupos do AD
Import-Module ActiveDirectory
Write-Output "Criar Grupos do AD"
$groupnameRW = "GAQM $newFolderName"
$groupnameR = "GAQL $newFolderName"
$groupnameS = "SHARE $newFolderName"
New-AdGroup $groupNameRW -samAccountName $groupNameRW -GroupScope Global -path "OU=Groups,OU=Matriz,OU=Localiza,OU=Corporacao,DC=localiza,DC=corp" -Description "Grupo de Acesso Modificacao a Q:\ $newFolderName"
New-AdGroup $groupNameR -samAccountName $groupNameR -GroupScope Global -path "OU=Groups,OU=Matriz,OU=Localiza,OU=Corporacao,DC=localiza,DC=corp" -Description "Grupo de Acesso leitura a Q:\ $newFolderName"
New-AdGroup $groupNameS -samAccountName $groupNameS -GroupScope Global -path "OU=Groups,OU=Matriz,OU=Localiza,OU=Corporacao,DC=localiza,DC=corp"
#Fim da Criacao dos Grupos do AD

#Cria a pasta no Compartilhado
Write-Output "Criando pasta no Compartilhado.."
New-Item $newFolderFull -ItemType Directory
#fim da criacao da pasta
Write-Output "Aplicando permissoes em pasta no Compartilhado.."
Start-Sleep 10
# Declaracao das variaveis de permissoes NTFS
$readOnly = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute"
$readWrite = [System.Security.AccessControl.FileSystemRights]"Modify"
$Share  = [System.Security.AccessControl.FileSystemRights]"Read"

# Inheritances
$inheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
$inheritanceFlag2 = [System.Security.AccessControl.InheritanceFlags]"None"
# Propagation
$propagationFlag = [System.Security.AccessControl.PropagationFlags]::None


# Declara os grupos de Usuario com os Acessos
$userRW = New-Object System.Security.Principal.NTAccount($groupNameRW)
$userR = New-Object System.Security.Principal.NTAccount($groupNameR)
$userS = New-Object System.Security.Principal.NTAccount($groupnameS)

# Define As ACL
$type = [System.Security.AccessControl.AccessControlType]::Allow
$accessControlEntryRW = New-Object System.Security.AccessControl.FileSystemAccessRule @($userRW, $readWrite, $inheritanceFlag, $propagationFlag, $type)
$accessControlEntryR = New-Object System.Security.AccessControl.FileSystemAccessRule @($userR, $readOnly, $inheritanceFlag, $propagationFlag, $type)
$accessControlEntryS = New-Object System.Security.AccessControl.FileSystemAccessRule @($userS, $Share, $inheritanceFlag2, $propagationFlag, $type)

#Aplica as permissoes na pasta
$objACL = Get-ACL $newFolderFull
Start-Sleep 5
$objACL.AddAccessRule($accessControlEntryRW)
$objACL.AddAccessRule($accessControlEntryR)
$objACL.AddAccessRule($accessControlEntryS)
Set-ACL $newFolderFull $objACL

#conecta ao file4 e seta a quota e cria o Share
Write-Output "Criando Share da pasta e criando quota padrao do compartilhado.."
Start-Sleep 5
$sesf4 = New-PSSession -ComputerName srv-file4
Invoke-Command -Session $sesf4 -ScriptBlock { param($newFolderName) 
#Criar Share da pasta 
New-SmbShare -Name "$newFolderName$" -Path "G:\Compartilhado\$newFolderName" -CachingMode Manual -FolderEnumerationMode AccessBased -FullAccess "Everyone" 
#configuar Quota da pasta
New-FsrmQuota -Path "G:\Compartilhado\$newFolderName" -Template "Localiza - Compartilhado 1.5GB" 
} -Args $newFolderName


#Criar referencia no DFS no File3
Write-Output "Criando Referencia no DFS.."
Start-Sleep 5
$sesf3 = New-PSSession -ComputerName srv-file3
Invoke-Command -Session $sesf3 -ScriptBlock { param($newFolderName) 
#cria a Referencia no DFS
New-DfsnFolderTarget -Path "\\localiza.corp\DFS\Compartilhado\$newFolderName"  -TargetPath "\\srv-file4\$newFolderName$"
#roda Script de Permissoes
Start-Process powershell -Verb runAs "C:\Script\permissaoFILE3auto.ps1"
} -Args $newFolderName

#Fim da Criacao
Write-Output "Pasta Criada Com sucesso, Acesse o servidor file4 para ajustar os alertas da quota"
Start-Sleep 30
}
