# Cursor Rules Setup

This document explains the Cursor rules configuration for this project.

## Overview

Cursor rules provide persistent, reusable context for the AI assistant. They help ensure consistent code generation, style, and best practices across the project.

## Rule Structure

Rules are organized in `.cursor/rules/` directory, with each rule in its own folder containing a `RULE.md` file.

## Project Rules Created

### 1. PowerShell Standards (`powershell-standards`)
- **Type**: Apply to Specific Files (`*.ps1`)
- **Purpose**: Defines PowerShell coding standards and best practices
- **Covers**: Code style, error handling, output formatting, script structure

### 2. System Configuration (`system-configuration`)
- **Type**: Always Apply
- **Purpose**: Provides system-specific information for NuNa device
- **Covers**: Device specs, system paths, PowerShell configuration, GitHub Desktop paths

### 3. Automation Patterns (`automation-patterns`)
- **Type**: Apply to Specific Files (`auto-*.ps1`, `run-all-auto.ps1`)
- **Purpose**: Defines automation patterns and intelligent defaults
- **Covers**: Windows setup automation, git operations, cloud services, error handling

### 4. Security Tokens (`security-tokens`)
- **Type**: Apply to Specific Files (`*git*.ps1`, `*credentials*`, `.gitignore`)
- **Purpose**: Security rules for handling GitHub tokens and credentials
- **Covers**: Token security, credential management, best practices

### 5. GitHub Desktop Integration (`github-desktop-integration`)
- **Type**: Apply to Specific Files (`*github-desktop*.ps1`)
- **Purpose**: Rules for GitHub Desktop integration and update checking
- **Covers**: Installation detection, version checking, settings, release notes

## AGENTS.md

A simple markdown file in the project root that provides general instructions for the Cursor agent. This is an alternative to structured rules for straightforward use cases.

## How Rules Work

1. **Always Apply**: Rules that are always included in AI context (e.g., system configuration)
2. **Apply Intelligently**: Rules applied when AI determines they're relevant based on description
3. **Apply to Specific Files**: Rules applied when working with matching file patterns
4. **Apply Manually**: Rules applied when @-mentioned in chat (e.g., `@powershell-standards`)

## Viewing and Managing Rules

1. Open **Cursor Settings → Rules, Commands**
2. View all project rules and their status
3. Enable/disable rules as needed
4. Create new rules using "New Cursor Rule" command

## Rule Precedence

Rules are applied in this order:
1. **Team Rules** (if applicable)
2. **Project Rules** (`.cursor/rules/`)
3. **User Rules** (global Cursor settings)
4. **AGENTS.md** (project root)

## Best Practices

- Keep rules focused and under 500 lines
- Split large rules into multiple, composable rules
- Provide concrete examples in rules
- Reference actual files using `@filename.ps1` syntax
- Update rules when patterns change

## References

- [Cursor Rules Documentation](https://cursor.com/docs/context/rules)
- `AUTOMATION-RULES.md` - Automation patterns
- `SYSTEM-INFO.md` - System specifications
- `GITHUB-DESKTOP-RULES.md` - GitHub Desktop integration

---

**Created**: 2025-12-09
**System**: NuNa (Windows 11 Home Single Language 25H2)
