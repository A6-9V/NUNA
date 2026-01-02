#Requires -Version 5.1
<#
.SYNOPSIS
    Verify Trading System Setup - Risk Management and EA Configuration
.DESCRIPTION
    Verifies that all Expert Advisors are properly configured with:
    - Risk management (stop loss, take profit, position sizing)
    - Proper compilation status
    - Trading system readiness
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Trading System Verification" -ForegroundColor Cyan
Write-Host "  Risk Management & EA Analysis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$expertsPath = "C:\Users\USER\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Experts\Advisors"

# Analysis Results
$analysisResults = @()
$riskManagementIssues = @()
$compilationIssues = @()

Write-Host "[1/4] Analyzing Expert Advisors..." -ForegroundColor Yellow

# Get all .mq5 files
$eaFiles = Get-ChildItem -Path $expertsPath -Filter "*.mq5" -ErrorAction SilentlyContinue

if ($null -eq $eaFiles -or $eaFiles.Count -eq 0) {
    Write-Host "[ERROR] No Expert Advisors found!" -ForegroundColor Red
    exit 1
}

foreach ($eaFile in $eaFiles) {
    $eaName = $eaFile.Name
    $content = Get-Content -Path $eaFile.FullName -Raw
    
    Write-Host "  Analyzing: $eaName..." -ForegroundColor Cyan
    
    # Check for risk management
    $hasRiskManagement = $false
    $riskType = "NONE"
    $hasStopLoss = $false
    $hasTakeProfit = $false
    
    # Check money management class
    if ($content -match "MoneyFixedRisk") {
        $hasRiskManagement = $true
        $riskType = "FixedRisk"
    } elseif ($content -match "MoneyFixedLot") {
        $hasRiskManagement = $true
        $riskType = "FixedLot"
    } elseif ($content -match "MoneySizeOptimized") {
        $hasRiskManagement = $true
        $riskType = "SizeOptimized"
    } elseif ($content -match "MoneyFixedMargin") {
        $hasRiskManagement = $true
        $riskType = "FixedMargin"
    } elseif ($content -match "MoneyNone") {
        $hasRiskManagement = $false
        $riskType = "NONE - CRITICAL RISK!"
    }
    
    # Check for Stop Loss
    if ($content -match "StopLoss|StopLevel|Stop") {
        $hasStopLoss = $true
    }
    
    # Check for Take Profit
    if ($content -match "TakeProfit|TakeLevel|TP") {
        $hasTakeProfit = $true
    }
    
    # Check compilation status
    $ex5Path = $eaFile.FullName -replace "\.mq5$", ".ex5"
    $isCompiled = Test-Path $ex5Path
    
    # Determine overall status
    $status = "OK"
    $issues = @()
    
    if (-not $hasRiskManagement) {
        $status = "CRITICAL"
        $issues += "No risk management (MoneyNone detected)"
        $riskManagementIssues += $eaName
    }
    
    if (-not $hasStopLoss) {
        $status = "WARNING"
        $issues += "No explicit stop loss configuration"
    }
    
    if (-not $hasTakeProfit) {
        $status = "WARNING"
        $issues += "No explicit take profit configuration"
    }
    
    if (-not $isCompiled) {
        $status = "ERROR"
        $issues += "Not compiled (.ex5 file missing)"
        $compilationIssues += $eaName
    }
    
    $analysisResults += @{
        Name = $eaName
        RiskManagement = $hasRiskManagement
        RiskType = $riskType
        HasStopLoss = $hasStopLoss
        HasTakeProfit = $hasTakeProfit
        IsCompiled = $isCompiled
        Status = $status
        Issues = $issues
    }
}

Write-Host ""
Write-Host "[2/4] Checking Enhanced EAs..." -ForegroundColor Yellow

$enhancedEAs = $analysisResults | Where-Object { $_.Name -like "*Enhanced*" }
$standardEAs = $analysisResults | Where-Object { $_.Name -notlike "*Enhanced*" }

Write-Host "  Enhanced EAs: $($enhancedEAs.Count)" -ForegroundColor Cyan
Write-Host "  Standard EAs: $($standardEAs.Count)" -ForegroundColor Cyan

Write-Host ""
Write-Host "[3/4] Risk Management Analysis..." -ForegroundColor Yellow

$safeEAs = $analysisResults | Where-Object { $_.RiskManagement -eq $true }
$unsafeEAs = $analysisResults | Where-Object { $_.RiskManagement -eq $false }

Write-Host "  EAs with Risk Management: $($safeEAs.Count)" -ForegroundColor $(if ($safeEAs.Count -gt 0) { "Green" } else { "Red" })
Write-Host "  EAs WITHOUT Risk Management: $($unsafeEAs.Count)" -ForegroundColor $(if ($unsafeEAs.Count -eq 0) { "Green" } else { "Red" })

if ($unsafeEAs.Count -gt 0) {
    Write-Host ""
    Write-Host "  [WARNING] EAs without risk management:" -ForegroundColor Yellow
    foreach ($ea in $unsafeEAs) {
        Write-Host "    - $($ea.Name) [CRITICAL RISK]" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[4/4] Compilation Status..." -ForegroundColor Yellow

$compiledEAs = $analysisResults | Where-Object { $_.IsCompiled -eq $true }
$uncompiledEAs = $analysisResults | Where-Object { $_.IsCompiled -eq $false }

Write-Host "  Compiled EAs: $($compiledEAs.Count)" -ForegroundColor $(if ($compiledEAs.Count -eq $analysisResults.Count) { "Green" } else { "Yellow" })
Write-Host "  Uncompiled EAs: $($uncompiledEAs.Count)" -ForegroundColor $(if ($uncompiledEAs.Count -eq 0) { "Green" } else { "Red" })

if ($uncompiledEAs.Count -gt 0) {
    Write-Host ""
    Write-Host "  [INFO] Uncompiled EAs:" -ForegroundColor Yellow
    foreach ($ea in $uncompiledEAs) {
        Write-Host "    - $($ea.Name)" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DETAILED ANALYSIS REPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($result in $analysisResults) {
    $statusColor = switch ($result.Status) {
        "OK" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "CRITICAL" { "Red" }
        default { "White" }
    }
    
    Write-Host "Expert: $($result.Name)" -ForegroundColor Cyan
    Write-Host "  Status: $($result.Status)" -ForegroundColor $statusColor
    Write-Host "  Risk Management: $($result.RiskType)" -ForegroundColor $(if ($result.RiskManagement) { "Green" } else { "Red" })
    Write-Host "  Stop Loss: $(if ($result.HasStopLoss) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($result.HasStopLoss) { "Green" } else { "Yellow" })
    Write-Host "  Take Profit: $(if ($result.HasTakeProfit) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($result.HasTakeProfit) { "Green" } else { "Yellow" })
    Write-Host "  Compiled: $(if ($result.IsCompiled) { 'Yes' } else { 'No' })" -ForegroundColor $(if ($result.IsCompiled) { "Green" } else { "Red" })
    
    if ($result.Issues.Count -gt 0) {
        Write-Host "  Issues:" -ForegroundColor Yellow
        foreach ($issue in $result.Issues) {
            Write-Host "    - $issue" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Final Recommendations
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$recommendations = @()

if ($unsafeEAs.Count -gt 0) {
    $recommendations += "CRITICAL: Use Enhanced EAs (ExpertMACD_Enhanced, ExpertMAMA_Enhanced, ExpertMAPSAR_Enhanced) which have proper risk management"
    $recommendations += "CRITICAL: Do NOT use EAs with MoneyNone - they have NO risk management"
}

if ($uncompiledEAs.Count -gt 0) {
    $recommendations += "Run compile-mql5-eas.ps1 to compile all Expert Advisors"
}

if ($safeEAs.Count -gt 0) {
    $recommendations += "RECOMMENDED: Use Enhanced EAs with FixedRisk set to 1% per trade for optimal risk management"
    $recommendations += "RECOMMENDED: Always set Stop Loss and Take Profit levels before trading"
}

if ($recommendations.Count -eq 0) {
    Write-Host "[OK] All systems ready for trading!" -ForegroundColor Green
    Write-Host "  - All EAs have risk management" -ForegroundColor Green
    Write-Host "  - All EAs are compiled" -ForegroundColor Green
    Write-Host "  - Trading system is ready" -ForegroundColor Green
} else {
    Write-Host "Recommendations:" -ForegroundColor Yellow
    foreach ($rec in $recommendations) {
        Write-Host "  - $rec" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VERIFICATION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Summary Statistics
$totalEAs = $analysisResults.Count
$readyEAs = ($analysisResults | Where-Object { $_.RiskManagement -eq $true -and $_.IsCompiled -eq $true }).Count
$winRatePotential = if ($readyEAs -gt 0) { "HIGH (with proper risk management)" } else { "LOW (no risk management)" }

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total EAs: $totalEAs" -ForegroundColor White
Write-Host "  Ready for Trading: $readyEAs" -ForegroundColor $(if ($readyEAs -eq $totalEAs) { "Green" } else { "Yellow" })
Write-Host "  Win Rate Potential: $winRatePotential" -ForegroundColor $(if ($readyEAs -gt 0) { "Green" } else { "Red" })
Write-Host ""
