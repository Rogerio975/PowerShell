function Get-InstalledPrograms {
    param (
        [string]$ComputerName,
        [PSCredential]$Credential
    )

    try {
        # Estabelece uma sessão remota com o computador especificado
        $session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
        
        # Executa o comando para obter a lista de programas instalados
        $installedPrograms = Invoke-Command -Session $session -ScriptBlock {
            Get-WmiObject -Class Win32_Product | Select-Object -Property Name, Version
        }

        # Fecha a sessão remota
        Remove-PSSession -Session $session

        return $installedPrograms
    } catch {
        Write-Error "Erro ao conectar ao computador remoto: $_"
        return $null
    }
}

Export-ModuleMember -Function Get-InstalledPrograms