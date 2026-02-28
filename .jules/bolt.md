# Bolt Learnings

## 2026-01-29 - Efficient Directory Cleanup with os.walk

**Learning:** Using pathlib.Path.rglob() to list all files and then sorting the
list to clean up empty directories is a performance anti-pattern. It loads the
entire directory structure into memory and incurs an O(N log N) sorting cost,
which can be very slow for large directories.

**Action:** For tasks requiring a bottom-up traversal of a directory tree (like
removing empty directories), always use os.walk(path, topdown=False). This
method processes directories from the deepest level up, uses minimal memory, and
operates in O(N) time. It's the idiomatic and far more performant solution.
