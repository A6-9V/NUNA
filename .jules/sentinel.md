# Sentinel Learnings

## 2025-02-12 - CSV Formula Injection Prevention

**Learning:** When generating CSV files from untrusted data, values starting
with special characters (=, +, -, @) can trigger formula execution in
spreadsheet applications like Excel.

**Action:** Sanitize all cell values that start with formula-triggering
characters by prepending a single quote ('). This ensures they are treated as
literal strings rather than executable formulas.
