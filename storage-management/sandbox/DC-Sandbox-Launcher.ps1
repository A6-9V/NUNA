# DC-Sandbox-Launcher.ps1 - Quick Launch Script for Sandbox Testing
# Created: November 7, 2025
# Purpose: Easy access to all sandbox testing tools

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('jupyter', 'demo', 'test', 'help', 'status')]
    [string]$Action = 'help'
)

$WorkingDir = "H:\My Drive\storage-management"

function Show-SandboxMenu {
    Write-Host @"
🏗️  DC SANDBOX TESTING ENVIRONMENT
========================================

Available Actions:

🚀 QUICK START:
   .\DC-Sandbox-Launcher.ps1 -Action demo     # Run full sandbox demo
   .\DC-Sandbox-Launcher.ps1 -Action jupyter  # Start Jupyter interface

🔧 TESTING OPTIONS:
   .\DC-Sandbox-Launcher.ps1 -Action test     # Component testing
   .\DC-Sandbox-Launcher.ps1 -Action status   # Check environment

📚 AVAILABLE FILES:
   ✅ DC-Sync-Sandbox.ps1           # Main sandbox script
   ✅ DC-Sandbox-Testing.ipynb      # Interactive Jupyter notebook
   ✅ DC-Sync-Jupyter-Guide.ipynb   # Production guide
   ✅ DC-Sync.ps1                   # Production script
   ✅ Transfer-Helper.ps1            # USB/Network transfer

🎯 SANDBOX BENEFITS:
   ✅ 100% Safe - No real changes made
   ✅ Shows exact commands that would run
   ✅ Tests error handling scenarios
   ✅ Realistic simulation of DC operations
   ✅ Detailed logging for review

🚨 SAFETY FIRST:
   Always test in sandbox before production!

"@ -ForegroundColor Cyan
}

function Start-SandboxDemo {
    Write-Host "🎭 Starting Sandbox Demo..." -ForegroundColor Green
    Set-Location $WorkingDir
    .\DC-Sync-Sandbox.ps1 -Mode Demo -ShowCommands
    
    Write-Host "`n📋 Demo completed! Check the results above." -ForegroundColor Yellow
    Write-Host "📝 Detailed log saved to: sandbox-log.txt" -ForegroundColor Cyan
}

function Start-SandboxJupyter {
    Write-Host "🚀 Starting Jupyter Notebook for Sandbox Testing..." -ForegroundColor Green
    Set-Location $WorkingDir
    
    # Check if Jupyter is available
    try {
        $null = Get-Command jupyter -ErrorAction Stop
        Write-Host "✅ Jupyter found" -ForegroundColor Green
    } catch {
        Write-Host "❌ Jupyter not found. Installing..." -ForegroundColor Red
        pip install jupyter
    }
    
    Write-Host "🌐 Starting Jupyter on port 8889..." -ForegroundColor Cyan
    Write-Host "📝 Open DC-Sandbox-Testing.ipynb to begin" -ForegroundColor Yellow
    Write-Host "🔗 Access at: http://localhost:8889" -ForegroundColor Cyan
    
    jupyter notebook --port=8889
}

function Start-ComponentTest {
    Write-Host "🧪 Running Component Tests..." -ForegroundColor Green
    Set-Location $WorkingDir
    .\DC-Sync-Sandbox.ps1 -Mode Test -ShowCommands
}

function Show-SandboxStatus {
    Write-Host "📊 Sandbox Environment Status" -ForegroundColor Green
    Set-Location $WorkingDir
    
    # Check files
    $files = @(
        "DC-Sync-Sandbox.ps1",
        "DC-Sandbox-Testing.ipynb", 
        "DC-Sync.ps1",
        "Transfer-Helper.ps1"
    )
    
    Write-Host "`n📁 Required Files:" -ForegroundColor Cyan
    foreach ($file in $files) {
        if (Test-Path $file) {
            $size = [math]::Round((Get-Item $file).Length / 1KB, 1)
            Write-Host "  ✅ $file ($size KB)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $file (Missing)" -ForegroundColor Red
        }
    }
    
    # Check log file
    if (Test-Path "sandbox-log.txt") {
        $logSize = [math]::Round((Get-Item "sandbox-log.txt").Length / 1KB, 1)
        $lastModified = (Get-Item "sandbox-log.txt").LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "`n📝 Log File:" -ForegroundColor Cyan
        Write-Host "  ✅ sandbox-log.txt ($logSize KB, modified: $lastModified)" -ForegroundColor Green
    } else {
        Write-Host "`n📝 Log File:" -ForegroundColor Cyan
        Write-Host "  ⚠️ No sandbox-log.txt (run demo first)" -ForegroundColor Yellow
    }
    
    # Test sandbox validation
    Write-Host "`n🔧 Environment Test:" -ForegroundColor Cyan
    .\DC-Sync-Sandbox.ps1 -Mode Validate
}

# Main execution
switch ($Action) {
    'demo' { Start-SandboxDemo }
    'jupyter' { Start-SandboxJupyter }
    'test' { Start-ComponentTest }
    'status' { Show-SandboxStatus }
    'help' { Show-SandboxMenu }
    default { Show-SandboxMenu }
}