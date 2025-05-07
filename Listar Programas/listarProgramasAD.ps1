# Solicitar as credenciais de usuário do Active Directory
$cred = Get-Credential

# Nome do computador remoto (no seu caso, 'teste')
$computerName = Read-Host "Digite o IP ou nome do computador"

# Função para listar programas instalados
function Get-InstalledPrograms {
    param (
        [string]$computerName,
        [PSCredential]$cred
    )
    
    Write-Host "Conectando a $computerName usando credenciais do Active Directory..."

    try {
        # Testar conectividade com o computador remoto
        if (Test-Connection -ComputerName $computerName -Count 1 -Quiet) {
            Write-Host "Listando programas instalados em $computerName..."

            # Usa Invoke-Command com credenciais do AD para executar remotamente
            $installedPrograms = Invoke-Command -ComputerName $computerName -Credential $cred -ScriptBlock {
                Get-WmiObject -Class Win32_Product | Select-Object Name, Version
            }

            # Exibir a lista de programas instalados
            if ($installedPrograms) {
                Write-Host "Programas instalados em $computerName"
                $installedPrograms | ForEach-Object {
                    Write-Host "$($_.Name) - Versão: $($_.Version)"
                }
            } else {
                Write-Host "Nenhum programa encontrado em $computerName."
            }
        } else {
            Write-Host "Não foi possível conectar a $computerName"
        }
    } catch {
        Write-Host "Erro ao tentar listar programas em $computerName"
    }
}

# Chamar a função para listar programas instalados no computador "teste" usando credenciais do AD
Get-InstalledPrograms -computerName $computerName -cred $cred

Write-Host "Listagem concluída em $computerName."