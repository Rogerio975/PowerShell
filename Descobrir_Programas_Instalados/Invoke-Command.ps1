$ComputerName = Read-Host "Digite o nome ou IP do computador"
$ProgramName = Read-Host "Digite o nome do programa que deseja procurar"

Invoke-Command -ComputerName $ComputerName -Credential (Get-Credential) -ScriptBlock {
    param ($ProgramName)

    $paths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    Get-ItemProperty $paths | 
    Where-Object { $_.DisplayName -and $_.DisplayName -like "*$ProgramName*" } | 
    Select-Object DisplayName, DisplayVersion, Publisher | 
    Sort-Object DisplayName
} -ArgumentList $ProgramName

Write-Host "Programas instalados no computador $ComputerName."
Write-Host "Script executado em $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')."