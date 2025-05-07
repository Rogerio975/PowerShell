$computador = Read-Host "Digite o nome ou IP do computador"
Get-WmiObject -Class Win32_BaseBoard -ComputerName $computador | Select-Object Manufacturer, Product, SerialNumber