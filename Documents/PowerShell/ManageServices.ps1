# Manual Service Management Script
# Simple interface for managing PowerShell services
# Created: $(Get-Date)

param(
    [switch]$Setup,      # Setup all services (install + initialize)
    [switch]$Install,    # Install services as scheduled tasks
    [switch]$Uninstall, # Remove all scheduled tasks
    [switch]$Status,     # Show service status
    [switch]$List,       # List all available services
    [switch]$Start,      # Start a service now
    [switch]$Help        # Show help
)

$ServiceManagerPath = "$PSScriptRoot\ServiceManager.ps1"
$LogPath = "$PSScriptRoot\.logs\ManageServices.log"

# Ensure logs directory exists
$logsDir = "$PSScriptRoot\.logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

# Logging function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $LogPath -Value $logEntry
    Write-Host $logEntry -ForegroundColor Cyan
}

function Show-Help {
    Write-Host @"

PowerShell Service Management

Usage:
    .\ManageServices.ps1 -<Action>

Actions:
    -Setup        Complete setup (install services + run initial setup)
    -Install      Install all services as Windows scheduled tasks
    -Uninstall    Remove all service scheduled tasks
    -Status       Show current status of all services
    -List         List all available services in the services/ folder
    -Start        Start all services manually (run once now)
    -Help         Show this help message

Examples:
    .\ManageServices.ps1 -Setup         # First time setup
    .\ManageServices.ps1 -Status        # Check what's running
    .\ManageServices.ps1 -List          # See available services
    .\ManageServices.ps1 -Start         # Run all services once now
    .\ManageServices.ps1 -Uninstall     # Remove all scheduled tasks

Advanced Usage (use ServiceManager.ps1 directly):
    .\ServiceManager.ps1 -Action install -ServiceName WingetExport
    .\ServiceManager.ps1 -Action start -ServiceName WingetExport

"@ -ForegroundColor Yellow
}

function Invoke-Setup {
    Write-Log "=== Services Setup Started ==="
    
    Write-Host "Setting up PowerShell services..." -ForegroundColor Green
    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "  1. Install all services as Windows scheduled tasks" -ForegroundColor White
    Write-Host "  2. Run initial setup for each service" -ForegroundColor White
    Write-Host "  3. Services will then run automatically on their schedules" -ForegroundColor White
    Write-Host ""
    
    # Install all services
    Write-Host "Installing services as scheduled tasks..." -ForegroundColor Green
    & $ServiceManagerPath -Action install -All
    
    # Run setup for services that support it
    $servicesPath = "$PSScriptRoot\services"
    if (Test-Path $servicesPath) {
        $serviceScripts = Get-ChildItem -Path $servicesPath -Filter "*.ps1" | Where-Object { $_.Name -notlike "*.template.ps1" }
        
        foreach ($script in $serviceScripts) {
            # Check if script supports setup mode
            $content = Get-Content $script.FullName -Raw
            if ($content -match 'param\s*\([^)]*\[switch\]\$Setup') {
                Write-Host "Running initial setup for $($script.BaseName)..." -ForegroundColor Green
                try {
                    & $script.FullName -Setup
                } catch {
                    Write-Log "Error running setup for $($script.BaseName): $_"
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "Setup complete! Services are now registered and will run on their schedules." -ForegroundColor Green
    Write-Host "Use 'ManageServices.ps1 -Status' to check service status." -ForegroundColor Yellow
    Write-Log "=== Services Setup Complete ==="
}

function Invoke-StartAll {
    Write-Log "=== Starting All Services ==="
    Write-Host "Starting all services manually..." -ForegroundColor Green
    
    # Get list of installed services and start them
    $services = & $ServiceManagerPath -Action list
    # This is a simple approach - in a real implementation you might want to parse the output
    # For now, we'll just run each service script directly
    
    $servicesPath = "$PSScriptRoot\services"
    if (Test-Path $servicesPath) {
        $serviceScripts = Get-ChildItem -Path $servicesPath -Filter "*.ps1" | Where-Object { $_.Name -notlike "*.template.ps1" }
        
        foreach ($script in $serviceScripts) {
            Write-Host "Starting $($script.BaseName)..." -ForegroundColor Green
            try {
                & $script.FullName -RunExport -Force  # Use -Force to ensure it runs
            } catch {
                Write-Log "Error starting $($script.BaseName): $_"
            }
        }
    }
    
    Write-Log "=== All Services Started ==="
}

# Main execution
try {
    if ($Help -or (-not ($Setup -or $Install -or $Uninstall -or $Status -or $List -or $Start))) {
        Show-Help
        exit 0
    }

    if ($Setup) {
        Invoke-Setup
    }
    elseif ($Install) {
        Write-Log "Installing services..."
        & $ServiceManagerPath -Action install -All
    }
    elseif ($Uninstall) {
        Write-Log "Uninstalling services..."
        & $ServiceManagerPath -Action uninstall -All
    }
    elseif ($Status) {
        Write-Host "Service Status:" -ForegroundColor Green
        & $ServiceManagerPath -Action status
    }
    elseif ($List) {
        Write-Host "Available Services:" -ForegroundColor Green
        & $ServiceManagerPath -Action list
    }
    elseif ($Start) {
        Invoke-StartAll
    }

} catch {
    Write-Log "Error in service management: $_"
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

