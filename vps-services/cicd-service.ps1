# CI/CD Automation Service
$ErrorActionPreference = "Continue"
$workspaceRoot = "C:\Users\USER\OneDrive"
$logsPath = "C:\Users\USER\OneDrive\vps-logs"

function Run-CICDPipeline {
    param([string]$repoPath, [string]$repoName)
    
    Set-Location $repoPath
    
    # Pull latest changes
    git pull origin main 2>&1 | Out-File -Append "$logsPath\cicd-service.log"
    
    # Check for Python projects and run them
    $pythonFiles = Get-ChildItem -Path $repoPath -Filter "*.py" -Recurse -ErrorAction SilentlyContinue
    if ($pythonFiles) {
        foreach ($pyFile in $pythonFiles) {
            Write-Host "[$(Get-Date)] Running: $($pyFile.Name)" | Out-File -Append "$logsPath\cicd-service.log"
            Start-Process python -ArgumentList $pyFile.FullName -WindowStyle Hidden
        }
    }
    
    # Check for requirements.txt and install dependencies
    $requirements = Get-ChildItem -Path $repoPath -Filter "requirements.txt" -Recurse -ErrorAction SilentlyContinue
    if ($requirements) {
        foreach ($req in $requirements) {
            pip install -r $req.FullName 2>&1 | Out-File -Append "$logsPath\cicd-service.log"
        }
    }
}

# Monitor repositories
$repos = @(
    @{Path="$workspaceRoot\ZOLO-A6-9VxNUNA"; Name="ZOLO-A6-9VxNUNA"},
    @{Path="$workspaceRoot\my-drive-projects"; Name="my-drive-projects"}
)

while ($true) {
    foreach ($repo in $repos) {
        if (Test-Path $repo.Path) {
            Run-CICDPipeline -RepoPath $repo.Path -RepoName $repo.Name
        }
    }
    Start-Sleep -Seconds 1800  # Run every 30 minutes
}
