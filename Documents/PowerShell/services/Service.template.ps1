# Service Template
# Template for creating new PowerShell services
# 
# SERVICE_NAME: ServiceTemplate
# SERVICE_DESCRIPTION: Template for creating new services
# SERVICE_SCHEDULE: Daily
# SERVICE_TIME: 12:00PM
# SERVICE_PARAMETERS: -RunService
# SERVICE_ENABLED: false
#
# Created: $(Get-Date)

param(
    [switch]$RunService,  # When true, runs the main service logic
    [switch]$Setup,       # When true, runs setup/initialization logic
    [switch]$Force        # Force execution regardless of conditions
)

# Configuration - Customize these for your service
$serviceName = "ServiceTemplate"
$logPath = "$env:USERPROFILE\Documents\PowerShell\.logs\$serviceName.log"
$configPath = "$env:USERPROFILE\Documents\PowerShell\$serviceName.config"

# Logging function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $logPath -Value $logEntry
    Write-Host $logEntry
}

# Service setup logic
function Invoke-ServiceSetup {
    Write-Log "=== $serviceName Service Setup ==="
    
    # Add your setup logic here
    # Examples:
    # - Create necessary directories
    # - Initialize configuration files
    # - Check dependencies
    # - Run initial service execution if needed
    
    try {
        # Example: Create config file if it doesn't exist
        if (-not (Test-Path $configPath)) {
            @{
                LastRun = $null
                Enabled = $true
                Settings = @{
                    # Add your service settings here
                }
            } | ConvertTo-Json | Set-Content $configPath
            Write-Log "Created configuration file: $configPath"
        }
        
        # Example: Check if immediate run is needed
        $shouldRunNow = $false
        
        # Add your logic to determine if service should run immediately
        # Example: Check if never run before, or if it's been too long since last run
        
        if ($shouldRunNow) {
            Write-Log "Running service immediately..."
            Invoke-ServiceLogic
        } else {
            Write-Log "Service setup complete. Will run on schedule."
        }
        
    } catch {
        Write-Log "Error during service setup: $_"
        return $false
    }
    
    Write-Log "=== $serviceName Service Setup Complete ==="
    return $true
}

# Main service logic
function Invoke-ServiceLogic {
    Write-Log "=== $serviceName Service Started ==="
    
    try {
        # Add your main service logic here
        # Examples:
        # - Process files
        # - Backup data
        # - Clean up system
        # - Send notifications
        # - Update configurations
        
        # Example service logic:
        Write-Log "Performing service tasks..."
        
        # Your service implementation goes here
        # ...
        
        # Example: Update last run time
        if (Test-Path $configPath) {
            $config = Get-Content $configPath | ConvertFrom-Json
            $config.LastRun = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $config | ConvertTo-Json | Set-Content $configPath
        }
        
        Write-Log "Service tasks completed successfully"
        return $true
        
    } catch {
        Write-Log "Error in service execution: $_"
        return $false
    } finally {
        # Cleanup logic here if needed
    }
    
    Write-Log "=== $serviceName Service Complete ==="
}

# Helper functions for your service
function Test-ServiceDependencies {
    # Check if required tools, files, or services are available
    # Return $true if all dependencies are met, $false otherwise
    return $true
}

function Get-ServiceConfiguration {
    # Load and return service configuration
    if (Test-Path $configPath) {
        return Get-Content $configPath | ConvertFrom-Json
    }
    return $null
}

# Main execution logic
if ($Setup) {
    # Setup mode: Initialize service
    Invoke-ServiceSetup
} elseif ($RunService) {
    # Service mode: Run main service logic
    Invoke-ServiceLogic
} else {
    # Default behavior: Run service logic (for when called by scheduled task)
    Invoke-ServiceLogic
}
