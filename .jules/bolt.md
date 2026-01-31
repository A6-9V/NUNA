## 2026-01-29 - Efficient Directory Cleanup with os.walk
**Learning:** Using `pathlib.Path.rglob()` to list all files and then sorting the list to clean up empty directories is a performance anti-pattern. It loads the entire directory structure into memory and incurs an O(N log N) sorting cost, which can be very slow for large directories.
**Action:** For tasks requiring a bottom-up traversal of a directory tree (like removing empty directories), always use `os.walk(path, topdown=False)`. This method processes directories from the deepest level up, uses minimal memory, and operates in O(N) time. It's the idiomatic and far more performant solution.

## 2026-01-29 - Bottlenecks in Pathlib: relative_to and resolve
**Learning:** `pathlib.Path.relative_to()` and `pathlib.Path.resolve()` are surprisingly slow as they perform complex lexical analysis or system calls. In high-frequency loops (e.g., scanning thousands of files), these can become significant bottlenecks.
**Action:** Accumulate relative paths manually during recursion (using the `/` operator) instead of calling `relative_to(root)` for every file. Also, avoid redundant `resolve()` calls by pre-resolving base paths once outside the loop.

## 2026-01-31 - Field Masking for Google Drive API
**Learning:** Using the `fields` parameter in Google Drive API `files().list()` calls (field masking) significantly reduces the JSON payload size. This reduces network latency and client-side parsing time, especially for large accounts with thousands of files.
**Action:** Always specify the minimum required fields when scanning or listing items from cloud APIs.

## 2026-01-31 - Safety vs. Performance in mkdirp Caching
**Learning:** A global cache for `mkdirp` using a `set` is unsafe because it doesn't account for external deletions of directories. While it provides a massive speedup (~40x), it sacrifices correctness.
**Action:** Avoid global state for filesystem operations. Use `if not p.is_dir():` as a safe way to speed up `Path.mkdir(parents=True, exist_ok=True)` by ~2x without sacrificing robustness.
