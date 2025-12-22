# Setup GitHub Secrets for Repository
# This script automates the process of setting up GitHub secrets for OAuth credentials

param(
    [Parameter(Mandatory=$false)]
    [string]$Repository = "Mouy-leng/ZOLO-A6-9VxNUNA-",
    
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientSecret
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "GitHub Secrets Setup Automation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Function to check if GitHub CLI is installed
function Test-GitHubCLI {
    try {
        $ghVersion = gh --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] GitHub CLI is installed" -ForegroundColor Green
            Write-Host "     Version: $($ghVersion -split "`n" | Select-Object -First 1)" -ForegroundColor Gray
            return $true
        }
    }
    catch {
        Write-Host "[ERROR] GitHub CLI is not installed" -ForegroundColor Red
        Write-Host "        Please install from: https://cli.github.com/" -ForegroundColor Yellow
        return $false
    }
    return $false
}

# Function to check GitHub CLI authentication
function Test-GitHubAuth {
    Write-Host "`n[INFO] Checking GitHub CLI authentication..." -ForegroundColor Cyan
    
    try {
        $authStatus = gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] GitHub CLI is authenticated" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[WARNING] GitHub CLI is not authenticated" -ForegroundColor Yellow
            Write-Host "          Running authentication process..." -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "[WARNING] Unable to check authentication status" -ForegroundColor Yellow
        return $false
    }
}

# Function to authenticate with GitHub CLI
function Start-GitHubAuth {
    Write-Host "`n[INFO] Starting GitHub CLI authentication..." -ForegroundColor Cyan
    Write-Host "       Follow the prompts to authenticate via web browser" -ForegroundColor Yellow
    
    try {
        gh auth login
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Successfully authenticated with GitHub" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[ERROR] Authentication failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[ERROR] Failed to run authentication: $_" -ForegroundColor Red
        return $false
    }
}

# Function to set a GitHub secret
function Set-GitHubSecret {
    param(
        [string]$SecretName,
        [string]$SecretValue,
        [string]$Repo
    )
    
    Write-Host "`n[INFO] Setting secret: $SecretName" -ForegroundColor Cyan
    
    try {
        # Create a temporary secure file
        $tempFile = [System.IO.Path]::GetTempFileName()
        
        try {
            # Write secret to temp file with restricted permissions
            $SecretValue | Out-File -FilePath $tempFile -NoNewline -Encoding UTF8
            
            # Set file permissions to be readable only by current user (Windows)
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
                $acl = Get-Acl $tempFile
                $acl.SetAccessRuleProtection($true, $false)
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
                    "Read",
                    "Allow"
                )
                $acl.SetAccessRule($rule)
                Set-Acl $tempFile $acl
            }
            
            # Use gh secret set with file input
            $result = gh secret set $SecretName --repo $Repo --body "$(Get-Content $tempFile -Raw)" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Secret '$SecretName' set successfully for repository '$Repo'" -ForegroundColor Green
                return $true
            }
            else {
                Write-Host "[ERROR] Failed to set secret '$SecretName'" -ForegroundColor Red
                Write-Host "        Error: $result" -ForegroundColor Red
                return $false
            }
        }
        finally {
            # Clean up temp file
            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-Host "[ERROR] Exception while setting secret: $_" -ForegroundColor Red
        return $false
    }
}

# Function to verify secrets
function Test-GitHubSecrets {
    param([string]$Repo)
    
    Write-Host "`n[INFO] Verifying secrets..." -ForegroundColor Cyan
    
    try {
        $secrets = gh secret list --repo $Repo 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Secrets in repository '$Repo':" -ForegroundColor Green
            Write-Host $secrets -ForegroundColor Gray
            return $true
        }
        else {
            Write-Host "[WARNING] Unable to list secrets" -ForegroundColor Yellow
            Write-Host "          Error: $secrets" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "[WARNING] Exception while verifying secrets: $_" -ForegroundColor Yellow
        return $false
    }
}

# Function to display manual setup instructions
function Show-ManualInstructions {
    param(
        [string]$Repo,
        [string]$ClientId,
        [string]$ClientSecret
    )
    
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host "Manual Setup Instructions" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Yellow
    
    Write-Host "If automated setup fails, you can set secrets manually:" -ForegroundColor White
    Write-Host "`n1. Go to: https://github.com/$Repo" -ForegroundColor White
    Write-Host "2. Click on 'Settings' tab" -ForegroundColor White
    Write-Host "3. In the left sidebar, click 'Secrets and variables' → 'Actions'" -ForegroundColor White
    Write-Host "4. Click 'New repository secret'" -ForegroundColor White
    Write-Host "5. Add the first secret:" -ForegroundColor White
    Write-Host "   - Name: CLIENT_ID" -ForegroundColor Cyan
    Write-Host "   - Secret: [YOUR_CLIENT_ID]" -ForegroundColor Gray
    Write-Host "6. Click 'Add secret'" -ForegroundColor White
    Write-Host "7. Repeat for the second secret:" -ForegroundColor White
    Write-Host "   - Name: CLIENT_SECRET" -ForegroundColor Cyan
    Write-Host "   - Secret: [YOUR_CLIENT_SECRET]" -ForegroundColor Gray
    Write-Host "`nNote: Secret names cannot start with 'GITHUB_' prefix" -ForegroundColor Yellow
}

# Main execution
Write-Host "Target Repository: $Repository" -ForegroundColor White
Write-Host "Client ID: [REDACTED FOR SECURITY]" -ForegroundColor White
Write-Host "Client Secret: [REDACTED FOR SECURITY]`n" -ForegroundColor White

# Step 1: Check GitHub CLI installation
if (-not (Test-GitHubCLI)) {
    Show-ManualInstructions -Repo $Repository -ClientId $ClientId -ClientSecret $ClientSecret
    exit 1
}

# Step 2: Check authentication
if (-not (Test-GitHubAuth)) {
    # Attempt to authenticate
    if (-not (Start-GitHubAuth)) {
        Write-Host "`n[ERROR] Cannot proceed without authentication" -ForegroundColor Red
        Show-ManualInstructions -Repo $Repository -ClientId $ClientId -ClientSecret $ClientSecret
        exit 1
    }
}

# Step 3: Set secrets
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setting GitHub Secrets" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$clientIdSuccess = Set-GitHubSecret -SecretName "CLIENT_ID" -SecretValue $ClientId -Repo $Repository
$clientSecretSuccess = Set-GitHubSecret -SecretName "CLIENT_SECRET" -SecretValue $ClientSecret -Repo $Repository

# Step 4: Verify secrets
Test-GitHubSecrets -Repo $Repository

# Step 5: Display results
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Results" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($clientIdSuccess -and $clientSecretSuccess) {
    Write-Host "[SUCCESS] All secrets have been set successfully!" -ForegroundColor Green
    Write-Host "`nYou can now use these secrets in your GitHub Actions workflows:" -ForegroundColor White
    Write-Host @"

env:
  CLIENT_ID: `${{ secrets.CLIENT_ID }}
  CLIENT_SECRET: `${{ secrets.CLIENT_SECRET }}

Or directly in steps:
- name: Use OAuth credentials
  run: |
    echo "Client ID: `${{ secrets.CLIENT_ID }}"
    # Use the secrets in your scripts

"@ -ForegroundColor Gray
}
else {
    Write-Host "[WARNING] Some secrets may not have been set correctly" -ForegroundColor Yellow
    Show-ManualInstructions -Repo $Repository -ClientId $ClientId -ClientSecret $ClientSecret
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
