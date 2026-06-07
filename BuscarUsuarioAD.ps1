#Requires -Version 5.1
<#
.SYNOPSIS
    Busca de usuários no Active Directory via PowerShell.

.DESCRIPTION
    Permite buscar usuários pelo nome, login (sAMAccountName) ou e-mail.
    Funciona com o módulo ActiveDirectory (RSAT) ou via LDAP direto (fallback).

.PARAMETER Busca
    Termo de busca: nome, login ou e-mail (parcial ou completo).

.PARAMETER Login
    Busca exata pelo sAMAccountName.

.PARAMETER Servidor
    Domain Controller (padrão: detectado automaticamente).

.PARAMETER MaxResultados
    Número máximo de resultados (padrão: 20).

.EXAMPLE
    .\BuscarUsuarioAD.ps1
    .\BuscarUsuarioAD.ps1 -Busca "joao silva"
    .\BuscarUsuarioAD.ps1 -Login joao.silva
    .\BuscarUsuarioAD.ps1 -Busca "ti" -MaxResultados 50
#>

[CmdletBinding()]
param(
    [string]$Busca,
    [string]$Login,
    [string]$Servidor = "",
    [int]$MaxResultados = 20
)

# ─── Configuração de cores ─────────────────────────────────────────────────────
$Host.UI.RawUI.WindowTitle = "Busca Active Directory"

function Write-Banner {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║      🔍  Busca Active Directory  v2.0        ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Separador { Write-Host ("  " + "─" * 70) -ForegroundColor DarkGray }

function Write-Campo {
    param([string]$Label, [string]$Valor, [string]$Cor = "White")
    if ($Valor -and $Valor.Trim() -ne "") {
        Write-Host ("  {0,-18}: " -f $Label) -NoNewline -ForegroundColor DarkGray
        Write-Host $Valor -ForegroundColor $Cor
    }
}

# ─── Verifica disponibilidade do módulo AD ────────────────────────────────────
function Test-ModuloAD {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# ─── Busca via módulo ActiveDirectory (RSAT) ──────────────────────────────────
function Search-UsuarioComModulo {
    param([string]$Termo, [string]$SrvAD, [int]$Max)

    $filtro = "(&(objectClass=user)(objectCategory=person)" +
              "(|(sAMAccountName=*$Termo*)(cn=*$Termo*)(displayName=*$Termo*)" +
              "(mail=*$Termo*)(givenName=*$Termo*)(sn=*$Termo*)))"

    $propriedades = @(
        "sAMAccountName","DisplayName","GivenName","Surname","EmailAddress",
        "OfficePhone","MobilePhone","Department","Title","Company","Office",
        "Manager","MemberOf","Enabled","LastLogonDate","Created",
        "DistinguishedName","PasswordNeverExpires","LockedOut","whenCreated"
    )

    $params = @{
        LDAPFilter  = $filtro
        Properties  = $propriedades
        ResultSetSize = $Max
    }
    if ($SrvAD) { $params.Server = $SrvAD }

    try {
        return Get-ADUser @params
    } catch {
        Write-Host "  ✘ Erro na busca: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Find-LoginExatoComModulo {
    param([string]$LoginAD, [string]$SrvAD)

    $propriedades = @(
        "sAMAccountName","DisplayName","GivenName","Surname","EmailAddress",
        "OfficePhone","MobilePhone","Department","Title","Company","Office",
        "Manager","MemberOf","Enabled","LastLogonDate","Created",
        "DistinguishedName","PasswordNeverExpires","LockedOut","whenCreated"
    )

    $params = @{ Identity = $LoginAD; Properties = $propriedades }
    if ($SrvAD) { $params.Server = $SrvAD }

    try {
        return Get-ADUser @params
    } catch {
        return $null
    }
}

# ─── Busca via ADSI/LDAP (sem módulo RSAT — fallback) ────────────────────────
function Search-UsuarioComADSI {
    param([string]$Termo, [string]$SrvAD, [int]$Max)

    try {
        $raiz = if ($SrvAD) {
            [ADSI]"LDAP://$SrvAD"
        } else {
            [ADSI]"LDAP://RootDSE"
            $rootDSE = [ADSI]"LDAP://RootDSE"
            [ADSI]("LDAP://" + $rootDSE.defaultNamingContext)
        }

        $searcher = New-Object DirectoryServices.DirectorySearcher($raiz)
        $searcher.Filter = "(&(objectClass=user)(objectCategory=person)" +
                           "(|(sAMAccountName=*$Termo*)(cn=*$Termo*)(displayName=*$Termo*)" +
                           "(mail=*$Termo*)(givenName=*$Termo*)(sn=*$Termo*)))"
        $searcher.SizeLimit    = $Max
        $searcher.PageSize     = $Max
        $searcher.SearchScope  = "Subtree"

        @("sAMAccountName","cn","displayName","givenName","sn","mail",
          "telephoneNumber","mobile","department","title","company",
          "physicalDeliveryOfficeName","manager","memberOf",
          "userAccountControl","lastLogon","whenCreated","distinguishedName") |
            ForEach-Object { $searcher.PropertiesToLoad.Add($_) | Out-Null }

        $resultados = $searcher.FindAll()
        return $resultados
    } catch {
        Write-Host "  ✘ Erro ADSI: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# ─── Exibe lista resumida ─────────────────────────────────────────────────────
function Show-ListaUsuarios {
    param($Usuarios, [bool]$UsandoModulo)

    Write-Host ""
    Write-Host ("  {0,-20} {1,-32} {2,-28} {3}" -f "LOGIN","NOME","E-MAIL","STATUS") -ForegroundColor Yellow
    Write-Separador

    $i = 1
    foreach ($u in $Usuarios) {
        if ($UsandoModulo) {
            $login  = $u.SamAccountName
            $nome   = if ($u.DisplayName) { $u.DisplayName } else { $u.Name }
            $email  = $u.EmailAddress
            $status = if ($u.Enabled) { "✔ Ativo" } else { "✘ Inativo" }
            $cor    = if ($u.Enabled) { "Green" } else { "Red" }
        } else {
            $p      = $u.Properties
            $login  = $p["samaccountname"][0]
            $nome   = if ($p["displayname"].Count -gt 0) { $p["displayname"][0] } else { $p["cn"][0] }
            $email  = if ($p["mail"].Count -gt 0) { $p["mail"][0] } else { "" }
            $uac    = if ($p["useraccountcontrol"].Count -gt 0) { [int]$p["useraccountcontrol"][0] } else { 0 }
            $ativo  = ($uac -band 0x2) -eq 0
            $status = if ($ativo) { "✔ Ativo" } else { "✘ Inativo" }
            $cor    = if ($ativo) { "Green" } else { "Red" }
        }

        Write-Host ("  [{0,2}] " -f $i) -NoNewline -ForegroundColor DarkGray
        Write-Host ("{0,-20} {1,-32} {2,-28} " -f $login, $nome, $email) -NoNewline
        Write-Host $status -ForegroundColor $cor
        $i++
    }
}

# ─── Exibe detalhes de um usuário (módulo AD) ─────────────────────────────────
function Show-DetalheModulo {
    param($u)

    Write-Host ""
    Write-Separador
    Write-Host "  DETALHES DO USUÁRIO" -ForegroundColor Cyan
    Write-Separador

    Write-Campo "Login"          $u.SamAccountName          "Cyan"
    Write-Campo "Nome"           $u.DisplayName             "White"
    Write-Campo "Primeiro nome"  $u.GivenName
    Write-Campo "Sobrenome"      $u.Surname
    Write-Campo "E-mail"         $u.EmailAddress            "Yellow"
    Write-Campo "Telefone"       $u.OfficePhone
    Write-Campo "Celular"        $u.MobilePhone
    Write-Campo "Cargo"          $u.Title
    Write-Campo "Departamento"   $u.Department
    Write-Campo "Empresa"        $u.Company
    Write-Campo "Escritório"     $u.Office
    Write-Campo "Gerente"        (Split-CN $u.Manager)

    $statusCor  = if ($u.Enabled)   { "Green" } else { "Red" }
    $statusTxt  = if ($u.Enabled)   { "✔ Ativa" }  else { "✘ Desabilitada" }
    $lockedTxt  = if ($u.LockedOut) { " | 🔒 BLOQUEADA" } else { "" }
    $pwdTxt     = if ($u.PasswordNeverExpires) { " | Senha não expira" } else { "" }
    Write-Campo "Conta"         ($statusTxt + $lockedTxt + $pwdTxt)  $statusCor

    $ultimoLogon = if ($u.LastLogonDate) { $u.LastLogonDate.ToString("dd/MM/yyyy HH:mm") } else { "Nunca" }
    Write-Campo "Último logon"   $ultimoLogon
    $criado = if ($u.Created) { $u.Created.ToString("dd/MM/yyyy HH:mm") } else { "" }
    Write-Campo "Conta criada"   $criado

    # Grupos
    if ($u.MemberOf -and $u.MemberOf.Count -gt 0) {
        Write-Host ""
        Write-Host ("  Grupos ({0}):" -f $u.MemberOf.Count) -ForegroundColor DarkGray
        foreach ($g in ($u.MemberOf | Sort-Object)) {
            Write-Host "    • $(Split-CN $g)" -ForegroundColor DarkYellow
        }
    }

    Write-Host ""
    Write-Host "  DN: $($u.DistinguishedName)" -ForegroundColor DarkGray
    Write-Separador
}

# ─── Exibe detalhes de um usuário (ADSI) ─────────────────────────────────────
function Show-DetalheADSI {
    param($entry)

    $p = $entry.Properties
    Write-Host ""
    Write-Separador
    Write-Host "  DETALHES DO USUÁRIO" -ForegroundColor Cyan
    Write-Separador

    $login   = if ($p["samaccountname"].Count -gt 0) { $p["samaccountname"][0] } else { "" }
    $nome    = if ($p["displayname"].Count -gt 0)    { $p["displayname"][0] }    else { $p["cn"][0] }
    $email   = if ($p["mail"].Count -gt 0)           { $p["mail"][0] }           else { "" }
    $tel     = if ($p["telephonenumber"].Count -gt 0) { $p["telephonenumber"][0] } else { "" }
    $cel     = if ($p["mobile"].Count -gt 0)         { $p["mobile"][0] }         else { "" }
    $cargo   = if ($p["title"].Count -gt 0)          { $p["title"][0] }          else { "" }
    $depto   = if ($p["department"].Count -gt 0)     { $p["department"][0] }     else { "" }
    $empresa = if ($p["company"].Count -gt 0)        { $p["company"][0] }        else { "" }
    $office  = if ($p["physicaldeliveryofficename"].Count -gt 0) { $p["physicaldeliveryofficename"][0] } else { "" }
    $gerente = if ($p["manager"].Count -gt 0)        { Split-CN $p["manager"][0] } else { "" }
    $dn      = if ($p["distinguishedname"].Count -gt 0) { $p["distinguishedname"][0] } else { "" }

    $uac   = if ($p["useraccountcontrol"].Count -gt 0) { [int]$p["useraccountcontrol"][0] } else { 0 }
    $ativo = ($uac -band 0x2) -eq 0
    $statusTxt = if ($ativo) { "✔ Ativa" } else { "✘ Desabilitada" }
    $statusCor = if ($ativo) { "Green" }   else { "Red" }

    # Último logon — timestamp Windows (100ns desde 01/01/1601)
    $ultimoLogon = "Nunca"
    if ($p["lastlogon"].Count -gt 0) {
        $ts = [long]$p["lastlogon"][0]
        if ($ts -gt 0) {
            $ultimoLogon = [DateTime]::FromFileTime($ts).ToString("dd/MM/yyyy HH:mm")
        }
    }

    # Data de criação
    $criado = ""
    if ($p["whencreated"].Count -gt 0) {
        $raw = $p["whencreated"][0].ToString()
        if ($raw.Length -ge 8) {
            $criado = "$($raw.Substring(6,2))/$($raw.Substring(4,2))/$($raw.Substring(0,4))"
        }
    }

    Write-Campo "Login"         $login          "Cyan"
    Write-Campo "Nome"          $nome           "White"
    Write-Campo "E-mail"        $email          "Yellow"
    Write-Campo "Telefone"      $tel
    Write-Campo "Celular"       $cel
    Write-Campo "Cargo"         $cargo
    Write-Campo "Departamento"  $depto
    Write-Campo "Empresa"       $empresa
    Write-Campo "Escritório"    $office
    Write-Campo "Gerente"       $gerente
    Write-Campo "Conta"         $statusTxt      $statusCor
    Write-Campo "Último logon"  $ultimoLogon
    Write-Campo "Conta criada"  $criado

    # Grupos
    if ($p["memberof"].Count -gt 0) {
        Write-Host ""
        Write-Host ("  Grupos ({0}):" -f $p["memberof"].Count) -ForegroundColor DarkGray
        foreach ($g in ($p["memberof"] | Sort-Object)) {
            Write-Host "    • $(Split-CN $g)" -ForegroundColor DarkYellow
        }
    }

    Write-Host ""
    Write-Host "  DN: $dn" -ForegroundColor DarkGray
    Write-Separador
}

# ─── Extrai o CN de um Distinguished Name ────────────────────────────────────
function Split-CN {
    param([string]$DN)
    if (-not $DN) { return "" }
    $rdn = ($DN -split ",")[0]
    if ($rdn -match "^[^=]+=(.+)$") { return $Matches[1].Trim() }
    return $DN
}

# ─── Fluxo principal de busca e exibição ─────────────────────────────────────
function Invoke-Busca {
    param([string]$Termo)

    Write-Host ""
    Write-Host "  Buscando por: " -NoNewline -ForegroundColor DarkGray
    Write-Host "`"$Termo`"" -NoNewline -ForegroundColor Cyan
    Write-Host " (máx. $MaxResultados resultados)..." -ForegroundColor DarkGray

    if ($script:UsandoModulo) {
        $usuarios = @(Search-UsuarioComModulo -Termo $Termo -SrvAD $Servidor -Max $MaxResultados)
        $total = $usuarios.Count

        if ($total -eq 0) {
            Write-Host "  Nenhum usuário encontrado." -ForegroundColor Yellow
            return
        }

        Write-Host "  $total resultado(s) encontrado(s)." -ForegroundColor Green
        Show-ListaUsuarios -Usuarios $usuarios -UsandoModulo $true

        if ($total -eq 1) {
            Write-Host ""
            Show-DetalheModulo $usuarios[0]
        } else {
            Write-Host ""
            Write-Host "  Ver detalhes? Digite o número ou Enter para continuar: " -NoNewline -ForegroundColor DarkGray
            $escolha = Read-Host
            if ($escolha -match "^\d+$") {
                $idx = [int]$escolha - 1
                if ($idx -ge 0 -and $idx -lt $total) {
                    Show-DetalheModulo $usuarios[$idx]
                } else {
                    Write-Host "  Número fora do intervalo." -ForegroundColor Yellow
                }
            }
        }

    } else {
        $resultados = @(Search-UsuarioComADSI -Termo $Termo -SrvAD $Servidor -Max $MaxResultados)
        $total = $resultados.Count

        if ($total -eq 0) {
            Write-Host "  Nenhum usuário encontrado." -ForegroundColor Yellow
            return
        }

        Write-Host "  $total resultado(s) encontrado(s)." -ForegroundColor Green
        Show-ListaUsuarios -Usuarios $resultados -UsandoModulo $false

        if ($total -eq 1) {
            Write-Host ""
            Show-DetalheADSI $resultados[0]
        } else {
            Write-Host ""
            Write-Host "  Ver detalhes? Digite o número ou Enter para continuar: " -NoNewline -ForegroundColor DarkGray
            $escolha = Read-Host
            if ($escolha -match "^\d+$") {
                $idx = [int]$escolha - 1
                if ($idx -ge 0 -and $idx -lt $total) {
                    Show-DetalheADSI $resultados[$idx]
                } else {
                    Write-Host "  Número fora do intervalo." -ForegroundColor Yellow
                }
            }
        }
        $resultados.Dispose()
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
#  INÍCIO DO SCRIPT
# ═══════════════════════════════════════════════════════════════════════════════
Write-Banner

# Detecta qual método de busca usar
$script:UsandoModulo = Test-ModuloAD
if ($script:UsandoModulo) {
    Write-Host "  ✔ Módulo ActiveDirectory (RSAT) detectado." -ForegroundColor Green
} else {
    Write-Host "  ⚠ Módulo RSAT não encontrado — usando ADSI/LDAP nativo." -ForegroundColor Yellow
}

if ($Servidor) {
    Write-Host "  Servidor: $Servidor" -ForegroundColor DarkGray
} else {
    Write-Host "  Servidor: detectado automaticamente (domínio atual)" -ForegroundColor DarkGray
}

# ── Busca por Login exato (parâmetro -Login) ───────────────────────────────────
if ($Login) {
    Write-Host ""
    Write-Host "  Busca por login exato: " -NoNewline -ForegroundColor DarkGray
    Write-Host $Login -ForegroundColor Cyan

    if ($script:UsandoModulo) {
        $u = Find-LoginExatoComModulo -LoginAD $Login -SrvAD $Servidor
        if ($u) { Show-DetalheModulo $u }
        else     { Write-Host "  Nenhum usuário encontrado com login: $Login" -ForegroundColor Yellow }
    } else {
        $resultados = @(Search-UsuarioComADSI -Termo $Login -SrvAD $Servidor -Max 1)
        if ($resultados.Count -gt 0) { Show-DetalheADSI $resultados[0]; $resultados.Dispose() }
        else { Write-Host "  Nenhum usuário encontrado com login: $Login" -ForegroundColor Yellow }
    }
    exit 0
}

# ── Busca direta via parâmetro -Busca ─────────────────────────────────────────
if ($Busca) {
    Invoke-Busca -Termo $Busca
    exit 0
}

# ── Modo interativo ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  COMO USAR:" -ForegroundColor Yellow
Write-Host "    • Digite parte do nome  → ex.: joao, silva"
Write-Host "    • Digite o login        → ex.: joao.silva"
Write-Host "    • Digite o e-mail       → ex.: joao@empresa.com"
Write-Host "    • Digite 'sair'         → encerra o programa"
Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor DarkGray

while ($true) {
    Write-Host ""
    Write-Host "  🔍  Busca: " -NoNewline -ForegroundColor Cyan
    $entrada = Read-Host

    if (-not $entrada.Trim()) { continue }

    if ($entrada.Trim() -in @("sair","exit","quit","q")) {
        Write-Host ""
        Write-Host "  Encerrando. Até logo!" -ForegroundColor Cyan
        Write-Host ""
        break
    }

    Invoke-Busca -Termo $entrada.Trim()
}
