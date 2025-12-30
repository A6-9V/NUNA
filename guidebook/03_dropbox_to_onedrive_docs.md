# `dropbox_to_onedrive.py` Documentation

This document provides detailed documentation for the `dropbox_to_onedrive.py` script.

## Purpose

The `dropbox_to_onedrive.py` script is a tool for importing a shared folder from Dropbox into your OneDrive. It automates the process of:

1.  Downloading the Dropbox shared folder as a ZIP file.
2.  Extracting the ZIP file locally.
3.  Uploading the extracted files to a specified folder in your OneDrive.

## Setup

1.  **Register an application in the Azure Portal:**
    *   Go to the [Azure Portal](https://portal.azure.com/) and sign in with your Microsoft account.
    *   Go to **App registrations** and create a **New registration**.
    *   Give it a name (e.g., "Dropbox to OneDrive Importer").
    *   For **Supported account types**, choose the option that best suits you.
    *   In the app's **Authentication** settings, enable **Allow public client flows**.
    *   In the app's **API permissions**, add the following **Delegated permissions** for **Microsoft Graph**:
        *   `Files.ReadWrite.All`
        *   `User.Read`

2.  **Set the `ONEDRIVE_CLIENT_ID` environment variable:**
    *   Copy the **Application (client) ID** from your app registration.
    *   Set it as an environment variable:
        ```bash
        export ONEDRIVE_CLIENT_ID="YOUR_CLIENT_ID"
        ```

## Usage

**Basic usage:**

```bash
python3 dropbox_to_onedrive.py --dropbox-url "<DROPBOX_SHARED_FOLDER_URL>" --onedrive-folder "My Dropbox Import"
```

The first time you run the script, it will provide you with a device login code and a URL. Open the URL in your browser and enter the code to authorize the script to access your OneDrive.

**Arguments:**

*   `--dropbox-url <URL>`: **(Required)** The URL of the Dropbox shared folder.
*   `--onedrive-folder <NAME>`: The name of the destination folder in your OneDrive root (default: "Dropbox Import YYYYMMDD-HHMMSS").
*   `--client-id <ID>`: The Azure app client ID. This can also be set using the `ONEDRIVE_CLIENT_ID` environment variable.
*   `--tenant <TENANT>`: The tenant for login (default: "common").
*   `--token-cache <PATH>`: The path to the MSAL token cache file (default: ".onedrive_token_cache.json").
*   `--dry-run`: Perform a dry run without uploading any files.
*   `--chunk-mb <MB>`: The upload session chunk size in MB for large files (default: 10).
*   `--keep-zip`: Keep the downloaded ZIP file (`dropbox-download.zip`).
*   `--keep-extracted`: Keep the extracted files (`dropbox-extracted/`).
*   `--parallel <N>`: The number of parallel uploads to run (default: 1).
