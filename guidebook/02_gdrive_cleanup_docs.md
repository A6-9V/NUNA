# `gdrive_cleanup.py` Documentation

This document provides detailed documentation for the `gdrive_cleanup.py`
script.

## Purpose

The `gdrive_cleanup.py` script is a tool for auditing and cleaning up your
Google Drive. It can be used to:

*   Identify the largest files in your Google Drive.
*   Find duplicate files based on their MD5 checksum.
*   Move files to the trash (but not permanently delete them).

## Setup

1.  **Enable the Google Drive API:**
    *   Go to the [Google Cloud Console](https://console.cloud.google.com/).
    *   Create a new project or select an existing one.
    *   In the **APIs & Services** > **Library**, search for "Google Drive API" and enable it.

2.  **Create OAuth 2.0 credentials:**

    *   In the **APIs & Services** > **Credentials**, create a new **OAuth client ID**.
    *   Select **Desktop app** as the application type.
    *   Download the JSON file and save it as `credentials.json` in the root of this repository.

## Commands

The `gdrive_cleanup.py` script has several commands, each with its own set of
arguments.

### `audit`

The `audit` command scans your Google Drive and reports the largest files.

**Usage:**

```bash
python3 gdrive_cleanup.py audit [ARGUMENTS]
```

**Arguments:**

*   `--top <N>`: The number of largest files to show (default: 25).
*   `--show-links`: Show the `webViewLink` for each file.
*   `--csv <PATH>`: Write the full file list to a CSV file.
*   `--json <PATH>`: Write the full file list to a JSON file.
*   `--query <QUERY>`: A Google Drive API query to filter the files.

### `duplicates`

The `duplicates` command finds duplicate files based on their MD5 checksum.

**Usage:**

```bash
python3 gdrive_cleanup.py duplicates [ARGUMENTS]
```

**Arguments:**

*   `--show <N>`: The number of duplicate groups to print (default: 10).
*   `--show-per-group <N>`: The number of items per group to print (default: 5).
*   `--plan-json <PATH>`: Write the duplicate groups to a JSON file for review.
*   `--query <QUERY>`: A Google Drive API query to filter the files.

### `trash`

The `trash` command moves specific files to the trash.

**Usage:**

```bash
python3 gdrive_cleanup.py trash [ARGUMENTS]
```

**Arguments:**

*   `--ids-json <PATH>`: A JSON file containing a list of file IDs to trash. The format should be `{"fileIds": ["ID1", "ID2", ...]}`.
*   `--apply`: Actually perform the trash operation. Without this flag, the script will only perform a dry run.
*   `--confirm "TRASH <N> FILES"`: A confirmation string that must be provided to trash the files. This is a safety measure to prevent accidental deletion.

### `trash-query`

The `trash-query` command moves all files matching a query to the trash.

**Usage:**

```bash
python3 gdrive_cleanup.py trash-query [ARGUMENTS]
```

**Arguments:**

*   `--name-contains <SUBSTRING>`: A convenience filter to match files where the name contains the given substring.
*   `--include-folders`: Include folders in the search (by default, folders are excluded).
*   `--limit <N>`: An optional safety limit on the number of files to trash.
*   `--show <N>`: The number of matched files to print.
*   `--show-links`: Show the `webViewLink` for each file.
*   `--ids-out <PATH>`: Write the matched file IDs to a JSON file.
*   `--apply`: Actually perform the trash operation.
*   `--confirm "TRASH <N> FILES"`: A confirmation string that must be provided to trash the files.
