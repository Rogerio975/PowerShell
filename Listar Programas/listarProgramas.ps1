# Nome do computador remoto
$computerName = Read-Host "Digite o IP ou nome do computador"


# Função para listar programas instalados
function Get-InstalledPrograms {
    param (
        [string]$computerName
    )
    
    Write-Host "Conectando a $computerName..."
    
    try {
        # Testa a conectividade com o computador remoto
        if (Test-Connection -ComputerName $computerName -Count 1 -Quiet) {
            Write-Host "Listando programas instalados em $computerName..."

            # Usa Invoke-Command para obter a lista de programas instalados remotamente
            $installedPrograms = Invoke-Command -ComputerName $computerName -ScriptBlock {
                Get-WmiObject -Class Win32_Product | Select-Object Name, Version
            }

            # Exibe a lista de programas instalados
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

# Chama a função para listar programas instalados no computador "teste"
Get-InstalledPrograms -computerName $computerName

Write-Host "Listagem concluída em $computerName."