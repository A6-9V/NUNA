---
description: "PowerShell script standards and best practices for Windows automation scripts"
alwaysApply: false
globs: ["*.ps1"]
---

# PowerShell Script Standards

When working with PowerShell scripts in this project, follow these standards:

## Code Style

- Use clear, descriptive variable names
- Add comments for complex logic
- Use `Write-Host` with `-ForegroundColor` for user feedback
- Prefer `-ErrorAction SilentlyContinue` for non-critical operations
- Use try-catch blocks for error handling

## Error Handling

- Always use try-catch blocks for operations that might fail
- Provide helpful error messages to users
- Skip gracefully if files/services are not found (don't fail completely)
- Use `Test-Path` before accessing files or directories

## Environment Variables

- Use `$env:VARIABLENAME` for standard environment variables
- For `ProgramFiles(x86)`, use: `(Get-Item "Env:ProgramFiles(x86)").Value` with try-catch
- Always handle cases where environment variables might not exist

## Output Formatting

- Use consistent status indicators: `[OK]`, `[INFO]`, `[WARNING]`, `[ERROR]`
- Use colored output for better readability:
  - Green: Success
  - Yellow: Information/Warnings
  - Red: Errors
  - Cyan: Headers/Sections
  - White: Regular text

## Script Structure

```powershell
# Script header with description
# Brief explanation of what the script does

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Script Title" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Main logic with error handling
try {
    # Operations
} catch {
    # Error handling
}

# Summary at end
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
```

## Best Practices

- Check if files exist before accessing them
- Use `Join-Path` for path construction
- Prefer relative paths or environment variables over hardcoded paths
- Add empty lines between logical sections
- Use `Start-Sleep` for user feedback delays (2 seconds typical)
