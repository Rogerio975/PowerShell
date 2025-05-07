# Solicite o nome do usuário
$userName = Read-Host "Digite o nome do usuário a ser pesquisado"

# Solicite as credenciais do usuário
$cred = Get-Credential

# Pesquise o logon do usuário no domínio usando as credenciais fornecidas
Get-ADUser -Credential $cred -Identity $userName -Properties LastLogon | ForEach-Object {
    $lastLogon = $_.LastLogon
    $computerName = Get-EventLog -LogName Security -Newest 1000 | Where-Object {
        $_.InstanceId -eq 4624 -and $_.ReplacementStrings[5] -eq $userName
    } | Select-Object -ExpandProperty MachineName
    Write-Output "$userName está logado em: $computerName (Último logon: $lastLogon)"
}