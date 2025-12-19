#Requires -Version 5.1
<#
.SYNOPSIS
    Run the NuNa "Task Manager" (support portal) in Docker, dark mode, with Disk 2/3 mounts.

.DESCRIPTION
    This starts a small web container (nginx) that serves the static site in `support-portal/`.
    It also optionally mounts your Disk 2 and Disk 3 drive roots into the container so the
    portal/container can access them (for future features, logs, exports, etc.).

    Notes:
    - This is intended for Windows + Docker Desktop (Linux containers).
    - The portal is already dark-themed; this script just runs the container.

.PARAMETER Port
    Host port to expose the portal on (default: 8080).

.PARAMETER Disk2
    One or more Windows paths for Disk 2 to mount (defaults to I:\, J:\, K:\ based on docs).

.PARAMETER Disk3
    One or more Windows paths for Disk 3 to mount (optional).

.PARAMETER ContainerName
    Docker container name (default: nuna-task-manager-dark).

.PARAMETER OpenBrowser
    Opens the portal URL after starting the container.

.EXAMPLE
    .\run-task-manager-docker-dark.ps1

.EXAMPLE
    .\run-task-manager-docker-dark.ps1 -Port 8090 -Disk2 "I:\" -Disk3 "L:\"
#>

[CmdletBinding()]
param(
    [int]$Port = 8080,
    [string[]]$Disk2 = @("I:\", "J:\", "K:\"),
    [string[]]$Disk3 = @(),
    [string]$ContainerName = "nuna-task-manager-dark",
    [switch]$OpenBrowser
)

function Write-Info([string]$Message) { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Err([string]$Message) { Write-Host "[ERROR] $Message" -ForegroundColor Red }

$ErrorActionPreference = "Stop"

try {
    Write-Info "Checking Docker..."
    $null = & docker version 2>$null
    Write-Ok "Docker is available."
} catch {
    Write-Err "Docker is not available. Install Docker Desktop and ensure 'docker' works in your terminal."
    exit 1
}

$repoRoot = $PSScriptRoot
$portalPath = Join-Path $repoRoot "support-portal"
if (-not (Test-Path $portalPath)) {
    Write-Err "Missing folder: $portalPath"
    exit 1
}

Write-Info "Preparing mounts..."
$mountArgs = @(
    "--mount", "type=bind,src=$portalPath,dst=/usr/share/nginx/html,readonly"
)

function Add-DiskMounts([string]$DiskLabel, [string[]]$Paths) {
    foreach ($p in $Paths) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        if (-not (Test-Path $p)) {
            Write-Warn "$DiskLabel path not found, skipping mount: $p"
            continue
        }

        # Create a stable container mountpoint name. Example: I:\ -> /mnt/disk2/i
        $drive = ($p.TrimEnd("\") -replace ":", "")
        if ([string]::IsNullOrWhiteSpace($drive)) { $drive = "unknown" }
        $drive = $drive.ToLowerInvariant()

        $dst = "/mnt/$($DiskLabel.ToLowerInvariant())/$drive"
        $mountArgs += @("--mount", "type=bind,src=$p,dst=$dst")
        Write-Ok "Will mount $p -> $dst"
    }
}

Add-DiskMounts -DiskLabel "disk2" -Paths $Disk2
Add-DiskMounts -DiskLabel "disk3" -Paths $Disk3

Write-Info "Removing existing container (if any): $ContainerName"
try { & docker rm -f $ContainerName 2>$null | Out-Null } catch { }

Write-Info "Starting portal container..."
$runArgs = @(
    "run", "-d",
    "--name", $ContainerName,
    "-p", "$Port`:80"
) + $mountArgs + @(
    "nginx:alpine"
)

& docker @runArgs | Out-Null
Write-Ok "Started: $ContainerName"

$url = "http://localhost:$Port/"
Write-Ok "Open: $url"

if ($OpenBrowser) {
    try {
        Start-Process $url | Out-Null
        Write-Ok "Browser opened."
    } catch {
        Write-Warn "Could not open browser automatically: $($_.Exception.Message)"
    }
}

