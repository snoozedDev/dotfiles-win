# PowerShell Service Manager
# Centralized management for PowerShell-based services and scheduled tasks
# Created: $(Get-Date)

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("install", "uninstall", "start", "stop", "status", "list")]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [string]$ServiceName,
    
    [switch]$All
)

# Configuration
$ServicesPath = "$PSScriptRoot\services"
$LogPath = "$env:USERPROFILE\Documents\PowerShell\.logs\ServiceManager.log"
$ServicePrefix = "PSService_"

# Logging function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $LogPath -Value $logEntry
    Write-Host $logEntry
}

# Get service configuration from script metadata
function Get-ServiceConfig {
    param([string]$ScriptPath)
    
    if (-not (Test-Path $ScriptPath)) {
        return $null
    }
    
    $content = Get-Content $ScriptPath -Raw
    $config = @{
        Name = [System.IO.Path]::GetFileNameWithoutExtension($ScriptPath)
        Description = "PowerShell Service"
        Schedule = "Daily"
        Time = "12:00PM"
        Enabled = $true
        Parameters = ""
    }
    
    # Parse metadata from script comments
    if ($content -match '#\s*SERVICE_NAME:\s*(.+)') {
        $config.Name = $matches[1].Trim()
    }
    if ($content -match '#\s*SERVICE_DESCRIPTION:\s*(.+)') {
        $config.Description = $matches[1].Trim()
    }
    if ($content -match '#\s*SERVICE_SCHEDULE:\s*(.+)') {
        $config.Schedule = $matches[1].Trim()
    }
    if ($content -match '#\s*SERVICE_TIME:\s*(.+)') {
        $config.Time = $matches[1].Trim()
    }
    if ($content -match '#\s*SERVICE_PARAMETERS:\s*(.+)') {
        $config.Parameters = $matches[1].Trim()
    }
    if ($content -match '#\s*SERVICE_ENABLED:\s*(false|no|0)') {
        $config.Enabled = $false
    }
    
    return $config
}

# Get all service scripts
function Get-ServiceScripts {
    if (-not (Test-Path $ServicesPath)) {
        Write-Log "Services directory not found: $ServicesPath"
        return @()
    }
    
    return Get-ChildItem -Path $ServicesPath -Filter "*.ps1" | Where-Object { $_.Name -ne "*.template.ps1" }
}

# Install a service (create scheduled task)
function Install-PSService {
    param(
        [string]$ScriptPath,
        [hashtable]$Config
    )
    
    try {
        $taskName = "$ServicePrefix$($Config.Name)"
        
        # Remove existing task if it exists using schtasks
        Write-Log "Checking for existing task: $taskName"
        $result = schtasks /query /tn $taskName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Removing existing scheduled task: $taskName"
            schtasks /delete /tn $taskName /f | Out-Null
        }
        
        # Build the command to run
        $command = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`" $($Config.Parameters)"
        
        # Map schedule types to schtasks format
        $scheduleType = switch ($Config.Schedule.ToLower()) {
            "daily" { "daily" }
            "weekly" { "weekly" }
            "monthly" { "monthly" }
            "startup" { "onstart" }
            "logon" { "onlogon" }
            default { "daily" }
        }
        
        # Create the scheduled task using schtasks
        if ($scheduleType -eq "onstart" -or $scheduleType -eq "onlogon") {
            # For startup/logon tasks, no time needed
            $result = schtasks /create /tn $taskName /tr $command /sc $scheduleType /ru $env:USERNAME /f 2>&1
        } else {
            # For time-based tasks, include start time
            $result = schtasks /create /tn $taskName /tr $command /sc $scheduleType /st $Config.Time /ru $env:USERNAME /f 2>&1
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to install service '$($Config.Name)': $result"
            return $false
        }
        
        Write-Log "Service '$($Config.Name)' installed successfully as '$taskName'"
        return $true
        
    } catch {
        if ($_.Exception.Message -like "*Access is denied*") {
            Write-Log "Access denied installing service '$($Config.Name)'. Run as Administrator to create scheduled tasks."
            return $false
        } else {
            Write-Log "Error installing service '$($Config.Name)': $_"
            return $false
        }
    }
}

# Uninstall a service (remove scheduled task)
function Uninstall-PSService {
    param([string]$ServiceName)
    
    try {
        $taskName = "$ServicePrefix$ServiceName"
        
        # Check if task exists and remove it using schtasks
        $result = schtasks /query /tn $taskName 2>$null
        if ($LASTEXITCODE -eq 0) {
            $result = schtasks /delete /tn $taskName /f 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Service '$ServiceName' uninstalled successfully"
                return $true
            } else {
                Write-Log "Failed to uninstall service '$ServiceName': $result"
                return $false
            }
        } else {
            Write-Log "Service '$ServiceName' not found"
            return $false
        }
    } catch {
        Write-Log "Error uninstalling service '$ServiceName': $_"
        return $false
    }
}

# Start a service (run scheduled task now)
function Start-PSService {
    param([string]$ServiceName)
    
    try {
        $taskName = "$ServicePrefix$ServiceName"
        $result = schtasks /run /tn $taskName 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Service '$ServiceName' started"
            return $true
        } else {
            Write-Log "Error starting service '$ServiceName': $result"
            return $false
        }
    } catch {
        Write-Log "Error starting service '$ServiceName': $_"
        return $false
    }
}

# Stop a service (stop scheduled task if running)
function Stop-PSService {
    param([string]$ServiceName)
    
    try {
        $taskName = "$ServicePrefix$ServiceName"
        $result = schtasks /end /tn $taskName 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Service '$ServiceName' stopped"
            return $true
        } else {
            Write-Log "Error stopping service '$ServiceName': $result"
            return $false
        }
    } catch {
        Write-Log "Error stopping service '$ServiceName': $_"
        return $false
    }
}

# Get service status
function Get-PSServiceStatus {
    param([string]$ServiceName)
    
    try {
        $taskName = "$ServicePrefix$ServiceName"
        
        # Query task using schtasks with CSV output for easy parsing
        $result = schtasks /query /tn $taskName /fo csv /nh 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            # Parse CSV output
            # CSV format: TaskName,NextRunTime,Status
            $csvData = $result | ConvertFrom-Csv -Header @("TaskName", "NextRunTime", "Status")
            
            # Get more detailed info if needed
            $detailResult = schtasks /query /tn $taskName /v /fo csv /nh 2>$null
            $lastRunTime = "N/A"
            $lastResult = "N/A"
            
            if ($LASTEXITCODE -eq 0 -and $detailResult) {
                $detailData = $detailResult | ConvertFrom-Csv -Header @("HostName", "TaskName", "NextRunTime", "Status", "LogonMode", "LastRunTime", "LastResult", "Creator", "Schedule", "TaskToRun", "StartIn", "Comment", "ScheduledTaskState", "ScheduledType", "Modifier", "StartTime", "StartDate", "EndDate", "Days", "Months", "RunAsUser", "DeleteTaskIfNotRescheduled", "StopTaskIfRunsXHoursandXMins", "Repeat", "RepeatDuration", "RepeatStopIfStillRunning", "IdleStartTime", "IdleOnlyStartIfIdleForXMinutes", "IdleIfNotIdleRetryForXMinutes", "IdleStopTaskIfIdleStateEnd", "PowerMgmtNoStartOnBatteries", "PowerMgmtStopOnBatteryMode")
                $lastRunTime = $detailData.LastRunTime
                $lastResult = $detailData.LastResult
            }
            
            return @{
                Name = $ServiceName
                State = $csvData.Status
                LastRunTime = if ($lastRunTime -and $lastRunTime -ne "N/A") { $lastRunTime } else { $null }
                NextRunTime = if ($csvData.NextRunTime -and $csvData.NextRunTime -ne "N/A") { $csvData.NextRunTime } else { $null }
                LastTaskResult = $lastResult
                Installed = $true
            }
        } else {
            return @{
                Name = $ServiceName
                State = "NotInstalled"
                Installed = $false
            }
        }
    } catch {
        return @{
            Name = $ServiceName
            State = "Error"
            Error = $_.Exception.Message
            Installed = $false
        }
    }
}

# List all services
function Get-PSServiceList {
    $services = @()
    $scripts = Get-ServiceScripts
    
    foreach ($script in $scripts) {
        $config = Get-ServiceConfig -ScriptPath $script.FullName
        $status = Get-PSServiceStatus -ServiceName $config.Name
        
        $services += [PSCustomObject]@{
            Name = $config.Name
            ScriptFile = $script.Name
            Description = $config.Description
            Schedule = $config.Schedule
            Time = $config.Time
            Enabled = $config.Enabled
            State = $status.State
            LastRun = $status.LastRunTime
            NextRun = $status.NextRunTime
            Installed = $status.Installed
        }
    }
    
    return $services
}

# Main execution logic
Write-Log "=== PowerShell Service Manager Started ==="
Write-Log "Action: $Action, ServiceName: $ServiceName, All: $All"

try {
    switch ($Action.ToLower()) {
        "install" {
            if ($All) {
                $scripts = Get-ServiceScripts
                $successCount = 0
                
                foreach ($script in $scripts) {
                    $config = Get-ServiceConfig -ScriptPath $script.FullName
                    if ($config.Enabled) {
                        if (Install-PSService -ScriptPath $script.FullName -Config $config) {
                            $successCount++
                        }
                    } else {
                        Write-Log "Skipping disabled service: $($config.Name)"
                    }
                }
                
                Write-Log "Installed $successCount services"
            } elseif ($ServiceName) {
                $scriptPath = Join-Path $ServicesPath "$ServiceName.ps1"
                if (Test-Path $scriptPath) {
                    $config = Get-ServiceConfig -ScriptPath $scriptPath
                    Install-PSService -ScriptPath $scriptPath -Config $config | Out-Null
                } else {
                    Write-Log "Service script not found: $scriptPath"
                }
            } else {
                Write-Log "Please specify -ServiceName or use -All"
            }
        }
        
        "uninstall" {
            if ($All) {
                $services = Get-PSServiceList | Where-Object { $_.Installed }
                foreach ($service in $services) {
                    Uninstall-PSService -ServiceName $service.Name | Out-Null
                }
            } elseif ($ServiceName) {
                Uninstall-PSService -ServiceName $ServiceName | Out-Null
            } else {
                Write-Log "Please specify -ServiceName or use -All"
            }
        }
        
        "start" {
            if ($ServiceName) {
                Start-PSService -ServiceName $ServiceName | Out-Null
            } else {
                Write-Log "Please specify -ServiceName"
            }
        }
        
        "stop" {
            if ($ServiceName) {
                Stop-PSService -ServiceName $ServiceName | Out-Null
            } else {
                Write-Log "Please specify -ServiceName"
            }
        }
        
        "status" {
            if ($ServiceName) {
                $status = Get-PSServiceStatus -ServiceName $ServiceName
                Write-Host "`nService Status for '$ServiceName':"
                $status | Format-List
            } else {
                $services = Get-PSServiceList
                Write-Host "`nPowerShell Services Status:"
                $services | Format-Table -AutoSize Name, State, LastRun, NextRun, Schedule, Installed
            }
        }
        
        "list" {
            $services = Get-PSServiceList
            Write-Host "`nAvailable PowerShell Services:"
            $services | Format-Table -AutoSize Name, ScriptFile, Description, Schedule, Time, Enabled, Installed
        }
        
        default {
            Write-Log "Invalid action: $Action"
            Write-Host @"

PowerShell Service Manager Usage:

    .\ServiceManager.ps1 -Action <action> [-ServiceName <name>] [-All]

Actions:
    install     - Install service(s) as scheduled task(s)
    uninstall   - Remove scheduled task(s)
    start       - Start a service now
    stop        - Stop a running service
    status      - Show service status
    list        - List all available services

Examples:
    .\ServiceManager.ps1 -Action list
    .\ServiceManager.ps1 -Action install -All
    .\ServiceManager.ps1 -Action install -ServiceName WingetExport
    .\ServiceManager.ps1 -Action status -ServiceName WingetExport
    .\ServiceManager.ps1 -Action start -ServiceName WingetExport

"@
        }
    }
    
} catch {
    Write-Log "Error in service manager: $_"
    exit 1
}

Write-Log "=== PowerShell Service Manager Complete ==="
