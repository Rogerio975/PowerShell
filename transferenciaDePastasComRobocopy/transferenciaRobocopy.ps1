# --- Interface de Entrada ---
$ComputadorOrigem  = Read-Host "Digite o nome do computador de ORIGEM"
$Usuario           = Read-Host "Digite o nome do USUÁRIO"
$ComputadorDestino = "SERVIDOR-BK" # Altere para o nome do seu servidor/PC de destino

# --- Configuração de Caminhos e Log ---
$Origem  = "\\$ComputadorOrigem\C$\Users\$Usuario"
$Destino = "\\$ComputadorDestino\C$\Backup_Migracao\$Usuario"
$LogFile = "C:\Logs\Backup_$($Usuario)_$(Get-Date -Format 'yyyyMMdd_HHmm').log"

# Garante que a pasta de logs local existe
if (!(Test-Path "C:\Logs")) { New-Item -ItemType Directory -Path "C:\Logs" | Out-Null }

Write-Host "`nVerificando conexão com $ComputadorOrigem..." -ForegroundColor Cyan

if (Test-Connection -ComputerName $ComputadorOrigem -Count 1 -Quiet) {
    
    Write-Host "Iniciando transferência. Acompanhe o progresso abaixo..." -ForegroundColor Yellow
    
    # Execução do Robocopy
    # /E   : Subpastas (inclui vazias)
    # /ZB  : Modo Backup (ignora travas de permissão simples)
    # /MT  : Multi-thread (velocidade)
    # /V   : Verbose (detalhes)
    # /ETA : Tempo estimado
    # /TEE : Mostra no console E grava no arquivo de log simultaneamente
    
    robocopy "$Origem" "$Destino" /E /ZB /R:3 /W:5 /MT:32 /V /ETA /XD AppData /TEE /LOG+:"$LogFile"

    Write-Host "`nProcesso finalizado!" -ForegroundColor Green
    Write-Host "Relatório salvo em: $LogFile" -ForegroundColor Gray
} 
else {
    Write-Host "ERRO: O computador $ComputadorOrigem não respondeu ao ping." -ForegroundColor Red
}