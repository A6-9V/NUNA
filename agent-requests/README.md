## Agent Requests (Auto Request System)

This folder provides a **standard request format** and **scripts** to generate/route work requests to agents (Cursor, GitHub, AMP, Gemini, Qodo, Intelligence Code, Kombai, etc.).

### What you get

- **Schema**: `agent-requests/schema/agent-request.schema.json`
- **Templates**: `agent-requests/templates/*.json`
- **Create requests**: `agent-requests/new-agent-request.ps1`
- **Render to prompt**: `agent-requests/render-agent-request.ps1`
- **Submit to GitHub**: `agent-requests/submit-agent-request.ps1` (creates a GitHub issue via `gh`)

### Quick start (PowerShell)

Create a request (writes JSON + a rendered Markdown prompt):

```powershell
powershell -ExecutionPolicy Bypass -File .\agent-requests\new-agent-request.ps1 `
  -Type debug `
  -Title "Fix startup failure in run-all-auto.ps1" `
  -Paths ".\run-all-auto.ps1", ".\system-setup\complete-setup.ps1" `
  -Instructions "Reproduce, identify root cause, apply fix, and add a short note in the relevant guide."
```

Render an existing request to Markdown:

```powershell
powershell -ExecutionPolicy Bypass -File .\agent-requests\render-agent-request.ps1 `
  -RequestPath ".\agent-requests\inbox\2025-12-19_debug_fix-startup.json"
```

Submit an existing request to GitHub Issues (optional):

```powershell
powershell -ExecutionPolicy Bypass -File .\agent-requests\submit-agent-request.ps1 `
  -RequestPath ".\agent-requests\inbox\2025-12-19_debug_fix-startup.json" `
  -Destination github-issue `
  -Labels "agent-request","debug"
```

### Notes / security

- **Do not put tokens/keys/passwords** into request JSON or prompts.
- Requests are intended to be saved under `agent-requests/inbox/` and outputs under `agent-requests/out/` (both ignored by git).

