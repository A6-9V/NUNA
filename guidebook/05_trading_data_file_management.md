# Trading Data File Management (Local Workflow)

This guide describes a clean, automated workflow for managing **trading logs**, **raw exports**, and **final reports** on your local machine. It also documents the included helper script: `trading_data_manager.py`.

## Goals (what “good” looks like)

- **Safe-by-default automation**: preview changes first (dry-run); no surprise deletes.
- **Analysis-ready reports**: raw `.csv` exports are converted to `.xlsx` for Excel/Power BI.
- **Low clutter**: old runtime logs and raw exports are automatically cleaned up.
- **Traceability**: every run produces a log of what it planned/executed.

## Recommended lifecycle and “what to keep”

### 1) Ingest (raw exports)

- **File types**: `.csv` from broker/platform exports
- **Folder**: `raw_csv/`
- **Rule**:
  - Convert to `.xlsx` into `reports/`
  - Then move the source `.csv` to `trash/` (quarantine) instead of immediate deletion

### 2) Report (analysis-ready)

- **File types**: `.xlsx`
- **Folder**: `reports/`
- **Rule**:
  - Keep the newest report per day in `reports/`
  - Move older same-day reports into `archive/` (so you can roll back if needed)

### 3) Archive (long-term history)

- **File types**: `.xlsx`
- **Folder**: `archive/YYYY/MM/`
- **Rule**:
  - Reports older than *N days* (default: 90) are moved into `archive/`

### 4) Logs (temporary)

- **File types**: `.txt`
- **Folder**: `logs/`
- **Rule**:
  - Logs older than *N days* (default: 14) are moved into `trash/`

### 5) Trash (safety quarantine)

- **Folder**: `trash/`
- **Rule**:
  - The tool moves files here instead of deleting them
  - Permanent deletion is a separate step (`purge-trash`) with a confirmation string

## Folder structure

Under a single root directory (default: `./trading_data`):

```text
trading_data/
├─ logs/              # .txt runtime/debug logs
├─ raw_csv/           # CSV exports (broker/platform)
├─ reports/           # Final XLSX reports (latest per day)
├─ archive/           # Archived reports (organized by YYYY/MM)
├─ trash/             # Quarantine (moved here instead of delete)
└─ automation_logs/   # Logs written by the automation runs
```

## Naming conventions (strongly recommended)

Good filenames make automation and auditing much easier:

- **Raw exports**: `trades_<broker>_YYYY-MM-DD.csv`
- **Reports**: `report_YYYY-MM-DD.xlsx`
- **If you create multiple per day**: `report_YYYY-MM-DD_v2.xlsx` (or include a timestamp)

If you don’t use a naming convention, the tool still works; it groups “per day” using the file’s **local modified time**.

## Automation script: `trading_data_manager.py`

### Install dependencies

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

### Initialize folders + write an example config

```bash
python3 trading_data_manager.py init --write-example-config trading_data_config.example.json
```

Create your local config by copying:

```bash
cp trading_data_config.example.json trading_data_config.json
```

(`trading_data_config.json` is ignored by git.)

### Daily run (dry-run first)

```bash
python3 trading_data_manager.py run
```

Apply the planned moves/conversions:

```bash
python3 trading_data_manager.py run --apply
```

### Purge old items from trash (permanent delete)

Dry-run (prints required confirmation):

```bash
python3 trading_data_manager.py purge-trash
```

Apply (must match the printed confirmation string exactly):

```bash
python3 trading_data_manager.py purge-trash --confirm "PURGE <n> FILES" --apply
```

## Scheduling (examples)

### Linux (cron)

Run every day at 6:05am:

```cron
5 6 * * * cd /path/to/repo && /path/to/repo/.venv/bin/python trading_data_manager.py run --apply
```

### Windows (Task Scheduler)

- Program: `python`
- Arguments: `trading_data_manager.py run --apply`
- Start in: repo folder path

## Suggested defaults (tune as you learn)

- **Logs**: move to trash after 14 days
- **Archive**: move reports to archive after 90 days
- **Trash purge**: permanently delete trash after 30 days

These are configurable in `trading_data_config.json`.

