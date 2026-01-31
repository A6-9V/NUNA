#!/usr/bin/env python3
"""
Safe Google Drive cleanup helper.

Defaults:
  - read-only scope (audit/duplicates)
  - never deletes permanently (only optional "trash")
  - "trash" requires explicit --apply and a confirmation string

Setup:
  1) Create OAuth client in Google Cloud Console (Desktop app)
  2) Download JSON and save as ./credentials.json
  3) Run: python gdrive_cleanup.py audit
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import heapq
import json
import os
import sys
from collections import defaultdict
from dataclasses import dataclass
from typing import Any, Dict, Iterable, List, Optional, Tuple

from common_utils import eprint, human_bytes, now_stamp, write_json
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from tqdm import tqdm


SCOPES_READONLY = ["https://www.googleapis.com/auth/drive.metadata.readonly"]
SCOPES_TRASH = ["https://www.googleapis.com/auth/drive"]


GOOGLE_API_BATCH_LIMIT = 100


DEFAULT_FIELDS = ",".join(
    [
        "nextPageToken",
        "files(id,name,mimeType,size,md5Checksum,trashed,createdTime,modifiedTime,owners(displayName,emailAddress),parents,webViewLink)",
    ]
)


# --- OPTIMIZATION: Minimal fields for trash-query ---
# To speed up the initial file scan, the `trash-query` command requests only
# the fields essential for identifying, displaying, and trashing files. This
# reduces the API response payload size, improving performance.
TRASH_QUERY_FIELDS = ",".join(
    [
        "nextPageToken",
        "files(id,name,size,webViewLink)",
    ]
)


# --- OPTIMIZATION: Minimal fields for duplicates pass 1 ---
# To speed up finding duplicates, the first pass requests only the fields
# essential for identifying files with the same content. This minimizes the
# initial API response payload.
DUPLICATES_PASS1_FIELDS = ",".join(
    [
        "nextPageToken",
        "files(id,size,md5Checksum)",
    ]
)


# --- OPTIMIZATION: Fields for fetching full file metadata ---
# Used in the second pass of the duplicates command to fetch detailed metadata
# for only the files identified as duplicates.
FULL_FILE_FIELDS = "id,name,mimeType,size,md5Checksum,trashed,createdTime,modifiedTime,owners(displayName,emailAddress),parents,webViewLink"


@dataclass(frozen=True)
class DriveFile:
    id: str
    name: str
    mimeType: str
    size: Optional[int]
    md5Checksum: Optional[str]
    trashed: bool
    createdTime: Optional[str]
    modifiedTime: Optional[str]
    owners: Tuple[str, ...]
    webViewLink: Optional[str]

    @staticmethod
    def from_api(d: Dict[str, Any]) -> "DriveFile":
        owners = tuple(
            o.get("emailAddress") or o.get("displayName") or "unknown"
            for o in (d.get("owners") or [])
        )
        size_raw = d.get("size")
        try:
            size = int(size_raw) if size_raw is not None else None
        except ValueError:
            size = None
        return DriveFile(
            id=d["id"],
            name=d.get("name", ""),
            mimeType=d.get("mimeType", ""),
            size=size,
            md5Checksum=d.get("md5Checksum"),
            trashed=bool(d.get("trashed", False)),
            createdTime=d.get("createdTime"),
            modifiedTime=d.get("modifiedTime"),
            owners=owners,
            webViewLink=d.get("webViewLink"),
        )


def load_credentials(
    *,
    credentials_path: str,
    token_path: str,
    scopes: List[str],
) -> Credentials:
    creds: Optional[Credentials] = None
    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, scopes=scopes)
    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())
    if not creds or not creds.valid:
        if not os.path.exists(credentials_path):
            raise FileNotFoundError(
                f"Missing OAuth client secrets file: {credentials_path}\n"
                "Create a 'Desktop app' OAuth client in Google Cloud Console, download JSON, "
                "and save it as ./credentials.json"
            )
        flow = InstalledAppFlow.from_client_secrets_file(credentials_path, scopes=scopes)
        creds = flow.run_local_server(port=0)
    with open(token_path, "w", encoding="utf-8") as f:
        f.write(creds.to_json())
    return creds


def drive_service(*, creds: Credentials) -> Any:
    """Initialize the Drive API service."""
    # cache_discovery=False avoids writing discovery cache files
    return build("drive", "v3", credentials=creds, cache_discovery=False)


def iter_files(
    service: Any,
    *,
    q: Optional[str],
    include_trashed: bool,
    page_size: int,
    fields: str = DEFAULT_FIELDS,
) -> Iterable[DriveFile]:
    page_token = None
    base_q = q.strip() if q else ""
    if include_trashed:
        final_q = base_q or None
    else:
        trash_filter = "trashed = false"
        if base_q:
            final_q = f"({base_q}) and ({trash_filter})"
        else:
            final_q = trash_filter

    while True:
        resp = (
            service.files()
            .list(
                q=final_q,
                fields=fields,
                pageSize=page_size,
                pageToken=page_token,
                supportsAllDrives=True,
                includeItemsFromAllDrives=True,
            )
            .execute()
        )
        for f in resp.get("files", []):
            yield DriveFile.from_api(f)
        page_token = resp.get("nextPageToken")
        if not page_token:
            break


def write_csv(path: str, files: List[DriveFile]) -> None:
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(
            [
                "id",
                "name",
                "mimeType",
                "size",
                "md5Checksum",
                "owners",
                "trashed",
                "createdTime",
                "modifiedTime",
                "webViewLink",
            ]
        )
        for x in files:
            w.writerow(
                [
                    x.id,
                    x.name,
                    x.mimeType,
                    x.size if x.size is not None else "",
                    x.md5Checksum or "",
                    ";".join(x.owners),
                    str(x.trashed).lower(),
                    x.createdTime or "",
                    x.modifiedTime or "",
                    x.webViewLink or "",
                ]
            )


def drive_single_quote(value: str) -> str:
    """
    Quote a value for Drive query strings using single quotes.
    Drive query syntax uses single-quoted string literals.
    """
    escaped = value.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{escaped}'"


def and_query(parts: Iterable[Optional[str]]) -> Optional[str]:
    xs = [p.strip() for p in parts if p and p.strip()]
    if not xs:
        return None
    if len(xs) == 1:
        return xs[0]
    return " and ".join(f"({x})" for x in xs)


# --- OPTIMIZATION: Batch trash requests ---
# For improved performance when trashing many files, this function uses batch
# requests to minimize HTTP overhead. Instead of one API call per file, it
# groups up to 100 trash operations into a single multipart HTTP request.
# This significantly reduces latency from network round-trips.
def _trash_batch_callback(
    request_id: str,
    response: Any,
    exception: Optional[HttpError],
    *,
    failed_list: List[Tuple[str, str]],
) -> None:
    """Callback for batch API requests to collect failures."""
    if exception:
        failed_list.append((request_id, str(exception)))


def trash_files_batch(
    service: Any, *, file_ids: List[str]
) -> Tuple[int, List[Tuple[str, str]]]:
    """Trash a list of file IDs using batch requests for performance."""
    if not file_ids:
        return (0, [])
    failed: List[Tuple[str, str]] = []
    batch = service.new_batch_http_request(
        callback=lambda req_id, resp, exc: _trash_batch_callback(
            req_id, resp, exc, failed_list=failed
        )
    )

    with tqdm(total=len(file_ids), desc="Trashing files", unit="files") as pbar:
        for i, fid in enumerate(file_ids):
            batch.add(
                service.files().update(fileId=fid, body={"trashed": True}),
                request_id=fid,
            )
            # Batch supports up to 100 calls. Execute every 100.
            if (i + 1) % GOOGLE_API_BATCH_LIMIT == 0:
                batch.execute()
                pbar.update(GOOGLE_API_BATCH_LIMIT)
                # Create a new batch for the next set of requests.
                batch = service.new_batch_http_request(
                    callback=lambda req_id, resp, exc: _trash_batch_callback(
                        req_id, resp, exc, failed_list=failed
                    )
                )
        # Execute any remaining requests in the last batch.
        remainder = (i + 1) % GOOGLE_API_BATCH_LIMIT
        if remainder != 0:
            batch.execute()
            pbar.update(remainder)

    ok = len(file_ids) - len(failed)
    return (ok, failed)


def get_files_batch(service: Any, *, file_ids: List[str]) -> Iterable[DriveFile]:
    """
    Fetch metadata for a list of file IDs using batch requests.
    This is more efficient than N+1 individual requests.
    """
    if not file_ids:
        return []

    results: List[DriveFile] = []
    failures: List[Tuple[str, str]] = []

    def _callback(req_id: str, resp: Any, exc: Optional[HttpError]) -> None:
        """
        Callback to process results from a batch request.
        - On success, parses the response and appends a DriveFile to `results`.
        - On failure, logs the exception to `failures`.
        """
        if exc:
            failures.append((req_id, str(exc)))
        else:
            # The response (`resp`) is already a parsed JSON dict.
            results.append(DriveFile.from_api(resp))

    # --- OPTIMIZATION: Batch chunking ---
    # The Google Drive API limits batch requests to 100 calls. To handle
    # more than 100 file IDs, the list is processed in chunks, executing a
    # separate batch request for each. This makes the function robust for
    # large inputs and avoids API errors.
    with tqdm(total=len(file_ids), desc="Fetching metadata", unit="files") as pbar:
        for i in range(0, len(file_ids), GOOGLE_API_BATCH_LIMIT):
            chunk = file_ids[i : i + GOOGLE_API_BATCH_LIMIT]
            batch = service.new_batch_http_request(callback=_callback)
            for fid in chunk:
                batch.add(
                    service.files().get(
                        fileId=fid, fields=FULL_FILE_FIELDS, supportsAllDrives=True
                    ),
                    request_id=fid,
                )
            batch.execute()
            pbar.update(len(chunk))

    if failures:
        eprint(f"Batch metadata fetch failed for {len(failures)} files:")
        for fid, msg in failures[:10]:
            eprint(f"- {fid}: {msg}")

    return results


def cmd_trash_query(args: argparse.Namespace) -> int:
    # This command modifies Drive, so it uses the broader scope.
    scopes = SCOPES_TRASH
    creds = load_credentials(
        credentials_path=args.credentials,
        token_path=args.token,
        scopes=scopes,
    )
    service = drive_service(creds=creds)

    name_q = None
    if args.name_contains:
        name_q = f"name contains {drive_single_quote(args.name_contains)}"

    folder_filter = None
    if not args.include_folders:
        folder_filter = "mimeType != 'application/vnd.google-apps.folder'"

    final_q = and_query([args.query, name_q, folder_filter])

    matched: List[DriveFile] = []
    try:
        iterator = iter_files(
            service,
            q=final_q,
            include_trashed=args.include_trashed,
            page_size=args.page_size,
            fields=TRASH_QUERY_FIELDS,
        )
        for f in tqdm(iterator, desc="Scanning for trash candidates", unit="files"):
            matched.append(f)
            if args.limit and len(matched) >= args.limit:
                break
    except HttpError as ex:
        eprint("Drive API error:", ex)
        return 2

    n = len(matched)
    print(f"Matched files: {n}")
    if final_q:
        print(f"Query used: {final_q}")
    print("")

    if n == 0:
        print("Nothing to do.")
        return 0

    show_n = min(args.show, n)
    print(f"Showing {show_n}/{n}:")
    for f in matched[:show_n]:
        print(f"- {human_bytes(f.size)}  {f.name}  ({f.id})")
        if args.show_links and f.webViewLink:
            print(f"  link: {f.webViewLink}")

    if args.ids_out:
        write_json(args.ids_out, {"fileIds": [x.id for x in matched]})
        print("")
        print(f"Wrote IDs JSON: {args.ids_out}")

    expected = f"TRASH {n} FILES"
    print("")
    print(f"To proceed, re-run with: --confirm \"{expected}\" --apply")

    # If user hasn't provided the confirm string, stop here.
    if args.confirm is None:
        return 0

    if args.confirm != expected:
        eprint("Refusing to proceed without exact confirmation string.")
        eprint(f"Provide: --confirm \"{expected}\"")
        return 2

    # Dry-run unless --apply
    if not args.apply:
        print("Dry-run only (no changes). Re-run with --apply to execute.")
        return 0

    ok, failed = trash_files_batch(service, file_ids=[f.id for f in matched])

    print(f"Trashed: {ok}/{n}")
    if failed:
        print("")
        print("Failures:")
        for fid, msg in failed[:25]:
            print(f"- {fid}: {msg}")
        if len(failed) > 25:
            print(f"... and {len(failed) - 25} more")
        return 3
    return 0


def cmd_audit(args: argparse.Namespace) -> int:
    scopes = SCOPES_READONLY
    creds = load_credentials(
        credentials_path=args.credentials,
        token_path=args.token,
        scopes=scopes,
    )
    service = drive_service(creds=creds)

    # --- OPTIMIZATION: Memory-efficient audit ---
    # When not exporting to CSV/JSON, the audit can find the largest files
    # without storing the entire file list in memory. This is critical for
    # very large drives, as it reduces memory usage from O(N) to O(k), where N
    # is the total number of files and k is the number of top files to show.
    # A min-heap is used to keep track of the largest k files seen so far.
    is_exporting = args.csv or args.json
    if is_exporting:
        # Fallback to the original memory-intensive method when exporting.
        return _cmd_audit_export(args, service)

    top_n_heap: List[Tuple[int, DriveFile]] = []
    total_size = 0
    scanned_count = 0
    count_with_size = 0
    try:
        iterator = iter_files(
            service,
            q=args.query,
            include_trashed=args.include_trashed,
            page_size=args.page_size,
        )
        for f in tqdm(iterator, desc="Scanning files", unit="files"):
            scanned_count += 1
            if f.size is not None:
                total_size += f.size
                count_with_size += 1
                # Use a min-heap to keep track of the k largest files.
                if len(top_n_heap) < args.top:
                    heapq.heappush(top_n_heap, (f.size, f))
                else:
                    heapq.heappushpop(top_n_heap, (f.size, f))
    except HttpError as ex:
        eprint("Drive API error:", ex)
        return 2

    # The heap contains the k largest files, sorted smallest to largest.
    top_n_files = sorted([item[1] for item in top_n_heap], key=lambda x: x.size or -1, reverse=True)

    print(f"Files scanned: {scanned_count}")
    print(f"Total size (files with size): {human_bytes(total_size)} ({count_with_size} files)")
    print("")
    print(f"Top {len(top_n_files)} largest files:")
    for f in top_n_files:
        print(f"- {human_bytes(f.size)}  {f.name}  ({f.id})")
        if args.show_links and f.webViewLink:
            print(f"  link: {f.webViewLink}")
    return 0


def _cmd_audit_export(args: argparse.Namespace, service: Any) -> int:
    """Original audit implementation, used when exporting requires all files in memory."""
    files: List[DriveFile] = []
    total_size = 0
    count_with_size = 0
    try:
        iterator = iter_files(
            service,
            q=args.query,
            include_trashed=args.include_trashed,
            page_size=args.page_size,
        )
        for f in tqdm(iterator, desc="Scanning files for export", unit="files"):
            files.append(f)
            if f.size is not None:
                total_size += f.size
                count_with_size += 1
    except HttpError as ex:
        eprint("Drive API error:", ex)
        return 2

    files_sorted = sorted(files, key=lambda x: (x.size or -1), reverse=True)
    top_n = files_sorted[: args.top]

    print(f"Files scanned: {len(files)}")
    print(f"Total size (files with size): {human_bytes(total_size)} ({count_with_size} files)")
    print("")
    print(f"Top {len(top_n)} largest files:")
    for f in top_n:
        print(f"- {human_bytes(f.size)}  {f.name}  ({f.id})")
        if args.show_links and f.webViewLink:
            print(f"  link: {f.webViewLink}")

    if args.csv:
        write_csv(args.csv, files_sorted)
        print("")
        print(f"Wrote CSV: {args.csv}")
    if args.json:
        payload = {
            "generatedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
            "query": args.query,
            "includeTrashed": args.include_trashed,
            "fileCount": len(files),
            "totalSizeBytes": total_size,
            "files": [f.__dict__ for f in files_sorted],
        }
        write_json(args.json, payload)
        print("")
        print(f"Wrote JSON: {args.json}")
    return 0


def cmd_duplicates(args: argparse.Namespace) -> int:
    scopes = SCOPES_READONLY
    creds = load_credentials(
        credentials_path=args.credentials,
        token_path=args.token,
        scopes=scopes,
    )
    service = drive_service(creds=creds)

    # --- OPTIMIZATION: Two-pass strategy for finding duplicates ---
    # Pass 1: Fetch minimal fields to find duplicate md5Checksums.
    # This pass is memory-efficient and minimizes API response size.
    eprint("Pass 1: Finding duplicate checksums...")
    by_hash: Dict[str, List[str]] = defaultdict(list)
    scanned = 0
    try:
        iterator = iter_files(
            service,
            q=args.query,
            include_trashed=args.include_trashed,
            page_size=args.page_size,
            fields=DUPLICATES_PASS1_FIELDS,
        )
        for f in tqdm(iterator, desc="Scanning checksums", unit="files"):
            scanned += 1
            if f.md5Checksum:
                by_hash[f.md5Checksum].append(f.id)
    except HttpError as ex:
        eprint("Drive API error (pass 1):", ex)
        return 2

    # Filter for checksums with 2 or more files.
    dup_checksums = {k: v for k, v in by_hash.items() if len(v) >= 2}
    if not dup_checksums:
        print("No duplicate files found.")
        return 0

    # Pass 2: Fetch full metadata for only the duplicate files.
    # This avoids fetching unnecessary data for unique files.
    eprint(f"Pass 2: Fetching metadata for {len(dup_checksums)} duplicate groups...")
    dup_file_ids = [fid for ids in dup_checksums.values() for fid in ids]

    files_by_hash: Dict[str, List[DriveFile]] = defaultdict(list)
    try:
        for f in get_files_batch(service, file_ids=dup_file_ids):
            if f.md5Checksum:
                files_by_hash[f.md5Checksum].append(f)
    except HttpError as ex:
        eprint("Drive API error (pass 2):", ex)
        return 2

    dup_groups = sorted(
        files_by_hash.values(),
        key=lambda g: sum(x.size or 0 for x in g),
        reverse=True,
    )

    print(f"Files scanned: {scanned}")
    print(f"Duplicate groups found (md5Checksum): {len(dup_groups)}")
    print("")

    plan: Dict[str, Any] = {
        "generatedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
        "kind": "gdrive-trash-plan",
        "note": "Review carefully. This plan is NOT executed unless you run: trash --apply",
        "groups": [],
    }

    shown = 0
    for g in dup_groups:
        total = sum((x.size or 0) for x in g)
        group = {
            "md5Checksum": g[0].md5Checksum,
            "totalSizeBytes": total,
            "files": [x.__dict__ for x in sorted(g, key=lambda x: (x.modifiedTime or ""))],
        }
        plan["groups"].append(group)

        if shown < args.show:
            print(f"md5={g[0].md5Checksum}  total={human_bytes(total)}  count={len(g)}")
            for x in sorted(g, key=lambda x: (x.size or -1), reverse=True)[: args.show_per_group]:
                print(f"  - {human_bytes(x.size)}  {x.name}  ({x.id})")
            print("")
            shown += 1

    if args.plan_json:
        write_json(args.plan_json, plan)
        print(f"Wrote plan JSON: {args.plan_json}")
        print("Tip: open it, choose which file IDs to trash, then run the 'trash' command.")
    return 0


def cmd_trash(args: argparse.Namespace) -> int:
    # This command modifies Drive, so it uses the broader scope.
    scopes = SCOPES_TRASH
    creds = load_credentials(
        credentials_path=args.credentials,
        token_path=args.token,
        scopes=scopes,
    )
    service = drive_service(creds=creds)

    if not os.path.exists(args.ids_json):
        eprint(f"Missing ids JSON: {args.ids_json}")
        return 2
    with open(args.ids_json, "r", encoding="utf-8") as f:
        payload = json.load(f)

    file_ids = payload.get("fileIds")
    if not isinstance(file_ids, list) or not all(isinstance(x, str) for x in file_ids):
        eprint("ids JSON must look like: {\"fileIds\": [\"<id>\", ...]}")
        return 2

    file_ids = list(dict.fromkeys(file_ids))  # de-dupe, keep order
    n = len(file_ids)
    if n == 0:
        print("No file IDs provided; nothing to do.")
        return 0

    expected = f"TRASH {n} FILES"
    if args.confirm != expected:
        eprint("Refusing to proceed without exact confirmation string.")
        eprint(f"Provide: --confirm \"{expected}\"")
        eprint("This is a safety check so a copied command can’t trash the wrong set.")
        return 2

    # Dry-run unless --apply
    print(f"Will move {n} files to trash.")
    if not args.apply:
        print("Dry-run only (no changes). Re-run with --apply to execute.")
        return 0

    ok, failed = trash_files_batch(service, file_ids=file_ids)

    print(f"Trashed: {ok}/{n}")
    if failed:
        print("")
        print("Failures:")
        for fid, msg in failed[:25]:
            print(f"- {fid}: {msg}")
        if len(failed) > 25:
            print(f"... and {len(failed) - 25} more")
        return 3
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="gdrive_cleanup.py",
        description="Audit Google Drive, find duplicates, and optionally move selected items to trash (safely).",
    )
    p.add_argument("--credentials", default="credentials.json", help="OAuth client secrets JSON path")
    p.add_argument("--token", default="token.json", help="OAuth token cache path")
    p.add_argument(
        "--include-trashed",
        action="store_true",
        help="Include items already in trash when scanning",
    )
    p.add_argument("--query", default=None, help="Drive API query (q=...) to filter files")
    p.add_argument("--page-size", type=int, default=1000, help="API page size (max 1000)")

    sub = p.add_subparsers(dest="cmd", required=True)

    a = sub.add_parser("audit", help="Scan files and report largest items")
    a.add_argument("--top", type=int, default=25, help="How many largest files to show")
    a.add_argument("--show-links", action="store_true", help="Print webViewLink for shown items")
    a.add_argument("--csv", default=None, help="Write full file list as CSV")
    a.add_argument("--json", default=None, help="Write full file list as JSON")
    a.set_defaults(func=cmd_audit)

    d = sub.add_parser("duplicates", help="Find duplicate binary files using md5Checksum")
    d.add_argument("--show", type=int, default=10, help="How many duplicate groups to print")
    d.add_argument("--show-per-group", type=int, default=5, help="Items per group to print")
    d.add_argument(
        "--plan-json",
        default=f"gdrive-plan-{now_stamp()}.json",
        help="Write duplicate groups JSON for review (default: timestamped file)",
    )
    d.set_defaults(func=cmd_duplicates)

    t = sub.add_parser(
        "trash",
        help="Move specific file IDs to trash (requires --apply and a confirmation string). Uses batch requests for performance.",
    )
    t.add_argument("--ids-json", required=True, help="JSON file containing {\"fileIds\": [..]}")
    t.add_argument("--apply", action="store_true", help="Actually perform the trash operation")
    t.add_argument("--confirm", required=True, help="Must exactly match: TRASH <n> FILES")
    t.set_defaults(func=cmd_trash)

    tq = sub.add_parser(
        "trash-query",
        help="Move all files matching a query to trash (dry-run by default; requires confirm + --apply). Uses batch requests for performance.",
    )
    tq.add_argument(
        "--name-contains",
        default=None,
        help="Convenience filter: match files where name contains this substring (case-insensitive)",
    )
    tq.add_argument(
        "--include-folders",
        action="store_true",
        help="Include folders (default: exclude folders as a safety measure)",
    )
    tq.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Optional safety limit (0 = no limit)",
    )
    tq.add_argument("--show", type=int, default=25, help="How many matched files to print")
    tq.add_argument("--show-links", action="store_true", help="Print webViewLink for shown items")
    tq.add_argument(
        "--ids-out",
        default=None,
        help="Write matched file IDs as JSON: {\"fileIds\": [..]}",
    )
    tq.add_argument("--apply", action="store_true", help="Actually perform the trash operation")
    tq.add_argument(
        "--confirm",
        default=None,
        help="Must exactly match: TRASH <n> FILES (printed by the dry-run step)",
    )
    tq.set_defaults(func=cmd_trash_query)

    return p


def main(argv: List[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except KeyboardInterrupt:
        eprint("Interrupted.")
        return 130


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
