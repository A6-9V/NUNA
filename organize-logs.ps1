# MetaTrader 5 Logs Organizer Script
# Automatically organizes log files into subdirectories based on date and type

# Default MT5 Logs Directory (can be overridden)
param(
    [string]$LogsDir = "."
)

Write-Host "Starting MT5 Logs Organization in: $LogsDir" -ForegroundColor Cyan

# Ensure we are in the right directory
Push-Location $LogsDir

# Define log categories based on filename patterns
$categories = @{
    "Expert" = "*Expert*"
    "Trade"  = "*Trade*"
    "System" = "202[0-9][0-9][0-9][0-9][0-9].log" # MT5 system logs usually look like YYYYMMDD.log
}

foreach ($category in $categories.Keys) {
    $pattern = $categories[$category]
    $files = Get-ChildItem -Path $pattern -File

    if ($files.Count -gt 0) {
        Write-Host "Processing $category logs..." -ForegroundColor Yellow

        # Create category directory
        if (-not (Test-Path $category)) {
            New-Item -ItemType Directory -Path $category | Out-Null
        }

        foreach ($file in $files) {
            # Extract date from filename or last write time
            # For system logs (YYYYMMDD.log), extract from name
            if ($category -eq "System") {
                $dateStr = $file.BaseName
                if ($dateStr -match "^\d{8}$") {
                    $year = $dateStr.Substring(0, 4)
                    $month = $dateStr.Substring(4, 2)
                } else {
                    $year = $file.LastWriteTime.ToString("yyyy")
                    $month = $file.LastWriteTime.ToString("MM")
                }
            } else {
                $year = $file.LastWriteTime.ToString("yyyy")
                $month = $file.LastWriteTime.ToString("MM")
            }

            # Create date-based subdirectories
            $destDir = Join-Path $category (Join-Path $year $month)
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }

            # Move file
            $destPath = Join-Path $destDir $file.Name
            if (-not (Test-Path $destPath)) {
                Move-Item -Path $file.FullName -Destination $destPath
                Write-Host "  Moved $($file.Name) to $destDir" -ForegroundColor Gray
            } else {
                Write-Host "  Skipped $($file.Name) (already exists in $destDir)" -ForegroundColor DarkGray
            }
        }
    }
}

Pop-Location
Write-Host "Logs organization completed successfully!" -ForegroundColor Green
