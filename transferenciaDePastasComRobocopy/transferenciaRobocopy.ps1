# --- Interface de Entrada ---
$ComputadorOrigem  = Read-Host "Digite o nome do computador de ORIGEM"
$Usuario           = Read-Host "Digite o nome do USUÁRIO"
$ComputadorDestino = "emb5022609" # Altere para o nome do seu servidor/PC de destino

# --- Configuração de Caminhos e Log ---
$Origem  = "\\$ComputadorOrigem\C$\Users\$Usuario\downloads"
$Destino = "\\$ComputadorDestino\C$\Backup_Migracao\$Usuario"
$LogFile = "C:\Logs\Backup_$($Usuario)_$(Get-Date -Format 'yyyyMMdd_HHmm').log"

# Garante que a pasta de logs local existe
<#
.SYNOPSIS
Cria o diretório de logs se não existir.

.DESCRIPTION
Verifica se o caminho "C:\Logs" existe. Caso não exista, cria um novo diretório nesse caminho.
A saída do comando New-Item é direcionada para Out-Null para suprimir mensagens de criação.

.EXAMPLE
if (!(Test-Path "C:\Logs")) { New-Item -ItemType Directory -Path "C:\Logs" | Out-Null }

.NOTES
- Test-Path: Testa se o caminho existe
- !(): Operador NOT (negação lógica)
- New-Item: Cria um novo item (neste caso, um diretório)
- Out-Null: Descarta a saída do comando
#>

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
    
    robocopy "$Origem" "$Destino" /E /ZB /R:3 /W:5 /MT:32 /V /ETA /XD AppData /XF *.exe *.msi /TEE /LOG+:"$LogFile"

    Write-Host "`nProcesso finalizado!" -ForegroundColor Green
    Write-Host "Relatório salvo em: $LogFile" -ForegroundColor Gray
} 
else {
    Write-Host "ERRO: O computador $ComputadorOrigem não respondeu ao ping." -ForegroundColor Red
}