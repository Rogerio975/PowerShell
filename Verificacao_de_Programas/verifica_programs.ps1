# Caminho do log
$logPath = "./Verificacao_de_Programas/verificacao_log.txt"
"Verificando programas instalados..." | Out-File -FilePath $logPath -Encoding utf8

# Lista de programas
$programsToCheck = @(
    "Google Chrome",
    "Mozilla Firefox",
    "7-Zip",
    "Notepad++"
    "Microsoft Visual C++ 2015-2019 Redistributable (x64)",
    "Office"
)
    # Caminhos de desinstalação
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$installedPrograms = Get-ItemProperty $uninstallPaths | Where-Object { $_.DisplayName } | Select-Object -ExpandProperty DisplayName

foreach ($program in $programsToCheck) {
    Write-Host ""
    Write-Host "Verificando: $program"
    Add-Content $logPath "`nVerificando: $program"

    if ($installedPrograms -match [regex]::Escape($program)) {
        Write-Host "[✓] $program está instalado." -ForegroundColor Green
        Add-Content $logPath "[✓] $program está instalado."
    } else {
        Write-Host "[x] $program NÃO está instalado." -ForegroundColor Red
        Add-Content $logPath "[x] $program NÃO está instalado."
    }
}

Write-Host "`nResultado salvo em: $logPath"