# Defina o hostname do computador remoto
$computerName = "Luciane"

# Caminho do instalador do programa (pode ser um compartilhamento de rede ou local). Escolhi o programa EPANET (br2setup.exe) devido a ser muito pequeno.
$installerPath = "C:\Users\Desktop\Downloads\br2setup.exe"

# Parâmetros de instalação silenciosa para o programa (verifique o instalador específico, pode ser /S, /silent, /quiet)
$installerArguments = "/S"

# Função para instalação remota
function Install {
    param (
        [string]$computerName
    )
    
    Write-Host "Conectando a $computerName..."
    
    try {
        # Testa a conectividade com o computador remoto
        if (Test-Connection -ComputerName $computerName -Count 1 -Quiet) {
            Write-Host "Instalando o programa em $computerName..."
            
            # Usa Invoke-Command para executar o comando de instalação remotamente
            Invoke-Command -ComputerName $computerName -ScriptBlock {
                param ($installerPath, $installerArguments)
                
                # Executa o instalador do programa
                Start-Process "$installerPath" -ArgumentList "$installerArguments" -Wait -NoNewWindow
                Write-Host "Instalação do programa concluída em $env:COMPUTERNAME"
            } -ArgumentList $installerPath, $installerArguments
            
        } else {
            Write-Host "Não foi possível conectar a $computerName"
        }
    } catch {
        Write-Host "Erro ao tentar instalar o programa em $computerName"
    }
}

# Chama a função para instalar o programa no computador "teste"
Install -computerName $computerName

Write-Host "Instalação concluída no computador remoto."