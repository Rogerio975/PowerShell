# Script para atualizar todos os pacotes via WinGet
# Destinado a execução via Agendador de Tarefas do Windows

$logFile = "$env:TEMP\WingetAutoUpdate.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Output "[$timestamp] Iniciando atualização automática..." | Out-File -FilePath $logFile -Append

try {
    # Executa o upgrade de todos os aplicativos. 
    # --accept-package-agreements e --accept-source-agreements são cruciais para automação (evitam prompts)
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Sucesso: Todos os pacotes processados." | Out-File -FilePath $logFile -Append
    } else {
        Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Aviso: Winget terminou com código de saída $LASTEXITCODE." | Out-File -FilePath $logFile -Append
    }
} catch {
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERRO: $_" | Out-File -FilePath $logFile -Append
}
