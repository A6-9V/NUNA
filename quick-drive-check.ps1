# Quick Drive Space Check
$drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.Size -gt 0 }
$output = @()
$output += "========================================"
$output += "  All Drives - Disk Space Report"
$output += "========================================"
$output += ""

foreach ($drive in $drives) {
    $letter = $drive.DeviceID
    $name = if ($drive.VolumeName) { $drive.VolumeName } else { "(No Label)" }
    $total = [math]::Round($drive.Size / 1GB, 2)
    $free = [math]::Round($drive.FreeSpace / 1GB, 2)
    $used = [math]::Round(($drive.Size - $drive.FreeSpace) / 1GB, 2)
    $percent = [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 1)
    
    $output += "$letter - $name"
    $output += "  Total: $total GB"
    $output += "  Used:  $used GB"
    $output += "  Free:  $free GB ($percent%)"
    $output += ""
}

$output | Out-File -FilePath "drive-check-output.txt" -Encoding ASCII
$output | ForEach-Object { Write-Host $_ }

