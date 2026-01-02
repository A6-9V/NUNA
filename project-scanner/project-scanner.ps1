# Project Scanner Script
# Scans all local drives to discover development projects, applications, and scripts

param(
    [string]$ConfigPath = "scanner-config.json",
    [string]$OutputPath = "discovered-projects.json",
    [switch]$Verbose
)

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ConfigPath -or -not (Test-Path $ConfigPath)) {
    $ConfigPath = Join-Path $scriptDir "scanner-config.json"
}
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found: $ConfigPath"
    exit 1
}

# Load configuration
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Import logger module
$loggerPath = Join-Path $scriptDir "project-logger.ps1"
if (Test-Path $loggerPath) {
    . $loggerPath
    Initialize-Logger -LogName "project-scanner"
} else {
    function Write-Log { param($Message, $Level = "INFO") Write-Host "[$Level] $Message" }
}

Write-Log "Starting project discovery scan..." -Level "INFO"
Write-Log "Configuration loaded from: $ConfigPath" -Level "INFO"

# Get all local drives
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null -and $_.Free -ne $null }
Write-Log "Found $($drives.Count) local drive(s) to scan" -Level "INFO"

$discoveredProjects = @()
$script:scanCount = 0
$script:errorCount = 0

function Test-ExcludedPath {
    param([string]$Path)
    
    foreach ($excluded in $config.excludedDirectories) {
        if ($Path -like "*\$excluded" -or $Path -like "$excluded\*" -or $Path -eq $excluded) {
            return $true
        }
    }
    return $false
}

function Get-ProjectType {
    param([string]$Directory)
    
    foreach ($projectType in $config.projectTypePatterns.PSObject.Properties) {
        $typeName = $projectType.Name
        $markers = $projectType.Value.markers
        
        foreach ($marker in $markers) {
            # Handle wildcard patterns
            if ($marker -like "*.*") {
                $files = Get-ChildItem -Path $Directory -Filter $marker -File -ErrorAction SilentlyContinue
                if ($files) {
                    return $typeName
                }
            } else {
                $markerPath = Join-Path $Directory $marker
                if (Test-Path $markerPath) {
                    return $typeName
                }
            }
        }
    }
    
    return $null
}

function Get-FileListing {
    param(
        [string]$Directory,
        [int]$MaxDepth = 3,
        [int]$CurrentDepth = 0
    )
    
    if ($CurrentDepth -ge $MaxDepth) {
        return @()
    }
    
    $files = @()
    try {
        $items = Get-ChildItem -Path $Directory -File -ErrorAction SilentlyContinue | 
            Where-Object { -not $_.PSIsContainer -and $_.Length -lt ($config.scanSettings.maxFileSizeMB * 1MB) }
        
        foreach ($item in $items) {
            $files += @{
                Name = $item.Name
                Path = $item.FullName
                Size = $item.Length
                LastModified = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
    } catch {
        # Silently continue on access denied or other errors
    }
    
    return $files
}

function Scan-Directory {
    param(
        [string]$Path,
        [int]$MaxDepth = 5,
        [int]$CurrentDepth = 0
    )
    
    if ($CurrentDepth -ge $MaxDepth) {
        return
    }
    
    if (Test-ExcludedPath -Path $Path) {
        return
    }
    
    try {
        $script:scanCount++
        if ($script:scanCount % 100 -eq 0) {
            Write-Log "Scanned $script:scanCount directories..." -Level "DEBUG"
        }
        
        # Check for project markers
        $projectType = Get-ProjectType -Directory $Path
        
        if ($projectType) {
            Write-Log "Found $projectType project: $Path" -Level "SUCCESS"
            
            $fileListing = Get-FileListing -Directory $Path -MaxDepth 3
            $configData = $config.projectTypePatterns.$projectType
            
            $project = @{
                Path = $Path
                Type = $projectType
                DiscoveryTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                FileCount = $fileListing.Count
                Files = $fileListing
                ExecutionCommand = $configData.executionCommand
                FallbackCommand = $configData.fallbackCommand
                WorkingDirectory = $Path
            }
            
            $script:discoveredProjects += $project
        }
        
        # Check for scripts
        $scripts = Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue |
            Where-Object { $config.scriptExtensions -contains $_.Extension }
        
        foreach ($script in $scripts) {
            if (-not (Test-ExcludedPath -Path $script.FullName)) {
                Write-Log "Found script: $($script.FullName)" -Level "SUCCESS"
                
                $scriptProject = @{
                    Path = $script.DirectoryName
                    Type = "script"
                    ScriptFile = $script.FullName
                    ScriptExtension = $script.Extension
                    DiscoveryTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    FileCount = 1
                    Files = @(@{
                        Name = $script.Name
                        Path = $script.FullName
                        Size = $script.Length
                        LastModified = $script.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                    })
                    ExecutionCommand = "& `"$($script.FullName)`""
                    WorkingDirectory = $script.DirectoryName
                }
                
                $script:discoveredProjects += $scriptProject
            }
        }
        
        # Recursively scan subdirectories
        if ($CurrentDepth -lt ($MaxDepth - 1)) {
            $subdirs = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue
            
            foreach ($subdir in $subdirs) {
                if (-not (Test-ExcludedPath -Path $subdir.FullName)) {
                    Scan-Directory -Path $subdir.FullName -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                }
            }
        }
    } catch {
        $script:errorCount++
        if ($Verbose) {
            Write-Log "Error scanning $Path : $($_.Exception.Message)" -Level "ERROR"
        }
    }
}

function Scan-ApplicationPaths {
    param([string]$Drive)
    
    foreach ($appPath in $config.applicationPaths) {
        $fullPath = Join-Path $Drive $appPath
        
        # Handle wildcards in path
        if ($appPath -like "*\*") {
            $basePath = $appPath -replace '\\\*.*$', ''
            $pattern = $appPath -replace '^.*\\', ''
            $searchPath = Join-Path $Drive $basePath
            
            if (Test-Path $searchPath) {
                $matchingDirs = Get-ChildItem -Path $searchPath -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like $pattern }
                
                foreach ($dir in $matchingDirs) {
                    Scan-Directory -Path $dir.FullName -MaxDepth 2
                }
            }
        } else {
            if (Test-Path $fullPath) {
                Scan-Directory -Path $fullPath -MaxDepth 2
            }
        }
    }
}

# Main scanning loop
$startTime = Get-Date

foreach ($drive in $drives) {
    $drivePath = $drive.Root
    Write-Log "Scanning drive: $drivePath" -Level "INFO"
    
    try {
        # Scan root directory (limited depth)
        Scan-Directory -Path $drivePath -MaxDepth 1
        
        # Scan application paths
        Scan-ApplicationPaths -Drive $drivePath
        
        # Scan common project locations
        $commonPaths = @(
            "Users",
            "Projects",
            "Development",
            "Code",
            "Workspace",
            "Documents\Projects"
        )
        
        foreach ($commonPath in $commonPaths) {
            $fullPath = Join-Path $drivePath $commonPath
            if (Test-Path $fullPath) {
                Write-Log "Scanning common path: $fullPath" -Level "INFO"
                Scan-Directory -Path $fullPath -MaxDepth $config.scanSettings.maxDepth
            }
        }
    } catch {
        Write-Log "Error scanning drive $drivePath : $($_.Exception.Message)" -Level "ERROR"
        $script:errorCount++
    }
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Log "Scan completed in $([math]::Round($duration.TotalSeconds, 2)) seconds" -Level "INFO"
Write-Log "Total directories scanned: $script:scanCount" -Level "INFO"
Write-Log "Errors encountered: $script:errorCount" -Level "INFO"
Write-Log "Projects discovered: $($discoveredProjects.Count)" -Level "SUCCESS"

# Remove duplicates based on path and ensure it's an array
$uniqueProjects = $discoveredProjects | Sort-Object -Property Path -Unique
# Ensure it's always an array (PowerShell might convert single items to objects)
if ($uniqueProjects -isnot [Array]) {
    $uniqueProjects = @($uniqueProjects)
}
Write-Log "Unique projects: $($uniqueProjects.Count)" -Level "INFO"

# Export results
$outputPathFull = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path $scriptDir $OutputPath
}

$output = @{
    ScanTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ScanDuration = [math]::Round($duration.TotalSeconds, 2)
    DirectoriesScanned = $script:scanCount
    ErrorsEncountered = $script:errorCount
    ProjectsDiscovered = $uniqueProjects.Count
    Projects = @($uniqueProjects)  # Explicitly ensure array
}

$output | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPathFull
Write-Log "Results exported to: $outputPathFull" -Level "SUCCESS"

# Return discovered projects
return $uniqueProjects

