# Book Map

This document provides a high-level overview of the repository's scripts, their functionalities, and the data flow between them.

## Device and Data Flow Map

This section illustrates the connections between your local machine, the cloud services, and the scripts in this repository.

### `gdrive_cleanup.py`

*   **Purpose:** To audit and clean up your Google Drive by identifying large and duplicate files.
*   **Action:**
    1.  Authenticates with your Google account using OAuth 2.0.
    2.  Scans your Google Drive files based on your specified criteria (e.g., file size, duplicates).
    3.  Provides a report of the findings.
    4.  Can move files to the trash (but does not permanently delete them).
*   **Target:** Google Drive.
*   **Next Steps:**
    *   Review the generated reports (`.csv`, `.json`).
    *   Create a list of file IDs to be trashed.
    *   Run the `trash` command with the list of file IDs.

### `dropbox_to_onedrive.py`

*   **Purpose:** To import a shared folder from Dropbox into your OneDrive.
*   **Action:**
    1.  Downloads the Dropbox shared folder as a ZIP file.
    2.  Extracts the ZIP file locally.
    3.  Authenticates with your Microsoft account using OAuth 2.0.
    4.  Uploads the extracted files to a specified folder in your OneDrive.
*   **Target:** Dropbox (read-only), OneDrive (write).
*   **Next Steps:**
    *   Verify that the files have been successfully uploaded to your OneDrive.

## Repository Instruction and Map

This section provides instructions on how to set up the repository and where to find the key scripts.

### Setup Instructions

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/USERNAME/REPOSITORY.git
    cd REPOSITORY
    ```

2.  **Create a virtual environment:**
    ```bash
    python3 -m venv .venv
    source .venv/bin/activate
    ```

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Set up OAuth credentials:**
    *   For `gdrive_cleanup.py`, follow the instructions in the `README.md` to create `credentials.json`.
    *   For `dropbox_to_onedrive.py`, follow the instructions in the `README.md` to set the `ONEDRIVE_CLIENT_ID` environment variable.

### File and Script Locations

*   `gdrive_cleanup.py`: The main script for auditing and cleaning up Google Drive.
*   `dropbox_to_onedrive.py`: The main script for importing Dropbox shared folders to OneDrive.
*   `requirements.txt`: A list of the Python dependencies required to run the scripts.
*   `guidebook/`: The directory containing this guide book.

### GitHub Agents Setup

*   `guidebook/04_org_copilot_agents_setup.md`: A comprehensive guide for setting up GitHub Copilot and Jules agents at the organization level.
