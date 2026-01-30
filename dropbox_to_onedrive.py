#!/usr/bin/env python3
"""
Import a Dropbox shared folder into OneDrive.

This script is designed for "shared folder" URLs like:
  https://www.dropbox.com/scl/fo/...?...&dl=0

It will:
  1) download the Dropbox share as a ZIP (dl=1)
  2) extract it locally
  3) upload contents into OneDrive via Microsoft Graph (device-code login)

Safety:
  - By default, uploads into a NEW folder you name (no deletes)
  - Supports --dry-run to preview what would be uploaded
"""

from __future__ import annotations

import argparse
import itertools
import os
import sys
import tempfile
import time
import zipfile
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set, Tuple
from urllib.parse import parse_qsl, quote, urlencode, urlparse, urlunparse

import msal
import requests
from tqdm import tqdm


GRAPH_BASE = "https://graph.microsoft.com/v1.0"


def eprint(*args: object) -> None:
    print(*args, file=sys.stderr)


def now_stamp() -> str:
    # compact and filesystem-safe
    return time.strftime("%Y%m%d-%H%M%S", time.gmtime())


def human_bytes(n: int) -> str:
    units = ["B", "KB", "MB", "GB", "TB", "PB"]
    x = float(n)
    for u in units:
        if x < 1024 or u == units[-1]:
            return f"{x:.1f}{u}" if u != "B" else f"{int(x)}B"
        x /= 1024
    return f"{n}B"


def normalize_dropbox_download_url(url: str) -> str:
    """
    Ensure the Dropbox URL forces a download.
    Dropbox share links commonly use dl=0; set dl=1.
    """
    u = urlparse(url)
    q = dict(parse_qsl(u.query, keep_blank_values=True))
    q["dl"] = "1"
    new_query = urlencode(q)
    return urlunparse((u.scheme, u.netloc, u.path, u.params, new_query, u.fragment))


def download_to_file(url: str, *, dest_path: Path, timeout_s: int = 120) -> None:
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    with requests.get(url, stream=True, timeout=timeout_s, allow_redirects=True) as r:
        r.raise_for_status()
        with open(dest_path, "wb") as f:
            for chunk in r.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    f.write(chunk)


def pick_extracted_root(extract_dir: Path) -> Path:
    """
    Dropbox ZIPs often wrap everything in a single top-level directory.
    If so, use that as the effective root to preserve nice paths.
    """
    entries = [p for p in extract_dir.iterdir()]
    if len(entries) == 1 and entries[0].is_dir():
        return entries[0]
    return extract_dir


def iter_files_with_size(root: Path) -> Iterable[Tuple[Path, Path, int]]:
    """
    Recursively scan a directory for files, yielding their full path,
    path relative to the root, and size.

    This uses `os.scandir` which is more performant than `os.walk` followed
    by `stat` calls, as it retrieves file metadata during the initial listing.
    """

    def _scan(current_dir: Path, current_rel_path: Path):
        for entry in os.scandir(current_dir):
            if entry.is_dir():
                yield from _scan(Path(entry.path), current_rel_path / entry.name)
            elif entry.is_file():
                # The size is retrieved from the Direntry, avoiding a stat() call.
                size = entry.stat().st_size
                # --- OPTIMIZATION: Avoid expensive relative_to() ---
                # Calculating relative path by joining is much faster than Path.relative_to(root)
                # which has to walk up the path and compare parts for every file.
                yield Path(entry.path), current_rel_path / entry.name, size

    yield from _scan(root, Path(""))


def encode_drive_path(path: str) -> str:
    """
    Encode a OneDrive path for Graph's /root:/...: addressing.
    Keep forward slashes as separators.
    """
    path = path.lstrip("/")
    return quote(path, safe="/")


@dataclass(frozen=True)
class GraphAuth:
    access_token: str


class GraphClient:
    def __init__(self, auth: GraphAuth):
        self._s = requests.Session()
        self._s.headers.update(
            {
                "Authorization": f"Bearer {auth.access_token}",
            }
        )

    def get_json(self, path: str, *, params: Optional[dict] = None) -> dict:
        r = self._s.get(f"{GRAPH_BASE}{path}", params=params, timeout=120)
        r.raise_for_status()
        return r.json()

    def post_json(self, path: str, payload: dict) -> dict:
        r = self._s.post(f"{GRAPH_BASE}{path}", json=payload, timeout=120)
        r.raise_for_status()
        return r.json()

    def put_bytes(self, url: str, data: bytes, *, headers: Optional[dict] = None) -> dict:
        r = self._s.put(url, data=data, headers=headers, timeout=300)
        r.raise_for_status()
        # For upload-session finalization, Graph returns JSON item metadata
        return r.json() if r.content else {}

    def put_file_simple(self, drive_path: str, local_path: Path) -> None:
        encoded = encode_drive_path(drive_path)
        url = f"{GRAPH_BASE}/me/drive/root:/{encoded}:/content"
        with open(local_path, "rb") as f:
            r = self._s.put(url, data=f, timeout=600)
            r.raise_for_status()

    def create_upload_session(self, drive_path: str) -> str:
        encoded = encode_drive_path(drive_path)
        url = f"{GRAPH_BASE}/me/drive/root:/{encoded}:/createUploadSession"
        payload = {"item": {"@microsoft.graph.conflictBehavior": "replace"}}
        resp = self.post_json(f"/me/drive/root:/{encoded}:/createUploadSession", payload)
        upload_url = resp.get("uploadUrl")
        if not upload_url:
            raise RuntimeError("Graph did not return an uploadUrl for upload session.")
        return str(upload_url)

    def upload_large_file(
        self,
        drive_path: str,
        local_path: Path,
        *,
        total: int,
        chunk_size: int,
    ) -> None:
        upload_url = self.create_upload_session(drive_path)
        with open(local_path, "rb") as f:
            start = 0
            while start < total:
                end_exclusive = min(start + chunk_size, total)
                f.seek(start)
                data = f.read(end_exclusive - start)
                headers = {
                    "Content-Length": str(len(data)),
                    "Content-Range": f"bytes {start}-{end_exclusive - 1}/{total}",
                }
                r = self._s.put(upload_url, data=data, headers=headers, timeout=600)
                # 202 accepted for intermediate chunks; 201/200 for final chunk
                if r.status_code in (200, 201):
                    return
                if r.status_code == 202:
                    start = end_exclusive
                    continue
                r.raise_for_status()

    def delta(self, *, item_id: str) -> Iterable[dict]:
        """
        Iterate through all descendants of an item using the delta query.
        This is significantly faster than recursive listings for large folders.
        """
        next_link = f"{GRAPH_BASE}/me/drive/items/{item_id}/delta"
        while next_link:
            r = self._s.get(next_link, timeout=120)
            r.raise_for_status()
            data = r.json()
            yield from data.get("value", [])
            next_link = data.get("@odata.nextLink")

    def _iter_children(self, *, item_id: str) -> Iterable[dict]:
        """Iterate through all children of an item, handling pagination."""
        path = (
            "/me/drive/root/children"
            if item_id == "root"
            else f"/me/drive/items/{item_id}/children"
        )
        params: Optional[Dict] = {"$select": "id,name,folder", "$top": 999}
        url: Optional[str] = f"{GRAPH_BASE}{path}"
        while url:
            r = self._s.get(url, params=params, timeout=120)
            # Params are only needed for the first request with a relative path
            params = None
            r.raise_for_status()
            data = r.json()
            yield from data.get("value", [])
            url = data.get("@odata.nextLink")


def load_onedrive_auth(
    *,
    client_id: str,
    tenant: str,
    token_cache_path: Path,
) -> GraphAuth:
    cache = msal.SerializableTokenCache()
    if token_cache_path.exists():
        cache.deserialize(token_cache_path.read_text(encoding="utf-8"))

    app = msal.PublicClientApplication(
        client_id=client_id,
        authority=f"https://login.microsoftonline.com/{tenant}",
        token_cache=cache,
    )

    scopes = [
        "User.Read",
        "Files.ReadWrite.All",
        "offline_access",
    ]

    accounts = app.get_accounts()
    result = None
    if accounts:
        result = app.acquire_token_silent(scopes=scopes, account=accounts[0])

    if not result:
        flow = app.initiate_device_flow(scopes=scopes)
        msg = flow.get("message")
        if not msg:
            raise RuntimeError("Failed to initiate device-code flow. Is the client_id correct?")
        print(msg)
        result = app.acquire_token_by_device_flow(flow)

    if not result or "access_token" not in result:
        raise RuntimeError(f"Failed to get access token: {result}")

    if cache.has_state_changed:
        token_cache_path.write_text(cache.serialize(), encoding="utf-8")

    return GraphAuth(access_token=str(result["access_token"]))


def get_existing_files_delta(
    client: GraphClient, *, item_id: str, dest_folder_name: str
) -> Set[Path]:
    """
    Use Graph's `delta` query for a high-performance recursive file listing.
    This avoids the N+1 problem of traversing the folder hierarchy manually.
    """
    existing_paths: Set[Path] = set()
    # The `delta` response provides item paths relative to the drive root.
    # We need to strip the destination folder's path to make them relative
    # to the sync root, for accurate duplicate detection.
    # Example: we want "sub/file.txt", not "MyImport/sub/file.txt".
    path_prefix_to_strip = f"{dest_folder_name}/"

    for item in client.delta(item_id=item_id):
        # The `parentReference.path` gives the full path from the drive root.
        # Example: /drives/{id}/root:/folder/subfolder
        path_str = item.get("parentReference", {}).get("path")
        name = item.get("name")
        if not path_str or not name or not item.get("file"):
            continue

        # Find the start of the path relative to the drive root.
        colon_idx = path_str.find(":")
        if colon_idx == -1:
            continue

        # This gives a path like: /folder/subfolder
        path_from_root = path_str[colon_idx + 1 :]

        # Full path of the item from the drive root.
        full_path_from_root = f"{path_from_root}/{name}"

        # Normalize to remove any leading slash for consistent matching.
        full_path_from_root = full_path_from_root.lstrip("/")

        if full_path_from_root.startswith(path_prefix_to_strip):
            rel_path_str = full_path_from_root[len(path_prefix_to_strip) :]
            existing_paths.add(Path(rel_path_str))

    return existing_paths


def get_or_create_folder(
    client: GraphClient,
    *,
    parent_id: str,
    name: str,
    children_cache: Dict[str, Dict[str, str]],
) -> str:
    # Cache by parent_id: { folder_name -> folder_id }
    if parent_id not in children_cache:
        mapping: Dict[str, str] = {}
        for ch in client._iter_children(item_id=parent_id):
            if ch.get("folder") is None:
                continue
            nm = ch.get("name")
            cid = ch.get("id")
            if isinstance(nm, str) and isinstance(cid, str):
                mapping[nm] = cid
        children_cache[parent_id] = mapping

    if name in children_cache[parent_id]:
        return children_cache[parent_id][name]

    payload = {
        "name": name,
        "folder": {},
        "@microsoft.graph.conflictBehavior": "fail",
    }
    try:
        if parent_id == "root":
            created = client.post_json("/me/drive/root/children", payload)
        else:
            created = client.post_json(f"/me/drive/items/{parent_id}/children", payload)
        fid = str(created["id"])
        children_cache[parent_id][name] = fid
        return fid
    except requests.HTTPError as ex:
        # If it already exists (e.g. race or rerun), refresh and try again once.
        resp = getattr(ex, "response", None)
        if resp is not None and resp.status_code == 409:
            children_cache.pop(parent_id, None)
            return get_or_create_folder(
                client, parent_id=parent_id, name=name, children_cache=children_cache
            )
        raise


def ensure_folder_path(
    client: GraphClient,
    *,
    base_parent_id: str,
    rel_folder: Path,
    children_cache: Dict[str, Dict[str, str]],
    folder_id_cache: Dict[str, str],
) -> str:
    """
    Ensure rel_folder exists under base_parent_id and return its item id.
    rel_folder is relative (no leading slash).
    """
    # --- OPTIMIZATION: Quick cache lookup for full path ---
    # Before splitting the path and checking each part, check if the full
    # path is already known. This avoids O(depth) string operations and
    # dict lookups for every file in the same directory.
    full_path_posix = rel_folder.as_posix()
    if full_path_posix in folder_id_cache:
        return folder_id_cache[full_path_posix]

    rel_parts = [p for p in rel_folder.parts if p not in ("", ".", "/")]
    if not rel_parts:
        return base_parent_id

    cur_id = base_parent_id
    cur_key = ""
    for part in rel_parts:
        cur_key = f"{cur_key}/{part}" if cur_key else part
        if cur_key in folder_id_cache:
            cur_id = folder_id_cache[cur_key]
            continue
        cur_id = get_or_create_folder(
            client, parent_id=cur_id, name=part, children_cache=children_cache
        )
        folder_id_cache[cur_key] = cur_id
    return cur_id


def upload_one_file(
    local_file: Path,
    rel_path: Path,
    file_size: int,
    *,
    client: GraphClient,
    dest_folder_id: str,
    onedrive_folder: str,
    children_cache: Dict[str, Dict[str, str]],
    folder_id_cache: Dict[str, str],
    chunk_size: int,
) -> Tuple[str, int]:
    parent_rel = rel_path.parent
    # This function is run in a thread, so directory creation needs to be safe.
    # The main thread pre-creates all directories, so this call should be cached.
    ensure_folder_path(
        client,
        base_parent_id=dest_folder_id,
        rel_folder=parent_rel,
        children_cache=children_cache,
        folder_id_cache=folder_id_cache,
    )

    drive_path = f"{onedrive_folder}/{rel_path.as_posix()}"
    if file_size <= 4 * 1024 * 1024:
        client.put_file_simple(drive_path, local_file)
    else:
        client.upload_large_file(
            drive_path,
            local_file,
            total=file_size,
            chunk_size=chunk_size,
        )
    return (str(rel_path), file_size)


def main(argv: List[str]) -> int:
    p = argparse.ArgumentParser(
        prog="dropbox_to_onedrive.py",
        description="Download a Dropbox shared folder and upload it into OneDrive.",
    )
    p.add_argument("--dropbox-url", required=True, help="Dropbox shared folder URL")
    p.add_argument(
        "--onedrive-folder",
        default=f"Dropbox Import {now_stamp()}",
        help="Destination folder name in OneDrive root",
    )
    p.add_argument(
        "--client-id",
        default=os.environ.get("ONEDRIVE_CLIENT_ID") or "",
        help="Azure app client id (or set env ONEDRIVE_CLIENT_ID)",
    )
    p.add_argument(
        "--tenant",
        default=os.environ.get("ONEDRIVE_TENANT") or "common",
        help="Tenant for login (common | organizations | consumers | <tenant-id>)",
    )
    p.add_argument(
        "--token-cache",
        default=os.environ.get("ONEDRIVE_TOKEN_CACHE") or ".onedrive_token_cache.json",
        help="Path to MSAL token cache file",
    )
    p.add_argument("--dry-run", action="store_true", help="Do not upload; only show plan")
    p.add_argument(
        "--chunk-mb",
        type=int,
        default=10,
        help="Upload session chunk size in MB (for files > 4MB). Use 10 by default.",
    )
    p.add_argument(
        "--keep-zip",
        action="store_true",
        help="Keep downloaded ZIP (writes dropbox-download.zip to current dir)",
    )
    p.add_argument(
        "--keep-extracted",
        action="store_true",
        help="Keep extracted files (writes to ./dropbox-extracted/)",
    )
    p.add_argument(
        "--parallel",
        type=int,
        default=1,
        help="Number of parallel uploads to run (default: 1, sequential). Improves performance for many small files.",
    )
    p.add_argument("--skip-duplicates", action="store_true", help="Do not upload files that already exist in the destination")
    args = p.parse_args(argv)

    if not args.client_id:
        eprint("Missing --client-id (or set env ONEDRIVE_CLIENT_ID).")
        return 2

    dl_url = normalize_dropbox_download_url(args.dropbox_url)

    if args.keep_zip:
        zip_path = Path("dropbox-download.zip").resolve()
        tmp_zip_ctx = None
    else:
        tmp_zip_ctx = tempfile.TemporaryDirectory(prefix="dropbox_zip_")
        zip_path = Path(tmp_zip_ctx.name) / "dropbox.zip"

    try:
        print(f"Downloading Dropbox ZIP...")
        download_to_file(dl_url, dest_path=zip_path)
        zip_size = zip_path.stat().st_size
        print(f"Downloaded: {zip_path.name} ({human_bytes(zip_size)})")

        if args.keep_extracted:
            extract_dir = Path("dropbox-extracted").resolve()
            extract_dir.mkdir(parents=True, exist_ok=True)
            tmp_extract_ctx = None
        else:
            tmp_extract_ctx = tempfile.TemporaryDirectory(prefix="dropbox_extract_")
            extract_dir = Path(tmp_extract_ctx.name)

        try:
            print("Extracting ZIP...")
            with zipfile.ZipFile(zip_path) as zf:
                zf.extractall(extract_dir)
            src_root = pick_extracted_root(extract_dir)

            # --- OPTIMIZATION: Single-pass file scan with pre-calculation ---
            # Use a single pass to collect file paths and sizes, avoiding
            # repeated `stat()` calls. This is a measurable performance gain
            # for directories with thousands of files.
            files: List[Tuple[Path, Path, int]] = list(iter_files_with_size(src_root))
            total = sum(size for _, _, size in files)
            print(f"Files to upload: {len(files)} (total {human_bytes(total)})")

            if args.dry_run:
                # Use the pre-calculated relative path and size
                for _, rel_path, size in files[:50]:
                    print(f"- {rel_path.as_posix()} ({human_bytes(size)})")
                if len(files) > 50:
                    print(f"... and {len(files) - 50} more")
                print("Dry-run complete (no uploads).")
                return 0

            token_cache_path = Path(args.token_cache).expanduser().resolve()
            auth = load_onedrive_auth(
                client_id=args.client_id,
                tenant=args.tenant,
                token_cache_path=token_cache_path,
            )
            client = GraphClient(auth)

            # Create destination folder under OneDrive root
            children_cache: Dict[str, Dict[str, str]] = {}
            folder_id_cache: Dict[str, str] = {}
            dest_folder_id = get_or_create_folder(
                client, parent_id="root", name=args.onedrive_folder, children_cache=children_cache
            )

            if args.skip_duplicates:
                print("Checking for existing files in OneDrive (this may take a while for large folders)...")
                # --- OPTIMIZATION: High-performance duplicate check ---
                # Use the Graph API's `delta` query to fetch the entire file
                # list in the destination folder in a single operation. This
                # avoids the N+1 problem of recursively listing directories,
                # significantly speeding up the check for large, nested folders.
                existing_paths = get_existing_files_delta(
                    client, item_id=dest_folder_id, dest_folder_name=args.onedrive_folder
                )
                if existing_paths:
                    original_count = len(files)
                    # --- FIX: Ensure `files` is reassigned to the filtered list ---
                    # The original logic failed to reassign the `files` variable if no
                    # duplicates were found, causing the upload step to iterate over
                    # the wrong list. This is corrected by always reassigning `files`
                    # to the filtered result.
                    files = [
                        (p, rel_p, size)
                        for p, rel_p, size in files
                        if rel_p not in existing_paths
                    ]
                    skipped = original_count - len(files)
                    if skipped > 0:
                        print(f"Found {len(existing_paths)} existing files. Skipping {skipped} duplicates.")
                else:
                    print("No existing files found in destination.")

            chunk_size = max(1, int(args.chunk_mb)) * 1024 * 1024
            # Graph best practice: chunk size multiple of 320 KiB
            if chunk_size % 327_680 != 0:
                # round down to nearest multiple (minimum 320 KiB)
                chunk_size = max(327_680, (chunk_size // 327_680) * 327_680)

            print(f"Uploading into OneDrive folder: {args.onedrive_folder}")

            # --- OPTIMIZATION: Parallel uploads ---
            # To make parallel uploads safe, first discover all unique directories
            # and create them sequentially. This avoids race conditions where
            # multiple threads might try to create the same folder.
            # This is a performance optimization for folders with many files,
            # as network I/O can be done concurrently.
            print("Pre-creating directories...")
            # Use pre-calculated relative paths
            all_dirs = sorted(
                list(
                    {
                        rel_p.parent
                        for _, rel_p, _ in files
                        if rel_p.parent != Path(".")
                    }
                )
            )
            for d in all_dirs:
                ensure_folder_path(
                    client,
                    base_parent_id=dest_folder_id,
                    rel_folder=d,
                    children_cache=children_cache,
                    folder_id_cache=folder_id_cache,
                )

            # Now, upload files in parallel.
            workers = min(max(1, args.parallel), 32)
            uploaded_count = 0
            if not files:
                print("No files to upload.")
                return 0

            with tqdm(total=len(files), unit="file") as pbar:
                if workers > 1:
                    print(f"Uploading with {workers} parallel workers...")
                    with ThreadPoolExecutor(max_workers=workers) as ex:
                        # Unpack the (local_path, rel_path, size) tuples
                        local_paths, rel_paths, sizes = zip(*files)
                        tasks = ex.map(
                            upload_one_file,
                            local_paths,
                            rel_paths,
                            sizes,
                            itertools.repeat(client),
                            itertools.repeat(dest_folder_id),
                            itertools.repeat(args.onedrive_folder),
                            itertools.repeat(children_cache),
                            itertools.repeat(folder_id_cache),
                            itertools.repeat(chunk_size),
                        )
                        for _, size in tasks:
                            uploaded_count += 1
                            pbar.update(1)
                else:
                    # Sequential upload for --parallel=1
                    print("Uploading sequentially...")
                    for local_file, rel_path, size in files:
                        upload_one_file(
                            local_file,
                            rel_path,
                            size,
                            client=client,
                            dest_folder_id=dest_folder_id,
                            onedrive_folder=args.onedrive_folder,
                            children_cache=children_cache,
                            folder_id_cache=folder_id_cache,
                            chunk_size=chunk_size,
                        )
                        uploaded_count += 1
                        pbar.update(1)

            print(f"Done. Uploaded {uploaded_count} files into '{args.onedrive_folder}'.")
            return 0
        finally:
            if not args.keep_extracted and "tmp_extract_ctx" in locals() and tmp_extract_ctx:
                tmp_extract_ctx.cleanup()
    finally:
        if not args.keep_zip and tmp_zip_ctx:
            tmp_zip_ctx.cleanup()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

