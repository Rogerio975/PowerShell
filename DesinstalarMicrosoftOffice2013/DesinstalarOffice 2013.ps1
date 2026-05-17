# ============================================
# Desinstalação Remota do Microsoft Office 2013
# ============================================

Clear-Host

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " DESINSTALADOR REMOTO - OFFICE 2013" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Solicita nome ou IP do computador
$Computador = Read-Host "Digite o nome ou IP do computador"

# Solicita credenciais para conexão remota (ex: DOMINIO\\usuario)
$Cred = Get-Credential -Message "Digite as credenciais para conexão remota"

# Testa conectividade
Write-Host ""
Write-Host "Testando conexão com $Computador..." -ForegroundColor Yellow

if (Test-Connection -ComputerName $Computador -Count 2 -Quiet) {

    Write-Host "Computador online." -ForegroundColor Green
    Write-Host ""

    try {

        Write-Host "Procurando Microsoft Office 2013..." -ForegroundColor Yellow

        $Office = Get-WmiObject Win32_Product -ComputerName $Computador -Credential $Cred |
                  Where-Object {
                      $_.Name -like "*Office*2013*"
                  }

        if ($Office) {

            Write-Host ""
            Write-Host "Office encontrado:" -ForegroundColor Green

            $Office | ForEach-Object {
                Write-Host $_.Name -ForegroundColor Cyan
            }

            Write-Host ""

            $Confirmacao = Read-Host "Deseja desinstalar? (S/N)"

            if ($Confirmacao -eq "S") {

                foreach ($App in $Office) {

                    Write-Host ""
                    Write-Host "Desinstalando: $($App.Name)" -ForegroundColor Yellow

                    $Resultado = $App.Uninstall()

                    if ($Resultado.ReturnValue -eq 0) {

                        Write-Host "Desinstalação concluída com sucesso." -ForegroundColor Green

                    }
                    else {

                        Write-Host "Falha ao desinstalar. Código: $($Resultado.ReturnValue)" -ForegroundColor Red

                    }
                }

            }
            else {

                Write-Host "Operação cancelada." -ForegroundColor Yellow

            }

        }
        else {

            Write-Host "Microsoft Office 2013 não encontrado." -ForegroundColor Red

        }

    }
    catch {

        Write-Host ""
        Write-Host "Erro durante a operação:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

    }

}
else {

    Write-Host "Não foi possível conectar ao computador." -ForegroundColor Red

}

Write-Host ""
Pause