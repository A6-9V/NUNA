# Simple launcher that will show UAC prompt
$scriptPath = Join-Path $PSScriptRoot "setup-cloud-sync.ps1"
Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$scriptPath`""


