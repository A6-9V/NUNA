
import unittest
import os
import shutil
import tempfile
import time
from pathlib import Path
from unittest.mock import patch

import trading_data_manager as tdm


class TestTradingDataManager(unittest.TestCase):

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.root = Path(self.test_dir) / "trading_data"
        self.logs_dir = self.root / "logs"
        self.raw_csv_dir = self.root / "raw_csv"
        self.reports_dir = self.root / "reports"
        self.archive_dir = self.root / "archive"
        self.trash_dir = self.root / "trash"

        self.cfg = tdm.DEFAULT_CONFIG
        self.cfg["paths"] = {
            "logs_dir": self.logs_dir.relative_to(self.root),
            "raw_csv_dir": self.raw_csv_dir.relative_to(self.root),
            "reports_dir": self.reports_dir.relative_to(self.root),
            "archive_dir": self.archive_dir.relative_to(self.root),
            "trash_dir": self.trash_dir.relative_to(self.root),
            "run_logs_dir": "automation_logs",
        }

        tdm.mkdirp(self.logs_dir)
        tdm.mkdirp(self.raw_csv_dir)
        tdm.mkdirp(self.reports_dir)
        tdm.mkdirp(self.archive_dir)
        tdm.mkdirp(self.trash_dir)

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_iter_files(self):
        # Create some files and directories
        (self.logs_dir / "log1.txt").touch()
        (self.logs_dir / "log2.txt").touch()
        (self.logs_dir / "subdir").mkdir()
        (self.logs_dir / "subdir" / "log3.txt").touch()

        files = list(tdm.iter_files(self.logs_dir))
        self.assertEqual(len(files), 2)
        self.assertEqual({p.name for p, s in files}, {"log1.txt", "log2.txt"})

    def test_riter_files(self):
        # Create some files and directories
        (self.logs_dir / "log1.txt").touch()
        (self.logs_dir / "subdir").mkdir()
        (self.logs_dir / "subdir" / "log2.txt").touch()

        files = list(tdm.riter_files(self.logs_dir))
        self.assertEqual(len(files), 2)
        self.assertEqual({p.name for p, s in files}, {"log1.txt", "log2.txt"})

    def test_plan_actions_txt_retention(self):
        # Create an old log file
        old_log = self.logs_dir / "old.txt"
        old_log.touch()
        os.utime(old_log, (time.time() - 15 * 86400, time.time() - 15 * 86400))

        # Create a new log file
        (self.logs_dir / "new.txt").touch()

        self.cfg["retention_days"]["txt_to_trash"] = 14
        actions = tdm.plan_actions(self.root, self.cfg)

        self.assertEqual(len(actions), 1)
        self.assertEqual(actions[0].kind, "move")
        self.assertEqual(actions[0].src, old_log)

    def test_plan_purge_actions(self):
        # Create an old file in the trash
        old_file = self.trash_dir / "old_file.txt"
        old_file.touch()
        os.utime(old_file, (time.time() - 31 * 86400, time.time() - 31 * 86400))

        # Create a new file in the trash
        (self.trash_dir / "new_file.txt").touch()

        self.cfg["retention_days"]["trash_purge"] = 30
        actions = tdm.plan_purge_actions(self.root, self.cfg)

        self.assertEqual(len(actions), 1)
        self.assertEqual(actions[0].kind, "purge")
        self.assertEqual(actions[0].src, old_file)

    def test_plan_actions_csv_to_xlsx(self):
        # Create a CSV file
        (self.raw_csv_dir / "data.csv").touch()

        # Ensure config has csv_to_xlsx = True
        self.cfg["conversion"]["csv_to_xlsx"] = True

        actions = tdm.plan_actions(self.root, self.cfg)

        # Expect 2 actions: convert csv->xlsx, and move csv->trash
        self.assertEqual(len(actions), 2)

        convert_action = actions[0]
        self.assertEqual(convert_action.kind, "convert")
        self.assertEqual(convert_action.src, self.raw_csv_dir / "data.csv")
        self.assertEqual(convert_action.dst, self.reports_dir / "data.xlsx")

        move_action = actions[1]
        self.assertEqual(move_action.kind, "move")
        self.assertEqual(move_action.src, self.raw_csv_dir / "data.csv")
        self.assertEqual(move_action.dst, self.trash_dir / "raw_csv" / "data.csv")

    def test_plan_actions_keep_latest_per_day(self):
        # Create two XLSX files for the same day
        p1 = self.reports_dir / "report_old.xlsx"
        p2 = self.reports_dir / "report_new.xlsx"
        p1.touch()
        p2.touch()

        # Set mtimes so p1 is older than p2, but same day
        base_time = 1600000000.0  # 2020-09-13 around 12:26 UTC
        os.utime(p1, (base_time, base_time))
        os.utime(p2, (base_time + 3600, base_time + 3600))

        self.cfg["reports"]["keep_latest_per_day"] = True
        self.cfg["retention_days"]["xlsx_to_archive"] = 0

        actions = tdm.plan_actions(self.root, self.cfg)

        # Expect 1 action: move p1 to archive
        self.assertEqual(len(actions), 1)
        self.assertEqual(actions[0].kind, "move")
        self.assertEqual(actions[0].src, p1)
        self.assertTrue(str(actions[0].dst).startswith(str(self.archive_dir)))


if __name__ == "__main__":
    unittest.main()
