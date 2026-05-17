# =========================================================
# DESINSTALADOR REMOTO OFFICE 365 VIA PsExec
# =========================================================
# Requisitos:
# - PsExec.exe
# - Permissão administrativa no computador remoto
# - Compartilhamento ADMIN$ habilitado
# =========================================================

Clear-Host

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " DESINSTALADOR REMOTO OFFICE 365 - PsExec" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Caminho do PsExec
$PsExec = "C:\PsExec\PsExec.exe"

# Verifica se o PsExec existe
if (!(Test-Path $PsExec)) {

    Write-Host "PsExec.exe não encontrado em:" -ForegroundColor Red
    Write-Host $PsExec -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Baixe o PsExec em:" -ForegroundColor Cyan
    Write-Host "https://learn.microsoft.com/sysinternals/downloads/psexec"

    Pause
    exit

}

# Nome ou IP do computador
$Computador = Read-Host "Digite o nome ou IP do computador"

# Credenciais
$Usuario = Read-Host "Digite o usuário administrador"
$Senha = Read-Host "Digite a senha" -AsSecureString

# Converte senha
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Senha)
$SenhaTexto = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host ""
Write-Host "Testando conectividade..." -ForegroundColor Yellow

if (Test-Connection -ComputerName $Computador -Count 2 -Quiet) {

    Write-Host "Computador online." -ForegroundColor Green
    Write-Host ""

    # Comando remoto para desinstalar Office 365 / Microsoft 365
    $remoteScript = @'
$apps = Get-WmiObject -Class Win32_Product -Filter "Name LIKE ''%Microsoft Office%365%'' OR Name LIKE ''%Microsoft Office 365%'' OR Name LIKE ''%Microsoft 365%''" -ErrorAction SilentlyContinue
if ($apps) {
    foreach ($app in $apps) {
        Write-Host "Desinstalando: $($app.Name)"
        $app.Uninstall() | Out-Null
    }
}
else {
    $c2rExe = Join-Path $env:ProgramFiles 'Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe'
    if (Test-Path $c2rExe) {
        Write-Host "Office Click-to-Run encontrado. Tentando desinstalar..."
        & $c2rExe /uninstall O365ProPlusRetail /quiet
    }
    else {
        Write-Host "Office 365 não encontrado via WMI e Click-to-Run não está instalado."
        exit 1
    }
}
'@

    $EncodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($remoteScript))
    $ComandoRemoto = "powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand $EncodedCommand"

    Write-Host "Executando desinstalação remota..." -ForegroundColor Yellow
    Write-Host ""

    & $PsExec `
        "\\$Computador" `
        -u $Usuario `
        -p $SenhaTexto `
        -h `
        cmd /c $ComandoRemoto

    Write-Host ""
    Write-Host "Processo finalizado." -ForegroundColor Green

}
else {

    Write-Host "Não foi possível conectar ao computador." -ForegroundColor Red

}

Write-Host ""
Pause