#!/usr/bin/env python3
"""
Local trading data file manager (safe-by-default).

Goals:
  - Keep reports analysis-ready (CSV -> XLSX)
  - Automatically clean up noisy logs
  - Archive older reports
  - Avoid accidental data loss (dry-run by default; destructive purge requires confirmation)

Default folder layout (under --root, default: ./trading_data):
  logs/          .txt runtime/debug logs (temporary)
  raw_csv/       broker exports / intermediate CSVs
  reports/       final XLSX reports (daily outputs)
  archive/       older reports moved here (organized by YYYY/MM)
  trash/         safety quarantine (moved here instead of deleting)
  automation_logs/  run logs produced by this tool
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import os
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple


DEFAULT_CONFIG: Dict[str, Any] = {
    "paths": {
        "logs_dir": "logs",
        "raw_csv_dir": "raw_csv",
        "reports_dir": "reports",
        "archive_dir": "archive",
        "trash_dir": "trash",
        "run_logs_dir": "automation_logs",
    },
    "retention_days": {
        # Move .txt logs older than this into trash/
        "txt_to_trash": 14,
        # After converting a CSV, move it into trash/ (instead of deleting immediately)
        "csv_to_trash": 14,
        # Move reports older than this into archive/
        "xlsx_to_archive": 90,
        # Permanently delete items inside trash/ older than this (requires confirm)
        "trash_purge": 30,
    },
    "conversion": {
        "csv_to_xlsx": True,
        "sheet_name": "data",
        "delimiter": ",",
        "encoding": "utf-8",
    },
    "reports": {
        # Keep only the newest XLSX per day inside reports/. Older same-day XLSX move to archive/.
        # The "day" is derived from the file's local mtime (no filename convention required).
        "keep_latest_per_day": True,
    },
    # Hard stop safety valve to avoid unexpected mass actions.
    "max_actions_per_run": 500,
}


def eprint(*args: object) -> None:
    print(*args, file=sys.stderr)


def now_local_stamp() -> str:
    # Include microseconds to avoid log filename collisions in fast reruns.
    return dt.datetime.now().strftime("%Y%m%d-%H%M%S-%f")


def load_json_config(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as f:
        payload = json.load(f)
    if not isinstance(payload, dict):
        raise ValueError(f"Config must be a JSON object: {path}")
    return payload


def deep_merge(base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
    out: Dict[str, Any] = dict(base)
    for k, v in override.items():
        if (
            k in out
            and isinstance(out[k], dict)
            and isinstance(v, dict)
        ):
            out[k] = deep_merge(out[k], v)
        else:
            out[k] = v
    return out


def ensure_under_root(root: Path, p: Path) -> None:
    rr = root.resolve()
    rp = p.resolve()
    if not rp.is_relative_to(rr):
        raise ValueError(f"Refusing to operate outside root: {rp} (root={rr})")


def mkdirp(p: Path) -> None:
    p.mkdir(parents=True, exist_ok=True)


def iter_files(p: Path) -> Iterable[Tuple[Path, os.stat_result]]:
    """More efficient Path.iterdir() + stat() for files."""
    try:
        for entry in os.scandir(p):
            if entry.is_file():
                yield (p / entry.name, entry.stat())
    except FileNotFoundError:
        pass


def riter_files(p: Path) -> Iterable[Tuple[Path, os.stat_result]]:
    """More efficient Path.rglob("*") + stat() for files."""
    try:
        for entry in os.scandir(p):
            if entry.is_file():
                yield (p / entry.name, entry.stat())
            elif entry.is_dir():
                yield from riter_files(p / entry.name)
    except FileNotFoundError:
        pass


def file_mtime_local(p: Path, stat: Optional[os.stat_result] = None) -> dt.datetime:
    ts = stat.st_mtime if stat else p.stat().st_mtime
    return dt.datetime.fromtimestamp(ts)


def older_than_days(
    p: Path, *, days: int, now: Optional[dt.datetime] = None, stat: Optional[os.stat_result] = None
) -> bool:
    if days <= 0:
        return False
    now_dt = now or dt.datetime.now()
    age = now_dt - file_mtime_local(p, stat=stat)
    return age.total_seconds() >= days * 86400


def archive_bucket_for(p: Path, stat: Optional[os.stat_result] = None) -> Tuple[str, str]:
    d = file_mtime_local(p, stat=stat)
    return (f"{d.year:04d}", f"{d.month:02d}")


def safe_move(src: Path, dst: Path) -> None:
    mkdirp(dst.parent)
    # Avoid overwriting: if exists, suffix with timestamp.
    if dst.exists():
        dst = dst.with_name(f"{dst.stem}.{now_local_stamp()}{dst.suffix}")
    shutil.move(str(src), str(dst))


def csv_to_xlsx(csv_path: Path, xlsx_path: Path, *, sheet_name: str, delimiter: str, encoding: str) -> None:
    """
    Convert a CSV file to an XLSX file.
    Sanitizes cells starting with =, +, -, or @ to prevent CSV injection (Formula Injection).
    """
    try:
        from openpyxl import Workbook
    except ModuleNotFoundError as ex:
        raise RuntimeError(
            "Missing dependency 'openpyxl'. Install with: pip install openpyxl"
        ) from ex

    mkdirp(xlsx_path.parent)
    tmp_path = xlsx_path.with_suffix(xlsx_path.suffix + ".tmp")

    wb = Workbook(write_only=True)
    ws = wb.create_sheet(title=sheet_name)

    with csv_path.open("r", encoding=encoding, newline="") as f:
        reader = csv.reader(f, delimiter=delimiter)
        for row in reader:
            # Sanitize CSV injection payloads (formula injection)
            safe_row = []
            for cell in row:
                if isinstance(cell, str) and cell.startswith(("=", "+", "-", "@")):
                    safe_row.append("'" + cell)
                else:
                    safe_row.append(cell)
            ws.append(safe_row)

    wb.save(tmp_path)
    tmp_path.replace(xlsx_path)


@dataclass(frozen=True)
class Action:
    kind: str  # "move" | "convert" | "purge"
    src: Optional[Path] = None
    dst: Optional[Path] = None
    detail: str = ""


def write_run_log(log_path: Path, lines: Iterable[str]) -> None:
    mkdirp(log_path.parent)
    with log_path.open("w", encoding="utf-8") as f:
        for line in lines:
            f.write(line.rstrip("\n") + "\n")


def plan_actions(root: Path, cfg: Dict[str, Any]) -> List[Action]:
    paths = cfg["paths"]
    retention = cfg["retention_days"]
    conversion = cfg["conversion"]
    reports_cfg = cfg["reports"]

    logs_dir = root / paths["logs_dir"]
    raw_csv_dir = root / paths["raw_csv_dir"]
    reports_dir = root / paths["reports_dir"]
    archive_dir = root / paths["archive_dir"]
    trash_dir = root / paths["trash_dir"]

    mkdirp(logs_dir)
    mkdirp(raw_csv_dir)
    mkdirp(reports_dir)
    mkdirp(archive_dir)
    mkdirp(trash_dir)

    now = dt.datetime.now()
    actions: List[Action] = []

    # 1) .txt logs -> trash after retention
    txt_days = int(retention.get("txt_to_trash", 0))
    if txt_days > 0:
        for p, p_stat in iter_files(logs_dir):
            if p.suffix == ".txt" and older_than_days(p, days=txt_days, now=now, stat=p_stat):
                actions.append(
                    Action(
                        kind="move",
                        src=p,
                        dst=trash_dir / "logs" / p.name,
                        detail=f"log older than {txt_days}d",
                    )
                )

    # 2) CSV -> XLSX conversion
    if bool(conversion.get("csv_to_xlsx", True)):
        for csv_p, csv_p_stat in iter_files(raw_csv_dir):
            if csv_p.suffix != ".csv":
                continue
            xlsx_p = reports_dir / (csv_p.stem + ".xlsx")
            # Skip if already converted and XLSX is newer than CSV
            if xlsx_p.exists() and xlsx_p.stat().st_mtime >= csv_p_stat.st_mtime:
                continue
            actions.append(
                Action(
                    kind="convert",
                    src=csv_p,
                    dst=xlsx_p,
                    detail="csv -> xlsx",
                )
            )
            # After conversion, move original CSV into trash (safer than delete)
            actions.append(
                Action(
                    kind="move",
                    src=csv_p,
                    dst=trash_dir / "raw_csv" / csv_p.name,
                    detail=f"post-conversion quarantine (keep {int(retention.get('csv_to_trash', 0))}d in trash)",
                )
            )

    # Cache all XLSX file stats once
    xlsx_files: List[Tuple[Path, os.stat_result]] = [
        (p, st) for p, st in iter_files(reports_dir) if p.suffix == ".xlsx"
    ]

    # 3) Keep only latest XLSX per day in reports/
    if bool(reports_cfg.get("keep_latest_per_day", True)):
        by_day: Dict[dt.date, List[Tuple[Path, os.stat_result]]] = {}
        for p, p_stat in xlsx_files:
            day = file_mtime_local(p, stat=p_stat).date()
            by_day.setdefault(day, []).append((p, p_stat))

        for day, files in by_day.items():
            if len(files) <= 1:
                continue
            files_sorted = sorted(files, key=lambda ps: ps[1].st_mtime, reverse=True)
            keep, _ = files_sorted[0]
            for old, old_stat in files_sorted[1:]:
                yyyy, mm = archive_bucket_for(old, stat=old_stat)
                actions.append(
                    Action(
                        kind="move",
                        src=old,
                        dst=archive_dir / yyyy / mm / old.name,
                        detail=f"same-day older report (kept newest: {keep.name})",
                    )
                )

    # 4) Archive reports older than X days (from reports/ only)
    xlsx_days = int(retention.get("xlsx_to_archive", 0))
    if xlsx_days > 0:
        for x, x_stat in xlsx_files:
            if older_than_days(x, days=xlsx_days, now=now, stat=x_stat):
                yyyy, mm = archive_bucket_for(x, stat=x_stat)
                actions.append(
                    Action(
                        kind="move",
                        src=x,
                        dst=archive_dir / yyyy / mm / x.name,
                        detail=f"report older than {xlsx_days}d",
                    )
                )

    # Safety: ensure every action stays within root
    for a in actions:
        if a.src is not None:
            ensure_under_root(root, a.src)
        if a.dst is not None:
            ensure_under_root(root, a.dst)

    return actions


def execute_actions(actions: List[Action], *, cfg: Dict[str, Any], apply: bool) -> Tuple[int, List[str]]:
    max_actions = int(cfg.get("max_actions_per_run", 0) or 0)
    if max_actions > 0 and len(actions) > max_actions:
        raise RuntimeError(
            f"Refusing to run: planned actions ({len(actions)}) exceed max_actions_per_run ({max_actions})."
        )

    conversion = cfg["conversion"]
    sheet_name = str(conversion.get("sheet_name", "data"))
    delimiter = str(conversion.get("delimiter", ","))
    encoding = str(conversion.get("encoding", "utf-8"))

    lines: List[str] = []
    ok = 0
    for a in actions:
        if a.kind == "convert":
            msg = f"CONVERT {a.src} -> {a.dst} ({a.detail})"
            lines.append(msg)
            if apply:
                csv_to_xlsx(a.src, a.dst, sheet_name=sheet_name, delimiter=delimiter, encoding=encoding)
            ok += 1
        elif a.kind == "move":
            msg = f"MOVE {a.src} -> {a.dst} ({a.detail})"
            lines.append(msg)
            if apply:
                safe_move(a.src, a.dst)
            ok += 1
        else:
            raise RuntimeError(f"Unknown action kind: {a.kind}")
    return ok, lines


def plan_purge_actions(root: Path, cfg: Dict[str, Any]) -> List[Action]:
    paths = cfg["paths"]
    retention = cfg["retention_days"]
    trash_dir = root / paths["trash_dir"]
    mkdirp(trash_dir)

    purge_days = int(retention.get("trash_purge", 0))
    if purge_days <= 0:
        return []

    now = dt.datetime.now()
    actions: List[Action] = []
    # Purge files (not directories) older than purge_days. Empty directories are removed at the end.
    # --- OPTIMIZATION: Remove unnecessary sort ---
    # The list of files to be purged does not need to be sorted. Removing the
    # sort avoids a potentially expensive operation on large directories without
    # affecting correctness.
    files_to_check = riter_files(trash_dir)
    for p, p_stat in files_to_check:
        if older_than_days(p, days=purge_days, now=now, stat=p_stat):
            actions.append(Action(kind="purge", src=p, dst=None, detail=f"trash older than {purge_days}d"))

    for a in actions:
        ensure_under_root(root, a.src or trash_dir)
    return actions


def execute_purge(actions: List[Action], *, apply: bool) -> Tuple[int, List[str]]:
    lines: List[str] = []
    ok = 0
    for a in actions:
        if a.kind != "purge" or a.src is None:
            raise RuntimeError("Invalid purge action")
        lines.append(f"PURGE {a.src} ({a.detail})")
        if apply:
            try:
                a.src.unlink()
            except FileNotFoundError:
                pass
        ok += 1
    return ok, lines


def cmd_init(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    cfg_path = Path(args.config).resolve()

    cfg = deep_merge(DEFAULT_CONFIG, load_json_config(cfg_path))
    for k, v in cfg["paths"].items():
        mkdirp(root / v)

    if args.write_example_config:
        example_path = Path(args.write_example_config).resolve()
        if example_path.exists():
            eprint(f"Refusing to overwrite existing file: {example_path}")
            return 2
        with example_path.open("w", encoding="utf-8") as f:
            json.dump(DEFAULT_CONFIG, f, indent=2, sort_keys=True)
            f.write("\n")
        print(f"Wrote example config: {example_path}")

    print(f"Initialized trading data folders under: {root}")
    return 0


def cmd_run(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    cfg_path = Path(args.config).resolve()
    cfg = deep_merge(DEFAULT_CONFIG, load_json_config(cfg_path))

    actions = plan_actions(root, cfg)
    print(f"Planned actions: {len(actions)}")
    if not actions:
        print("Nothing to do.")
        return 0

    # Print a short preview
    show_n = min(int(args.show), len(actions))
    for a in actions[:show_n]:
        if a.kind == "convert":
            print(f"- CONVERT {a.src.name} -> {a.dst.name}")
        elif a.kind == "move":
            print(f"- MOVE {a.src.name} -> {a.dst.relative_to(root)}")

    if not args.apply:
        print("")
        print("Dry-run only. Re-run with --apply to execute non-destructive actions.")

    ok, lines = execute_actions(actions, cfg=cfg, apply=bool(args.apply))

    run_logs_dir = root / cfg["paths"]["run_logs_dir"]
    log_path = run_logs_dir / f"trading-data-manager-{now_local_stamp()}.log"
    write_run_log(log_path, lines)
    print(f"Wrote run log: {log_path}")
    print(f"Actions {'executed' if args.apply else 'planned'}: {ok}")
    return 0


def cmd_purge_trash(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    cfg_path = Path(args.config).resolve()
    cfg = deep_merge(DEFAULT_CONFIG, load_json_config(cfg_path))

    actions = plan_purge_actions(root, cfg)
    n = len(actions)
    print(f"Trash purge candidates: {n}")
    if n == 0:
        print("Nothing to purge.")
        return 0

    expected = f"PURGE {n} FILES"
    print(f"To permanently delete them, re-run with: --confirm \"{expected}\" --apply")
    if args.confirm != expected:
        return 0

    ok, lines = execute_purge(actions, apply=bool(args.apply))
    if not args.apply:
        print("Dry-run only. Re-run with --apply to execute.")
        return 0

    # --- OPTIMIZATION: Efficiently remove empty directories ---
    # To clean up the trash folder, this uses a bottom-up traversal
    # (`os.walk` with `topdown=False`). This is significantly more
    # performant than the previous `rglob` + `sorted` method because it
    # avoids loading the entire directory tree into memory and sorting it.
    # Instead, it visits directories from the deepest level up, attempting
    # to remove them. `os.rmdir` will only succeed if a directory is empty,
    # making this a safe and efficient O(N) operation.
    trash_dir = root / cfg["paths"]["trash_dir"]
    for dirpath, _, _ in os.walk(trash_dir, topdown=False):
        try:
            os.rmdir(dirpath)
        except OSError:
            # Directory is not empty, which is expected.
            pass

    run_logs_dir = root / cfg["paths"]["run_logs_dir"]
    log_path = run_logs_dir / f"trading-data-manager-purge-{now_local_stamp()}.log"
    write_run_log(log_path, lines)
    print(f"Wrote purge log: {log_path}")
    print(f"Purged: {ok}/{n}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="trading_data_manager.py",
        description="Safe local file workflow automation for trading logs and reports.",
    )
    p.add_argument("--root", default="trading_data", help="Root folder containing trading subfolders")
    p.add_argument(
        "--config",
        default="trading_data_config.json",
        help="Optional JSON config path (missing file = defaults)",
    )

    sub = p.add_subparsers(dest="cmd", required=True)

    i = sub.add_parser("init", help="Create the folder structure (and optionally write example config)")
    i.add_argument(
        "--write-example-config",
        default=None,
        help="Write a default config JSON to this path (recommended: trading_data_config.example.json)",
    )
    i.set_defaults(func=cmd_init)

    r = sub.add_parser("run", help="Convert CSV -> XLSX and move old files (dry-run by default)")
    r.add_argument("--apply", action="store_true", help="Execute planned actions (otherwise dry-run)")
    r.add_argument("--show", type=int, default=25, help="How many planned actions to preview")
    r.set_defaults(func=cmd_run)

    pt = sub.add_parser(
        "purge-trash",
        help="Permanently delete old items inside trash/ (requires --confirm and --apply)",
    )
    pt.add_argument("--apply", action="store_true", help="Actually purge (otherwise dry-run)")
    pt.add_argument("--confirm", default=None, help="Must exactly match: PURGE <n> FILES")
    pt.set_defaults(func=cmd_purge_trash)

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

