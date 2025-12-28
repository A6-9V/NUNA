# Google Drive cleanup (safe-by-default)

This repo contains a small tool to **audit** your Google Drive, find **duplicate binary files**, and (optionally) move *selected* files to **Trash** with strong safety checks.

## Safety model

- **Audit / duplicates** use **read-only** Drive scopes (`drive.metadata.readonly`).
- Nothing is ever permanently deleted.
- “Trash” requires:
  - a different OAuth scope (`drive`)
  - `--apply` (otherwise it’s a dry-run)
  - an **exact confirmation string** (`TRASH <n> FILES`)
  - an explicit list of file IDs you prepared yourself

## Setup

### 1) Create OAuth credentials

In Google Cloud Console:

- **APIs & Services → Library**: enable **Google Drive API**
- **APIs & Services → Credentials**: create **OAuth client ID**
  - Application type: **Desktop app**
  - Download JSON and save it as `./credentials.json` (repo root)

### 2) Install dependencies

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

## Usage

### Audit: find largest files (read-only)

```bash
python3 gdrive_cleanup.py audit --top 25 --show-links
```

Export a full CSV/JSON inventory:

```bash
python3 gdrive_cleanup.py audit --csv gdrive-report.csv --json gdrive-report.json
```

### Find duplicates (read-only)

This uses Drive’s `md5Checksum`, which typically exists for **uploaded binary files** (photos, videos, PDFs, zips, etc.). Many Google Docs formats won’t have an MD5.

```bash
python3 gdrive_cleanup.py duplicates --show 20 --show-per-group 10
```

It also writes a review file by default:

- `gdrive-plan-<timestamp>.json`

### Trash selected files (carefully)

1) Create a small JSON containing the IDs you want to trash:

```json
{
  "fileIds": [
    "FILE_ID_1",
    "FILE_ID_2"
  ]
}
```

2) Dry-run first (no changes):

```bash
python3 gdrive_cleanup.py trash --ids-json ids_to_trash.json --confirm "TRASH 2 FILES"
```

3) Apply (moves items to Trash):

```bash
python3 gdrive_cleanup.py trash --ids-json ids_to_trash.json --confirm "TRASH 2 FILES" --apply
```

## Optional filtering with Drive queries

All commands accept `--query`, which is passed to Drive’s `files.list(q=...)`. Examples:

- Only items in a folder:
  - `--query "'<FOLDER_ID>' in parents"`
- Only PDFs:
  - `--query "mimeType='application/pdf'"`
- Only large files (note: size is bytes):
  - `--query "size > 1073741824"`

## Notes / gotchas

- This tool includes “Shared drives” results as well (`supportsAllDrives=true`). If you don’t have permission to trash an item, it will fail and be reported.
- The token cache (`token.json`) and OAuth secrets (`credentials.json`) are ignored by git via `.gitignore`.

## Dropbox → OneDrive import

If you have a Dropbox shared-folder link and want it copied into your OneDrive, use `dropbox_to_onedrive.py`.

### OneDrive setup (Microsoft Graph)

1) In Azure Portal → **App registrations** → **New registration**
   - Supported account types: pick what matches you (or use “Accounts in any organizational directory and personal Microsoft accounts”)
2) In the app → **Authentication**
   - Enable **Allow public client flows** (device-code login)
3) In the app → **API permissions** → **Microsoft Graph** → **Delegated permissions**
   - Add: `Files.ReadWrite.All`
   - Add: `User.Read`

Then copy the **Application (client) ID** and set it as an environment variable:

```bash
export ONEDRIVE_CLIENT_ID="YOUR_CLIENT_ID"
```

### Run the import

Dry-run (no uploads, just shows what will be uploaded):

```bash
python3 dropbox_to_onedrive.py --dropbox-url "<DROPBOX_SHARED_FOLDER_URL>" --dry-run
```

Upload into a named folder in your OneDrive root:

```bash
python3 dropbox_to_onedrive.py --dropbox-url "<DROPBOX_SHARED_FOLDER_URL>" --onedrive-folder "Dropbox Import"
```

The script will print a **device login code** and URL the first time; complete that in your browser to authorize OneDrive access.

## Optional: run a Windows VM locally (Docker/KVM)

If you need a **real Windows environment** (for example, to use Windows-only tooling alongside this repo), you can run a local Windows VM using the upstream project `dockur/windows`:

- Repo: `https://github.com/dockur/windows`

Notes:

- This requires a **Linux host with hardware virtualization** enabled and access to **KVM** (`/dev/kvm`).
- Follow the upstream README for the current recommended `docker run` / compose configuration and Windows version/ISO options.
