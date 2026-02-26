"""
Common utility functions for the Google Drive cleanup and trading data tools.
"""

from __future__ import annotations

import datetime as dt
import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, Optional


def eprint(*args: object) -> None:
    """Print to stderr."""
    print(*args, file=sys.stderr)


def human_bytes(n: Optional[int]) -> str:
    """Format bytes into a human-readable string (KB, MB, GB, etc.)."""
    if n is None:
        return "—"
    units = ["B", "KB", "MB", "GB", "TB", "PB"]
    x = float(n)
    for u in units:
        if x < 1024 or u == units[-1]:
            return f"{x:.1f}{u}" if u != "B" else f"{int(x)}B"
        x /= 1024
    return f"{n}B"


def now_stamp() -> str:
    """Get a UTC timestamp string (filesystem-safe)."""
    return dt.datetime.now(dt.timezone.utc).strftime("%Y%m%d-%H%M%SZ")


def now_local_stamp() -> str:
    """Get a local timestamp string including microseconds (filesystem-safe)."""
    return dt.datetime.now().strftime("%Y%m%d-%H%M%S-%f")


def load_json_config(path: Path) -> Dict[str, Any]:
    """Load a JSON configuration file."""
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as f:
        payload = json.load(f)
    if not isinstance(payload, dict):
        raise ValueError(f"Config must be a JSON object: {path}")
    return payload


def deep_merge(base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
    """Recursively merge two dictionaries."""
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


def mkdirp(p: Path) -> None:
    """Create directory and its parents if they don't exist."""
    # Optimization: Avoid the overhead of mkdir() if the directory already exists.
    # This is safe because mkdir(parents=True, exist_ok=True) also fails if 'p' exists as a file.
    if not p.is_dir():
        p.mkdir(parents=True, exist_ok=True)


def write_json(path: str | Path, payload: Any) -> None:
    """Write a payload to a JSON file."""
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, sort_keys=True)
