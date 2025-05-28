Import-Module ActiveDirectory

Get-ADComputer -Filter * | ForEach-Object {
    $computer = $_.Name
    try {
        $sessions = quser /server:$computer 2>$null
        if ($sessions -match "e144231") {
            Write-Output "Usuário e144231 está logado em: $computer"
        }
    } catch {
        # Computador pode estar offline ou inacessível
    }
}