$process = Get-Process -Name "code" | Select-Object * | Out-GridView
$process.Name
$process.Id
$process.StartTime
$process.CPU