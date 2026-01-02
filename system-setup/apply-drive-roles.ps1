# Apply Drive Roles and Permissions
# Sets up proper permissions for each drive based on their role

param(
    [switch]$DryRun
)

# Requires Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    exit 1
}

$ErrorActionPreference = "Continue"

function Set-DrivePermissions {
    param(
        [string]$DriveLetter,
        [string]$Role,
        [string]$Permission,
        [string]$Label
    )
    
    $drivePath = "$DriveLetter\"
    
    if (-not (Test-Path $drivePath)) {
        Write-Host "Drive $DriveLetter not found, skipping..." -ForegroundColor Yellow
        return
    }
    
    Write-Host "`nConfiguring $DriveLetter ($Role)..." -ForegroundColor Cyan
    
    # Set drive label
    try {
        if (-not $DryRun) {
            Set-Volume -DriveLetter $DriveLetter.Replace(":", "") -NewFileSystemLabel $Label -ErrorAction SilentlyContinue
            Write-Host "  ✓ Label set to: $Label" -ForegroundColor Green
        } else {
            Write-Host "  [DRY RUN] Would set label to: $Label" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ⚠ Could not set label: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Set permissions
    try {
        $acl = Get-Acl $drivePath
        
        # Remove existing permissions (optional - be careful!)
        # $acl.SetAccessRuleProtection($true, $false)
        
        # Add new permission
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $Permission,
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        
        if (-not $DryRun) {
            $acl.SetAccessRule($accessRule)
            Set-Acl $drivePath $acl
            Write-Host "  ✓ Permissions set: $Permission - FullControl" -ForegroundColor Green
        } else {
            Write-Host "  [DRY RUN] Would set permissions: $Permission - FullControl" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ✗ Failed to set permissions: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "=== Drive Role Configuration ===" -ForegroundColor Cyan
Write-Host "Dry Run Mode: $DryRun`n" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "White" })

# Drive Role Definitions
$driveRoles = @(
    @{
        Drive = "C:"
        Role = "OS & System"
        Permission = "BUILTIN\Administrators"
        Label = "OS"
        Description = "Windows, Programs, System Files - Admin Only"
    },
    @{
        Drive = "D:"
        Role = "Projects & Development"
        Permission = "BUILTIN\Users"
        Label = "PROJECTS"
        Description = "Code, Projects, Git Repos - User Full Control"
    },
    @{
        Drive = "F:"
        Role = "Code Workspace"
        Permission = "BUILTIN\Users"
        Label = "CODE"
        Description = "Active Development - User Full Control"
    },
    @{
        Drive = "G:"
        Role = "Domain Controller"
        Permission = "BUILTIN\Administrators"
        Label = "DOMAIN_CONTROLLER"
        Description = "System Management - Admin Full Control"
    },
    @{
        Drive = "I:"
        Role = "Backup & Storage"
        Permission = "BUILTIN\Users"
        Label = "BACKUP"
        Description = "Archives, Backups - User Read/Write"
    }
)

# Apply roles
foreach ($role in $driveRoles) {
    Set-DrivePermissions `
        -DriveLetter $role.Drive `
        -Role $role.Role `
        -Permission $role.Permission `
        -Label $role.Label
    
    Write-Host "  Purpose: $($role.Description)" -ForegroundColor Gray
}

Write-Host "`n=== Drive Role Configuration Complete ===" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`n⚠️ DRY RUN MODE - No changes were made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
}

