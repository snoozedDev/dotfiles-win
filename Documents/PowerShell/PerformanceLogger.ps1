# Define log file path
$LogFilePath = "C:\Users\ale\Documents\PowerShell\.logs\perf_log.txt"

# Ensure the log directory exists
$LogDirectory = Split-Path -Parent $LogFilePath
if (-not (Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

while ($true) {
    "=== $(Get-Date) ===" | Out-File $LogFilePath -Append
    Write-Host "Starting performance logging... $(Get-Date)"
    "GPU Engine utilization: " | Out-File $LogFilePath -Append
    Get-Counter "\GPU Engine(*)\Utilization Percentage" | Select-Object -ExpandProperty CounterSamples | Out-File $LogFilePath -Append
    Write-Host "GPU Engine utilization logged"
    "GPU Adapter Memory usage: " | Out-File $LogFilePath -Append
    Get-Counter "\GPU Adapter Memory(*)\Dedicated Usage" | Out-File $LogFilePath -Append
    Write-Host "GPU Adapter Memory usage logged"
    "DWM process details: " | Out-File $LogFilePath -Append
    Get-Process dwm | Format-List * | Out-File $LogFilePath -Append
    Write-Host "DWM process details logged"
    "Top 10 CPU processes: " | Out-File $LogFilePath -Append
    Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 10 Name,CPU,PM | Out-File $LogFilePath -Append
    Write-Host "Top 10 CPU processes logged"
    Write-Host "Sleeping for 5 seconds..."
    Start-Sleep -Seconds 5
}
