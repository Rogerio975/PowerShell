# Get the free space of the C: drive in Gigabytes
$FreeSpaceGB = (Get-Volume -DriveLetter C).SizeRemaining / 1GB

# 1. Check if free space is less than 10 GB (Critical)
if ($FreeSpaceGB -lt 10) {
    Write-Warning "CRITICAL: Severe low disk space! Only $FreeSpaceGB GB left."
} 
# 2. Check if free space is between 10 GB and 50 GB (Warning)
elseif ($FreeSpaceGB -lt 50) {
    Write-Host "WARNING: Disk space is getting tight. $FreeSpaceGB GB left." -ForegroundColor Yellow
} 
# 3. If it's greater than 50 GB, everything is fine
else {
    Write-Host "SUCCESS: Disk space looks healthy! $FreeSpaceGB GB available." -ForegroundColor Green
}