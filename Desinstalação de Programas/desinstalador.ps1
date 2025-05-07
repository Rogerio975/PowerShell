# Configurações
$remoteComputer = "NomeDoComputadorRemoto"  # Substitua pelo nome ou IP do computador remoto
$programName = "NomeDoPrograma"            # Substitua pelo nome do programa a ser desinstalado
$psexecPath = "C:\PSTools\PsExec.exe"      # Substitua pelo caminho do PsExec

# Comando para localizar o programa no computador remoto
$wmicCommand = "wmic product where ""name like '%$programName%'"" call uninstall /nointeractive"

# Executa o comando remoto usando PsExec
try {
    Write-Host "Iniciando desinstalação do programa '$programName' no computador remoto '$remoteComputer'..."
    & $psexecPath \\$remoteComputer cmd /c $wmicCommand

    Write-Host "Comando enviado. Verifique se o programa foi desinstalado com sucesso."
} catch {
    Write-Error "Erro ao tentar desinstalar o programa: $_"
}