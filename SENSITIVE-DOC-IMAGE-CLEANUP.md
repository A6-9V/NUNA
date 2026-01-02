# Sensitive document image cleanup (Dropbox / Google Drive)

This repo includes `cleanup-sensitive-doc-images.ps1` to help you **find and remove/quarantine** pictures of sensitive documents (ID cards, passports, credit/debit cards) that may be sitting inside **Dropbox** or **Google Drive** synced folders.

## What it does (safe defaults)

- **AUDIT mode (default)**: scans and creates a CSV report — **no changes**
- **APPLY mode (`-Apply`)**: moves flagged files into a **local quarantine folder** (outside cloud sync)

It **does not** OCR or read image contents; it flags files using **filename/path keywords** (fast, safer, but not perfect).

## How to run

### 1) Audit first (recommended)

```powershell
.\cleanup-sensitive-doc-images.ps1
```

It writes a report CSV into:
- `%USERPROFILE%\Documents\Sensitive-Cloud-Cleanup-Reports\`

### 2) Apply moves to quarantine (after reviewing report)

```powershell
.\cleanup-sensitive-doc-images.ps1 -Apply
```

Quarantine location:
- `%USERPROFILE%\Documents\Quarantine-Sensitive-CloudFiles\<timestamp>\`

### 3) Scan specific folders (if auto-detect misses yours)

```powershell
.\cleanup-sensitive-doc-images.ps1 -Targets @(
  "C:\Users\YOURNAME\Dropbox",
  "D:\Sync\Google Drive"
) -Apply
```

## Tips to reduce false positives

- Increase threshold:

```powershell
.\cleanup-sensitive-doc-images.ps1 -MinScore 5
```

## After you quarantine

- **Review** the quarantined files and delete anything you truly don’t want.
- If you need to keep a copy in the cloud, consider **redacting** the image first (blur/crop card numbers, MRZ, etc.) and re-upload only the redacted version.

