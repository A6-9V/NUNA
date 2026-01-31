
import unittest
import datetime as dt
from pathlib import Path
import tempfile
import shutil
import json
import os

from common_utils import (
    eprint,
    human_bytes,
    now_stamp,
    now_local_stamp,
    load_json_config,
    deep_merge,
    mkdirp,
    write_json
)

class TestCommonUtils(unittest.TestCase):

    def test_human_bytes(self):
        self.assertEqual(human_bytes(None), "—")
        self.assertEqual(human_bytes(0), "0B")
        self.assertEqual(human_bytes(1023), "1023B")
        self.assertEqual(human_bytes(1024), "1.0KB")
        self.assertEqual(human_bytes(1024 * 1024), "1.0MB")
        self.assertEqual(human_bytes(1024 * 1024 * 1024), "1.0GB")

    def test_now_stamp(self):
        stamp = now_stamp()
        self.assertRegex(stamp, r"^\d{8}-\d{6}Z$")

    def test_now_local_stamp(self):
        stamp = now_local_stamp()
        # Format: %Y%m%d-%H%M%S-%f
        self.assertRegex(stamp, r"^\d{8}-\d{6}-\d{6}$")

    def test_deep_merge(self):
        base = {"a": 1, "b": {"c": 2}}
        override = {"b": {"d": 3}, "e": 4}
        merged = deep_merge(base, override)
        self.assertEqual(merged, {"a": 1, "b": {"c": 2, "d": 3}, "e": 4})

    def test_mkdirp(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            p = Path(tmpdir) / "a" / "b" / "c"
            mkdirp(p)
            self.assertTrue(p.exists())
            self.assertTrue(p.is_dir())

    def test_load_json_config(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            config_path = Path(tmpdir) / "config.json"
            data = {"key": "value"}
            with config_path.open("w", encoding="utf-8") as f:
                json.dump(data, f)

            loaded = load_json_config(config_path)
            self.assertEqual(loaded, data)

            # Test missing file
            self.assertEqual(load_json_config(Path(tmpdir) / "missing.json"), {})

    def test_write_json(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "test.json"
            payload = {"foo": "bar"}
            write_json(path, payload)

            with path.open("r", encoding="utf-8") as f:
                loaded = json.load(f)
            self.assertEqual(loaded, payload)

if __name__ == "__main__":
    unittest.main()
