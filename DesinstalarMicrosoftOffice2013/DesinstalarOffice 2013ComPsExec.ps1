# =========================================================
# DESINSTALADOR REMOTO OFFICE 2013 VIA PsExec
# =========================================================
# Requisitos:
# - PsExec.exe
# - Permissão administrativa no computador remoto
# - Compartilhamento ADMIN$ habilitado
# =========================================================

Clear-Host

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " DESINSTALADOR REMOTO OFFICE 2013 - PsExec" -ForegroundColor Cyan
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

    # Comando remoto
    $ComandoRemoto = 'wmic product where "name like ''Microsoft Office%%2013%%''" call uninstall /nointeractive'

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