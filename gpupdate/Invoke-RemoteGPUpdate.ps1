#Requires -Version 5.1
<#
.SYNOPSIS
    Executa "gpupdate /force" remotamente em computadores do Active Directory.

.DESCRIPTION
    Este script permite disparar a atualização de Group Policy (gpupdate /force)
    em uma lista de computadores, em uma OU específica do AD, ou em todos os
    computadores do domínio (com filtro opcional por último logon).

    Suporta dois métodos de execução:
      1) Invoke-GPUpdate  -> cmdlet nativo do módulo GroupPolicy (RSAT).
         Não exige PowerShell Remoting habilitado, apenas RPC/WMI e que o
         serviço "Group Policy Client" esteja acessível.
      2) Invoke-Command   -> fallback via WinRM, executando "gpupdate /force"
         diretamente na máquina remota. Exige PowerShell Remoting habilitado
         (Enable-PSRemoting) nos computadores de destino.

.PARAMETER ComputerName
    Lista explícita de nomes de computadores (hostname ou FQDN).

.PARAMETER SearchBase
    DN da OU do AD para buscar os computadores (ex: "OU=Financeiro,DC=empresa,DC=local").
    Requer o módulo ActiveDirectory (RSAT) instalado.

.PARAMETER Filter
    Filtro do Get-ADComputer quando -SearchBase é usado. Padrão: Enabled -eq $true

.PARAMETER Method
    "GPUpdateCmdlet" (padrão) ou "Remoting".

.PARAMETER Target
    "Computer" (padrão, aplica policy da máquina), "User" ou "Both".

.PARAMETER Credential
    Credencial opcional para autenticar nos computadores remotos.

.PARAMETER ThrottleLimit
    Número de execuções em paralelo. Padrão: 16.

.PARAMETER TimeoutSeconds
    Timeout (em segundos) por computador. Padrão: 120.

.PARAMETER LogPath
    Caminho do CSV de resultado. Padrão: .\GPUpdate_Resultado_<timestamp>.csv

.EXAMPLE
    .\Invoke-RemoteGPUpdate.ps1 -ComputerName PC01,PC02,PC03

.EXAMPLE
    # Domínio padrão é embasanet.ba.gov.br - basta informar a OU
    .\Invoke-RemoteGPUpdate.ps1 -SearchBase "OU=Financeiro" -Method Remoting -Credential (Get-Credential)

.EXAMPLE
    # Sem parâmetros: varre TODO o domínio embasanet.ba.gov.br
    .\Invoke-RemoteGPUpdate.ps1

.EXAMPLE
    .\Invoke-RemoteGPUpdate.ps1 -ComputerName (Get-Content .\lista.txt) -Target Both -ThrottleLimit 32
#>

[CmdletBinding(DefaultParameterSetName = 'ByOU')]
param(
    [Parameter(ParameterSetName = 'ByList', Mandatory = $true)]
    [string[]]$ComputerName,

    # Domínio padrão: embasanet.ba.gov.br
    # Passe apenas a OU (ex: "OU=Financeiro") que o domínio é anexado automaticamente,
    # ou passe o DN completo (ex: "OU=Financeiro,DC=embasanet,DC=ba,DC=gov,DC=br"),
    # ou deixe em branco para varrer o domínio inteiro.
    [Parameter(ParameterSetName = 'ByOU')]
    [string]$SearchBase = "DC=embasanet,DC=ba,DC=gov,DC=br",

    [Parameter(ParameterSetName = 'ByOU')]
    [string]$Filter = "Enabled -eq 'True'",

    [ValidateSet('GPUpdateCmdlet', 'Remoting')]
    [string]$Method = 'GPUpdateCmdlet',

    [ValidateSet('Computer', 'User', 'Both')]
    [string]$Target = 'Computer',

    [System.Management.Automation.PSCredential]$Credential,

    [int]$ThrottleLimit = 16,

    [int]$TimeoutSeconds = 120,

    [string]$LogPath = ".\GPUpdate_Resultado_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

# ---------------------------------------------------------------------------
# 1) Monta a lista de computadores
# ---------------------------------------------------------------------------
$DomainDN = "DC=embasanet,DC=ba,DC=gov,DC=br"

if ($PSCmdlet.ParameterSetName -eq 'ByOU') {
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Error "Módulo ActiveDirectory (RSAT) não encontrado. Instale o RSAT ou use -ComputerName."
        return
    }
    Import-Module ActiveDirectory -ErrorAction Stop

    # Se o usuário passou só a OU (ex: "OU=Financeiro"), anexa o domínio padrão.
    # Se já passou o DN completo (contém "DC="), usa como está.
    if ($SearchBase -notmatch 'DC=') {
        $SearchBase = "$SearchBase,$DomainDN"
    }

    Write-Host "Buscando computadores em '$SearchBase'..." -ForegroundColor Cyan
    $ComputerName = Get-ADComputer -Filter $Filter -SearchBase $SearchBase |
        Select-Object -ExpandProperty Name
}

if (-not $ComputerName -or $ComputerName.Count -eq 0) {
    Write-Warning "Nenhum computador para processar."
    return
}

Write-Host "Total de computadores: $($ComputerName.Count)" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 2) Verifica pré-requisitos do método escolhido
# ---------------------------------------------------------------------------
if ($Method -eq 'GPUpdateCmdlet' -and -not (Get-Command Invoke-GPUpdate -ErrorAction SilentlyContinue)) {
    Write-Warning "Cmdlet Invoke-GPUpdate não disponível (módulo GroupPolicy/RSAT ausente). Alternando para -Method Remoting."
    $Method = 'Remoting'
}

# ---------------------------------------------------------------------------
# 3) Função que roda em cada computador
# ---------------------------------------------------------------------------
$scriptBlock = {
    param($Comp, $Method, $Target, $TimeoutSeconds, $CredObj)

    $result = [PSCustomObject]@{
        ComputerName = $Comp
        Online       = $false
        Status       = ''
        Detalhe      = ''
        DataHora     = Get-Date
    }

    # Testa conectividade básica antes de tentar
    if (-not (Test-Connection -ComputerName $Comp -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        $result.Status  = 'Falha'
        $result.Detalhe = 'Computador offline ou inacessível (ping falhou).'
        return $result
    }
    $result.Online = $true

    try {
        if ($Method -eq 'GPUpdateCmdlet') {
            $gpParams = @{
                Computer            = $Comp
                Force               = $true
                RandomDelayInMinutes = 0
                Boolean             = $false
                Target              = $Target
            }
            Invoke-GPUpdate @gpParams -ErrorAction Stop
            $result.Status  = 'Sucesso'
            $result.Detalhe = "Comando enviado via Invoke-GPUpdate (Target=$Target)."
        }
        else {
            $icmParams = @{
                ComputerName = $Comp
                ScriptBlock  = { gpupdate /force /target:Computer }
                ErrorAction  = 'Stop'
            }
            if ($CredObj) { $icmParams['Credential'] = $CredObj }

            $output = Invoke-Command @icmParams
            $result.Status  = 'Sucesso'
            $result.Detalhe = ($output -join ' | ')
        }
    }
    catch {
        $result.Status  = 'Falha'
        $result.Detalhe = $_.Exception.Message
    }

    return $result
}

# ---------------------------------------------------------------------------
# 4) Execução em paralelo (PowerShell 7+ usa -Parallel; PS5.1 usa Jobs)
# ---------------------------------------------------------------------------
$results = New-Object System.Collections.Generic.List[object]

if ($PSVersionTable.PSVersion.Major -ge 7) {

    $results = $ComputerName | ForEach-Object -Parallel {
        $sb     = $using:scriptBlock
        $method = $using:Method
        $target = $using:Target
        $cred   = $using:Credential
        $to     = $using:TimeoutSeconds
        & $sb $_ $method $target $to $cred
    } -ThrottleLimit $ThrottleLimit

}
else {
    Write-Host "PowerShell 5.1 detectado — usando Jobs em background (Throttle=$ThrottleLimit)." -ForegroundColor Yellow

    $jobs = New-Object System.Collections.Generic.List[object]
    foreach ($comp in $ComputerName) {
        while ((Get-Job -State Running).Count -ge $ThrottleLimit) {
            Start-Sleep -Milliseconds 300
        }
        $jobs.Add((Start-Job -ScriptBlock $scriptBlock -ArgumentList $comp, $Method, $Target, $TimeoutSeconds, $Credential))
    }

    Write-Host "Aguardando conclusão de $($jobs.Count) tarefas..." -ForegroundColor Cyan
    $null = Wait-Job -Job $jobs -Timeout ($TimeoutSeconds + 30)

    foreach ($job in $jobs) {
        if ($job.State -eq 'Running') {
            Stop-Job -Job $job
            $results.Add([PSCustomObject]@{
                ComputerName = 'N/D'
                Online       = $false
                Status       = 'Timeout'
                Detalhe      = 'Excedeu o tempo limite.'
                DataHora     = Get-Date
            })
        }
        else {
            $out = Receive-Job -Job $job -ErrorAction SilentlyContinue
            if ($out) { $results.Add($out) }
        }
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# 5) Relatório final
# ---------------------------------------------------------------------------
$results = $results | Sort-Object ComputerName

$results | Format-Table ComputerName, Online, Status, Detalhe -AutoSize

$results | Export-Csv -Path $LogPath -NoTypeInformation -Encoding UTF8

$sucesso = ($results | Where-Object Status -eq 'Sucesso').Count
$falha   = ($results | Where-Object Status -ne 'Sucesso').Count

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host " Concluído: $sucesso sucesso(s) | $falha falha(s)"  -ForegroundColor Cyan
Write-Host " Log salvo em: $LogPath" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
