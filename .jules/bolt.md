## 2024-07-25 - Initial Journal Entry
**Learning:** The `gdrive_cleanup.py` script has an N+1 API call problem when trashing multiple files, making it slow. Batching API requests is the best way to fix this.
**Action:** Use batching for all Google Drive API calls that are performed in a loop to improve performance.
