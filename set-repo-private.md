# Make Repository Private - Instructions

## Quick Method (GitHub Web Interface)

1. Go to your repository: https://github.com/A6-9V/my-drive-projects
2. Click on **Settings** (top right of repository page)
3. Scroll down to **Danger Zone** section
4. Click **Change visibility**
5. Select **Make private**
6. Type the repository name to confirm: `A6-9V/my-drive-projects`
7. Click **I understand, change repository visibility**

## Using GitHub CLI (Alternative)

If you have GitHub CLI installed:

```powershell
gh repo edit A6-9V/my-drive-projects --visibility private
```

## Using GitHub API (Programmatic)

You can use PowerShell to make the repository private via API:

```powershell
# Set your GitHub token
$token = "YOUR_GITHUB_TOKEN"
$headers = @{
    "Authorization" = "token $token"
    "Accept" = "application/vnd.github.v3+json"
}

# Make repository private
$body = @{
    private = $true
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.github.com/repos/A6-9V/my-drive-projects" `
    -Method PATCH `
    -Headers $headers `
    -Body $body
```

## Verify Repository is Private

After making it private:
1. Visit the repository URL in an incognito/private window
2. You should see "This repository is private"
3. Only you and collaborators can access it

## Notes

- Making a repository private is **irreversible** without admin access
- Private repositories are free for personal accounts
- All collaborators will retain access
- Public forks will remain public (they are separate repositories)

