@echo off
REM Quick Setup for Disk Performance Monitor
REM Run this as Administrator to set up the monitor

echo ========================================
echo   Disk Performance Monitor Setup
echo ========================================
echo.
echo This will set up real-time disk monitoring
echo to ensure trading operations execute reliably.
echo.
echo Press any key to continue (or Ctrl+C to cancel)...
pause >nul

echo.
echo [1/2] Setting up scheduled task...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup-disk-performance-monitor.ps1"

echo.
echo [2/2] Verifying setup...
powershell.exe -ExecutionPolicy Bypass -Command "Get-ScheduledTask -TaskName 'TradingSystem\DiskPerformanceMonitor' | Format-List"

echo.
echo ========================================
echo   Setup Complete!
echo ========================================
echo.
echo The disk performance monitor is now running.
echo.
echo To view the log:
echo   Get-Content "%USERPROFILE%\OneDrive\disk-performance-monitor.log" -Wait -Tail 20
echo.
echo For more information, see:
echo   DISK-PERFORMANCE-MONITOR-GUIDE.md
echo.
pause





