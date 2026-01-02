# Set Repositories to Private

Instructions for making the repositories private on GitHub.

## Repositories to Make Private

1. **I-bride_bridges3rd**: https://github.com/A6-9V/I-bride_bridges3rd.git
2. **my-drive-projects**: https://github.com/A6-9V/my-drive-projects.git

## Method 1: Using GitHub Web Interface

### For I-bride_bridges3rd Repository

1. Navigate to: https://github.com/A6-9V/I-bride_bridges3rd
2. Click on **Settings** (top right of the repository page)
3. Scroll down to the **Danger Zone** section
4. Click **Change visibility**
5. Select **Make private**
6. Type the repository name to confirm: `A6-9V/I-bride_bridges3rd`
7. Click **I understand, change repository visibility**

### For my-drive-projects Repository

1. Navigate to: https://github.com/A6-9V/my-drive-projects
2. Click on **Settings** (top right of the repository page)
3. Scroll down to the **Danger Zone** section
4. Click **Change visibility**
5. Select **Make private**
6. Type the repository name to confirm: `A6-9V/my-drive-projects`
7. Click **I understand, change repository visibility**

## Method 2: Using GitHub CLI

If you have GitHub CLI installed:

```powershell
# Authenticate with GitHub CLI
gh auth login

# Make I-bride_bridges3rd private
gh repo edit A6-9V/I-bride_bridges3rd --visibility private

# Make my-drive-projects private
gh repo edit A6-9V/my-drive-projects --visibility private
```

## Method 3: Using GitHub API

If you have a GitHub Personal Access Token:

```powershell
# Set your token
$token = "YOUR_GITHUB_TOKEN"
$headers = @{
    "Authorization" = "token $token"
    "Accept" = "application/vnd.github.v3+json"
}

# Make I-bride_bridges3rd private
$body = @{
    private = $true
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.github.com/repos/A6-9V/I-bride_bridges3rd" `
    -Method PATCH -Headers $headers -Body $body

# Make my-drive-projects private
Invoke-RestMethod -Uri "https://api.github.com/repos/A6-9V/my-drive-projects" `
    -Method PATCH -Headers $headers -Body $body
```

## Verification

After making repositories private, verify:

1. Visit the repository URL
2. You should see a "Private" badge
3. Only authorized users can access the repository

## Notes

- Making a repository private is **irreversible** without changing it back manually
- Private repositories may have different access controls
- Ensure you have proper access permissions before making private
- Collaborators need to be explicitly added to private repositories

## Access Control

After making repositories private:

1. Go to **Settings** > **Collaborators**
2. Add any users who need access
3. Set appropriate permission levels (Read, Write, or Admin)

---

**Created**: 2025-12-09  
**Repositories**: 
- https://github.com/A6-9V/I-bride_bridges3rd.git
- https://github.com/A6-9V/my-drive-projects.git
