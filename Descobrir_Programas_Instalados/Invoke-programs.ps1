$ComputerName = Read-Host "Digite o nome ou IP do computador"
$ProgramName = Read-Host "Digite o nome do programa que deseja procurar"

$InstalledPrograms = Invoke-Command -ComputerName $ComputerName -Credential (Get-Credential) -ScriptBlock {
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

if ($InstalledPrograms) {
    Write-Host "O programa $ProgramName está instalado no computador $ComputerName." -ForegroundColor Green
} else {
    Write-Host "O programa '$ProgramName' não foi localizado em $ComputerName." -ForegroundColor Yellow
}

Write-Host "Script executado em $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')."