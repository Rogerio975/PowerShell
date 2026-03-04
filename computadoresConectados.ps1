1..254 | ForEach-Object {
    $ip = "10.19.1.$_"
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
        Write-Host "$ip está online" -ForegroundColor Green
    } else {
        # Opcional: mostrar quem está offline
        Write-Host "$ip está offline" -ForegroundColor Red
    }
}