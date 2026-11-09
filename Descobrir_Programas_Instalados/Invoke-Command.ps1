$ComputerName = Read-Host "Digite o nome ou IP do computador"

$programas = Invoke-Command -ComputerName $ComputerName -Credential (Get-Credential) -ScriptBlock {
    $paths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    Get-ItemProperty $paths |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName
}

Write-Host "Quantidade de programas instalados no computador ${ComputerName}: $($programas.Count)"
Write-Host "Script executado em $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')."