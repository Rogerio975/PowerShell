$logPath = "C:\Temp\agendamento-log.txt"
"Script executado em: $(Get-Date)" | Out-File -FilePath $logPath -Append