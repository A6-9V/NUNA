## 2025-02-12 - CSV Formula Injection
**Vulnerability:** Unsanitized CSV input converted to XLSX allowed Excel Formula Injection (e.g. `=cmd|' /C calc'!A0`).
**Learning:** `openpyxl` does not automatically sanitize strings starting with `=`, `+`, `-`, `@`. It writes them as cell values, which Excel interprets as formulas.
**Prevention:** Explicitly check for these prefixes and prepend `'` to force Excel to treat them as text.
