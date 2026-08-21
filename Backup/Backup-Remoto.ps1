[CmdletBinding()]
param(
    [string]$Hostname,
    [string]$Login
)

$ErrorActionPreference = 'Stop'
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$startTime = Get-Date
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$stagingPath = Join-Path $env:TEMP "BackupRemoto_$timestamp"
$localLogPath = Join-Path $env:TEMP "BackupRemoto_$timestamp.log"
$backupRoot = '\\serv\c$\backups'
$zipPath = $null
$remoteLogPath = $null

function Write-Log {
    param([string]$Message)

    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $localLogPath -Value $line
    Write-Host $line
}

try {
    if ([string]::IsNullOrWhiteSpace($Hostname)) {
        $Hostname = Read-Host 'Digite o hostname do computador de origem'
    }

    if ([string]::IsNullOrWhiteSpace($Login)) {
        $Login = Read-Host 'Digite o login do usuario'
    }

    $Hostname = $Hostname.Trim()
    $Login = $Login.Trim()
    $profileName = ($Login -split '\\')[-1]
    $safeLogin = ($profileName -replace '[^a-zA-Z0-9._-]', '_')
    $sourcePath = "\\$Hostname\c$\Users\$profileName"
    $zipPath = Join-Path $backupRoot "${Hostname}_${safeLogin}_$timestamp.zip"
    $remoteLogPath = Join-Path $backupRoot "${Hostname}_${safeLogin}_$timestamp.log"

    if ([string]::IsNullOrWhiteSpace($Hostname) -or [string]::IsNullOrWhiteSpace($profileName)) {
        throw 'Hostname e login sao obrigatorios.'
    }

    if (-not (Test-Path -LiteralPath $backupRoot)) {
        throw "Nao foi possivel acessar o destino: $backupRoot"
    }

    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Nao foi possivel acessar a origem: $sourcePath"
    }

    New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null
    Write-Log "Inicio do backup. Origem: $sourcePath"
    Write-Log "Destino do arquivo compactado: $zipPath"

    $robocopyArguments = @(
        $sourcePath,
        $stagingPath,
        '/E',
        '/COPY:DAT',
        '/DCOPY:DAT',
        '/R:2',
        '/W:5',
        '/XJ',
        '/FFT',
        '/NP',
        "/LOG+:$localLogPath"
    )

    & robocopy @robocopyArguments
    $robocopyExitCode = $LASTEXITCODE

    if ($robocopyExitCode -gt 7) {
        throw "Robocopy terminou com erro. Codigo: $robocopyExitCode"
    }

    Write-Log "Robocopy concluido. Codigo: $robocopyExitCode"
    Write-Log 'Compactando os arquivos.'
    Compress-Archive -Path (Join-Path $stagingPath '*') -DestinationPath $zipPath -CompressionLevel Optimal -Force
    Write-Log 'Compactacao concluida.'
}
catch {
    Write-Log "ERRO: $($_.Exception.Message)"
    exit 1
}
finally {
    $stopwatch.Stop()
    Write-Log "Data de inicio: $startTime"
    Write-Log "Data de termino: $(Get-Date)"
    Write-Log "Duracao total: $($stopwatch.Elapsed.ToString('hh\:mm\:ss\.fff'))"

    try {
        if (Test-Path -LiteralPath $backupRoot) {
            Copy-Item -LiteralPath $localLogPath -Destination $remoteLogPath -Force
            Write-Host "Log salvo em: $remoteLogPath"
        }
        else {
            Write-Host "Log local salvo em: $localLogPath"
        }
    }
    catch {
        Write-Host "Nao foi possivel copiar o log para o servidor. Log local: $localLogPath"
    }

    if (Test-Path -LiteralPath $stagingPath) {
        Remove-Item -LiteralPath $stagingPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
