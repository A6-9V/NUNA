#Requires -Version 5.1
<#
.SYNOPSIS
    Convert Files to Google Documents Format
.DESCRIPTION
    Organizes files and prepares them for Google Docs conversion
    Note: Actual conversion to Google Docs requires Google Drive API or manual upload
#>

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Convert Files to Google Docs Format" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$workspaceRoot = "C:\Users\USER\OneDrive"
$googleDocsDir = Join-Path $workspaceRoot "Google-Documents"
$organizedDir = Join-Path $googleDocsDir "Organized"

# Create directories
if (-not (Test-Path $googleDocsDir)) {
    New-Item -ItemType Directory -Path $googleDocsDir -Force | Out-Null
}
if (-not (Test-Path $organizedDir)) {
    New-Item -ItemType Directory -Path $organizedDir -Force | Out-Null
}

# Create subdirectories for organization
$categories = @("Documents", "Spreadsheets", "Presentations", "PDFs", "Images", "Other")
foreach ($category in $categories) {
    $catPath = Join-Path $organizedDir $category
    if (-not (Test-Path $catPath)) {
        New-Item -ItemType Directory -Path $catPath -Force | Out-Null
    }
}

Write-Host "[1/4] Scanning for files to convert..." -ForegroundColor Yellow
$filesToConvert = @()

# Find common document files
$extensions = @("*.doc", "*.docx", "*.txt", "*.rtf", "*.odt", "*.pdf", "*.xls", "*.xlsx", "*.ppt", "*.pptx")
$searchPaths = @(
    $workspaceRoot,
    "$workspaceRoot\Documents",
    "$workspaceRoot\Document,sheed,PDF, PICTURE"
)

foreach ($searchPath in $searchPaths) {
    if (Test-Path $searchPath) {
        foreach ($ext in $extensions) {
            $files = Get-ChildItem -Path $searchPath -Filter $ext -Recurse -ErrorAction SilentlyContinue | Where-Object {-not $_.PSIsContainer}
            $filesToConvert += $files
        }
    }
}

Write-Host ("    [OK] Found " + $filesToConvert.Count + " file(s) to process") -ForegroundColor Green

Write-Host ""
Write-Host "[2/4] Organizing files by type..." -ForegroundColor Yellow
$organized = 0
foreach ($file in $filesToConvert) {
    $ext = $file.Extension.ToLower()
    $targetCategory = "Other"
    
    switch ($ext) {
        {$_ -in ".doc", ".docx", ".txt", ".rtf", ".odt"} { $targetCategory = "Documents" }
        {$_ -in ".xls", ".xlsx", ".csv"} { $targetCategory = "Spreadsheets" }
        {$_ -in ".ppt", ".pptx"} { $targetCategory = "Presentations" }
        {$_ -eq ".pdf"} { $targetCategory = "PDFs" }
        {$_ -in ".jpg", ".jpeg", ".png", ".gif", ".bmp"} { $targetCategory = "Images" }
    }
    
    $targetPath = Join-Path $organizedDir $targetCategory
    $targetFile = Join-Path $targetPath $file.Name
    
    try {
        Copy-Item $file.FullName $targetFile -Force -ErrorAction Stop
        $organized++
    } catch {
        Write-Host ("    [WARNING] Could not copy: " + $file.Name) -ForegroundColor Yellow
    }
}

Write-Host ("    [OK] Organized " + $organized + " file(s)") -ForegroundColor Green

Write-Host ""
Write-Host "[3/4] Creating conversion manifest..." -ForegroundColor Yellow
$manifest = @()
foreach ($category in $categories) {
    $catPath = Join-Path $organizedDir $category
    $files = Get-ChildItem -Path $catPath -File -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $manifest += [PSCustomObject]@{
            FileName = $file.Name
            Category = $category
            OriginalPath = $file.FullName
            Size = $file.Length
            LastModified = $file.LastWriteTime
        }
    }
}

$manifestFile = Join-Path $googleDocsDir "conversion-manifest.csv"
$manifest | Export-Csv -Path $manifestFile -NoTypeInformation -Encoding UTF8
Write-Host ("    [OK] Manifest created: " + $manifest.Count + " files") -ForegroundColor Green

Write-Host ""
Write-Host "[4/4] Creating Google Docs upload instructions..." -ForegroundColor Yellow
$instructions = @"
========================================
Google Docs Conversion Instructions
========================================

Files have been organized and are ready for Google Docs conversion.

LOCATION:
---------
Organized files: $organizedDir

CATEGORIES:
-----------
$(($categories | ForEach-Object { "  - $_" }) -join "`n")

CONVERSION METHODS:
------------------

Method 1: Google Drive Web Interface
1. Go to https://drive.google.com
2. Click 'New' > 'File upload'
3. Navigate to: $organizedDir
4. Select files or folders to upload
5. Right-click uploaded files > 'Open with' > 'Google Docs/Sheets/Slides'

Method 2: Google Drive Desktop App
1. Install Google Drive for Desktop
2. Copy files to Google Drive folder
3. Files will sync automatically
4. Open in Google Drive web interface
5. Convert to Google Docs format

Method 3: Google Docs API (Advanced)
- Requires Google Cloud project setup
- Use Google Drive API for automated conversion
- See: https://developers.google.com/drive/api

FILE TYPES:
-----------
- Documents (.doc, .docx, .txt) → Google Docs
- Spreadsheets (.xls, .xlsx) → Google Sheets
- Presentations (.ppt, .pptx) → Google Slides
- PDFs → Can be viewed in Google Drive
- Images → Can be stored in Google Drive

MANIFEST:
---------
Conversion manifest: $manifestFile
Total files: $($manifest.Count)

NEXT STEPS:
-----------
1. Review organized files in: $organizedDir
2. Upload to Google Drive using one of the methods above
3. Convert files to Google Docs format
4. Organize in Google Drive folders

========================================
"@

$instructionsFile = Join-Path $googleDocsDir "CONVERSION-INSTRUCTIONS.txt"
$instructions | Out-File -FilePath $instructionsFile -Encoding UTF8
Write-Host ("    [OK] Instructions created: $instructionsFile") -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Organization Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files organized in: $organizedDir" -ForegroundColor Green
Write-Host "Total files: $($manifest.Count)" -ForegroundColor Green
Write-Host "Manifest: $manifestFile" -ForegroundColor Green
Write-Host "Instructions: $instructionsFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Upload files to Google Drive and convert to Google Docs format" -ForegroundColor Yellow
Write-Host ""

