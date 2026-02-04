# OAuth Setup Guide for NUNA Tools

This guide will help you set up OAuth credentials for both Google Drive and OneDrive.

## Part 1: Google Drive OAuth Setup

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click on the project dropdown at the top
3. Click **"New Project"**
4. Enter project name: `NUNA Drive Cleanup` (or any name you prefer)
5. Click **"Create"**

### Step 2: Enable Google Drive API

1. In the Google Cloud Console, go to **"APIs & Services" → "Library"**
2. Search for **"Google Drive API"**
3. Click on it and click **"Enable"**

### Step 3: Create OAuth Credentials

1. Go to **"APIs & Services" → "Credentials"**
2. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
3. If prompted, configure the OAuth consent screen first:
   - User Type: **External** (unless you have a Google Workspace)
   - App name: `NUNA Drive Cleanup`
   - User support email: Your email
   - Developer contact: Your email
   - Click **"Save and Continue"**
   - Scopes: Click **"Add or Remove Scopes"**, search and add:
     - `https://www.googleapis.com/auth/drive.metadata.readonly`
     - `https://www.googleapis.com/auth/drive` (for trash functionality)
   - Click **"Save and Continue"**
   - Test users: Add your email address
   - Click **"Save and Continue"**
   - Click **"Back to Dashboard"**

4. Now create the OAuth client ID:
   - Application type: **Desktop app**
   - Name: `NUNA Drive Cleanup Client`
   - Click **"Create"**

5. Download the credentials:
   - Click the **download icon** (⬇️) next to your newly created OAuth client
   - Save the file as `credentials.json` in the `H:\Pictures\.Gallery2\recycle\bins` directory

### Step 4: Verify Setup

Run this command to test:
```bash
python gdrive_cleanup.py audit --top 5
```

The first time, it will open a browser for authentication and create `token.json`.

---

## Part 2: OneDrive OAuth Setup (Microsoft Graph)

### Step 1: Create Azure App Registration

1. Go to [Azure Portal](https://portal.azure.com/)
2. Search for **"Azure Active Directory"** or **"Microsoft Entra ID"**
3. Click **"App registrations"** in the left menu
4. Click **"+ New registration"**

### Step 2: Register the Application

1. **Name**: `NUNA OneDrive Import` (or any name)
2. **Supported account types**: 
   - Select **"Accounts in any organizational directory and personal Microsoft accounts"** (most common)
   - OR select what matches your needs
3. **Redirect URI**: Leave empty (we'll use device code flow)
4. Click **"Register"**

### Step 3: Configure Authentication

1. In your app, go to **"Authentication"** in the left menu
2. Under **"Advanced settings"**, find **"Allow public client flows"**
3. Set it to **"Yes"**
4. Click **"Save"**

### Step 4: Add API Permissions

1. Go to **"API permissions"** in the left menu
2. Click **"+ Add a permission"**
3. Select **"Microsoft Graph"**
4. Select **"Delegated permissions"**
5. Add these permissions:
   - `Files.ReadWrite.All` - Read and write all files
   - `User.Read` - Sign in and read user profile
6. Click **"Add permissions"**

**Note**: For personal Microsoft accounts, `Files.ReadWrite.All` should work without admin consent. For organizational accounts, you may need admin consent.

### Step 5: Get Client ID

1. In your app overview page, copy the **"Application (client) ID"**
2. It looks like: `12345678-1234-1234-1234-123456789abc`

### Step 6: Set Environment Variable

#### Windows PowerShell:
```powershell
$env:ONEDRIVE_CLIENT_ID = "YOUR_CLIENT_ID_HERE"
```

#### Windows Command Prompt:
```cmd
set ONEDRIVE_CLIENT_ID=YOUR_CLIENT_ID_HERE
```

#### Permanent (PowerShell - User level):
```powershell
[System.Environment]::SetEnvironmentVariable('ONEDRIVE_CLIENT_ID', 'YOUR_CLIENT_ID_HERE', 'User')
```

#### Permanent (Command Prompt):
```cmd
setx ONEDRIVE_CLIENT_ID "YOUR_CLIENT_ID_HERE"
```

**Note**: After setting permanently, restart your terminal/PowerShell.

### Step 7: Verify Setup

Run this command to test (dry-run):
```bash
python dropbox_to_onedrive.py --dropbox-url "YOUR_DROPBOX_URL" --dry-run
```

The first time, it will print a device code and URL. Open the URL in your browser and enter the code to authenticate.

---

## Quick Setup Scripts

I've created helper scripts to make this easier. See:
- `setup-google-oauth.ps1` - Interactive Google OAuth setup
- `setup-onedrive-oauth.ps1` - Interactive OneDrive OAuth setup

---

## Troubleshooting

### Google Drive Issues:
- **403 Error**: Make sure Google Drive API is enabled
- **Credentials not found**: Ensure `credentials.json` is in the `H:\Pictures\.Gallery2\recycle\bins` directory
- **Scope errors**: Check that you added the required scopes in OAuth consent screen

### OneDrive Issues:
- **Client ID not found**: Make sure environment variable is set correctly
- **Permission denied**: Check that `Files.ReadWrite.All` permission is added
- **Device code expired**: The code expires after 15 minutes, run the command again

---

## Security Notes

- **Never commit** `credentials.json` or `token.json` to version control
- These files are already in `.gitignore`
- Keep your OAuth credentials secure
- Revoke access if credentials are compromised
