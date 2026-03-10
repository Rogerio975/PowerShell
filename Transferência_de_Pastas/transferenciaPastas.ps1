# Script para transferência de pastas em ambiente Active Directory
# Preserva permissões NTFS, Datas e Atributos

$SourcePath = "\\SERVIDOR-ORIGEM\Compartilhamento\Pasta"
$DestPath   = "\\SERVIDOR-DESTINO\Compartilhamento\Destino"

# Log para auditoria
$LogFile = "C:\Logs\Transferencia_AD_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

if (!(Test-Path $SourcePath)) {
    Write-Error "Caminho de origem não encontrado."
    exit
}

$RobocopyOptions = @(
    "/E",           # Copia subdiretórios, inclusive os vazios
    "/COPYALL",     # Copia tudo: Dados, Atributos, Datas, ACLs (NTFS), Proprietário e Auditoria
    "/ZB",          # Modo reiniciável; se acesso negado, usa modo de Backup
    "/R:3",         # Tenta novamente 3 vezes em caso de falha
    "/W:5",         # Aguarda 5 segundos entre as tentativas
    "/MT:16",       # Multi-threaded (mais rápido para muitos arquivos pequenos)
    "/LOG:$LogFile",# Gera log da operação
    "/TEE",         # Exibe a saída no console e no log
    "/NP"           # Não exibe o progresso (evita poluir o log)
)

Write-Host "Iniciando transferência de $SourcePath para $DestPath..." -ForegroundColor Cyan

Start-Process robocopy -ArgumentList "`"$SourcePath`"", "`"$DestPath`"", $RobocopyOptions -Wait

if ($LASTEXITCODE -lt 8) {
    Write-Host "Transferência concluída com sucesso!" -ForegroundColor Green
} else {
    Write-Host "Erro detectado durante a cópia. Verifique o log em $LogFile" -ForegroundColor Red
}