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
