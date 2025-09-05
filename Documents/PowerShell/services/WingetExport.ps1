# Winget Export Service
# Intelligent backup service for Windows Package Manager (winget) installations
# 
# SERVICE_NAME: WingetExport
# SERVICE_DESCRIPTION: Daily winget package export with smart change detection
# SERVICE_SCHEDULE: Daily
# SERVICE_TIME: 12:00PM
# SERVICE_PARAMETERS: -RunExport
# SERVICE_ENABLED: true
#
# Created: $(Get-Date)

param(
    [switch]$RunExport,  # When true, runs the export logic
    [switch]$Force,      # Forces export even if no changes detected
    [switch]$Setup       # Setup mode for initial configuration
)

# Configuration
$exportPath = "$env:USERPROFILE\winget.json"
$logPath = "$env:USERPROFILE\Documents\PowerShell\.logs\WingetExport.log"
$tempPath = "$env:TEMP\winget_temp.json"

# Logging function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $logPath -Value $logEntry
    Write-Host $logEntry
}

# Helper functions for winget export functionality
function Get-WingetPackageList {
    param([string]$JsonPath)
    
    if (-not (Test-Path $JsonPath)) {
        return @()
    }
    
    try {
        $jsonContent = Get-Content $JsonPath -Raw | ConvertFrom-Json
        if ($jsonContent.Sources -and $jsonContent.Sources[0].Packages) {
            return $jsonContent.Sources[0].Packages | Sort-Object Id
        }
        return @()
    }
    catch {
        Write-Log "Error reading JSON file: $_"
        return @()
    }
}

function Compare-PackageLists {
    param($List1, $List2)
    
    if ($List1.Count -ne $List2.Count) {
        return $false
    }
    
    for ($i = 0; $i -lt $List1.Count; $i++) {
        if ($List1[$i].Id -ne $List2[$i].Id) {
            return $false
        }
        if ($List1[$i].Version -ne $List2[$i].Version) {
            return $false
        }
    }
    
    return $true
}

# Export functionality
function Invoke-WingetExport {
    Write-Log "=== Winget Export Started ==="
    
    try {
        # Check if winget is available
        $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $wingetPath) {
            Write-Log "Winget is not installed or not in PATH"
            return $false
        }
        
        # Export current winget packages to temp file
        Write-Log "Exporting current winget packages..."
        $exportResult = winget export -o $tempPath 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Winget export failed: $exportResult"
            return $false
        }
        
        # Compare with existing export if it exists and Force is not specified
        if (-not $Force -and (Test-Path $exportPath)) {
            Write-Log "Comparing package lists..."
            $currentPackages = Get-WingetPackageList -JsonPath $exportPath
            $newPackages = Get-WingetPackageList -JsonPath $tempPath
            
            if (Compare-PackageLists -List1 $currentPackages -List2 $newPackages) {
                Write-Log "No changes detected in package list. Skipping export."
                Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                Write-Log "=== Winget Export Completed (No Changes) ==="
                return $true
            } else {
                Write-Log "Changes detected in package list. Updating export..."
            }
        } else {
            if ($Force) {
                Write-Log "Force flag specified. Updating export..."
            } else {
                Write-Log "No existing export found. Creating new export..."
            }
        }
        
        # Move temp file to final location
        Move-Item $tempPath $exportPath -Force
        Write-Log "Winget export updated successfully: $exportPath"
        
        # Log package count
        $packageCount = (Get-WingetPackageList -JsonPath $exportPath).Count
        Write-Log "Export contains $packageCount packages"
        
        return $true
        
    } catch {
        Write-Log "Error in export: $_"
        return $false
    } finally {
        # Clean up temp file if it still exists
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
    
    Write-Log "=== Winget Export Completed ==="
}

# Setup functionality
function Invoke-Setup {
    Write-Log "=== Winget Export Service Setup ==="
    
    # Check if export should run immediately
    $shouldRun = $false
    
    if (-not (Test-Path $exportPath)) {
        Write-Log "No existing export found. Should run immediately."
        $shouldRun = $true
    } else {
        $fileInfo = Get-Item $exportPath
        $lastModified = $fileInfo.LastWriteTime
        $now = Get-Date
        
        # If the file is older than 24 hours, we should run
        $hoursSinceLastExport = ($now - $lastModified).TotalHours
        
        Write-Log "Last export was $([math]::Round($hoursSinceLastExport, 1)) hours ago"
        
        if ($hoursSinceLastExport -ge 24) {
            Write-Log "Export is older than 24 hours. Should run immediately."
            $shouldRun = $true
        } elseif ($lastModified.Date -lt $now.Date -and $now.Hour -ge 12) {
            Write-Log "Haven't run today and it's past noon. Should run immediately."
            $shouldRun = $true
        } else {
            Write-Log "Export is recent enough. No immediate run needed."
        }
    }
    
    if ($shouldRun) {
        Write-Log "Running initial winget export..."
        Invoke-WingetExport
    }
    
    Write-Log "=== Winget Export Service Setup Complete ==="
}

# Main execution logic
if ($Setup) {
    Invoke-Setup
} elseif ($RunExport) {
    Invoke-WingetExport
} else {
    # Default behavior - run export (for when called by scheduled task)
    Invoke-WingetExport
}
