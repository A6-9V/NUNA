# Project Discovery & Execution System

A comprehensive PowerShell-based system that scans all local drives, discovers development projects, applications, and scripts, collects file listings, and executes them in the background.

## 🚀 Quick Start

### Run Complete System
```powershell
cd D:\my-drive-projects\project-scanner
.\run-all-projects.ps1
```

### Run Individual Components
```powershell
# Just discover projects
.\project-scanner.ps1

# Just execute discovered projects
.\project-executor.ps1
```

## 📁 System Components

### 1. `project-scanner.ps1`
**Purpose**: Scans all local drives to discover projects, applications, and scripts

**Features**:
- Scans all local drives (C:, D:, E:, F:, G:, etc.)
- Identifies development projects by markers:
  - Node.js: `package.json`
  - Python: `requirements.txt`, `setup.py`, `pyproject.toml`
  - Java: `pom.xml`, `build.gradle`
  - Rust: `Cargo.toml`
  - .NET: `*.sln`, `*.csproj`
  - Go: `go.mod`
- Finds scripts: `.bat`, `.ps1`, `.sh`, `.cmd`, `.vbs`
- Collects file listings for each project
- Exports results to JSON

**Usage**:
```powershell
.\project-scanner.ps1 -ConfigPath "scanner-config.json" -OutputPath "discovered-projects.json" -Verbose
```

### 2. `project-executor.ps1`
**Purpose**: Executes discovered projects in background using PowerShell jobs

**Features**:
- Reads discovered projects from JSON
- Executes projects in background (PowerShell jobs)
- Handles different project types with appropriate commands
- Rate limiting and timeout handling
- Tracks execution status

**Usage**:
```powershell
.\project-executor.ps1 -ProjectsFile "discovered-projects.json" -SkipConfirmation
```

### 3. `project-logger.ps1`
**Purpose**: Comprehensive logging system

**Features**:
- Timestamped log files
- Color-coded console output
- Execution logging
- Summary generation

### 4. `run-all-projects.ps1`
**Purpose**: Main orchestrator that runs the complete workflow

**Features**:
- Runs discovery scan
- Displays discovered projects summary
- Executes projects in background
- Generates summary reports

**Usage**:
```powershell
.\run-all-projects.ps1 -SkipConfirmation -Verbose
```

### 5. `scanner-config.json`
**Purpose**: Configuration file with all settings

**Configuration Options**:
- Excluded directories (Windows system folders, node_modules, etc.)
- Project type patterns and execution commands
- Script extensions to detect
- Application paths to scan
- Scan depth and execution limits

## 📊 Output Files

- `discovered-projects.json` - All discovered projects with file listings
- `execution-summary.json` - Execution status summary
- `log-summary.txt` - Log statistics
- `logs/` - Timestamped log files

## 🔒 Safety Features

- Excludes Windows system directories
- Excludes Program Files system applications
- Confirmation prompts before execution (can be skipped with `-SkipConfirmation`)
- Rate limiting for executions
- Comprehensive logging for audit trail
- Timeout handling for long-running jobs

## 🎯 Use Cases

1. **Project Discovery**: Find all development projects across all drives
2. **Automated Execution**: Run all projects in background
3. **Project Inventory**: Generate comprehensive list of all projects
4. **Drive Management**: Understand what's on each drive

## 📝 Configuration

Edit `scanner-config.json` to customize:
- Which directories to exclude
- Project type detection patterns
- Execution commands per project type
- Scan depth limits
- Concurrent job limits

## 🔧 Troubleshooting

### No Projects Found
- Check excluded directories in config
- Verify scan depth settings
- Run with `-Verbose` flag for detailed output

### Execution Failures
- Check execution logs in `logs/` directory
- Verify project paths exist
- Check execution commands in config

### Performance Issues
- Reduce `maxDepth` in scan settings
- Lower `maxConcurrentJobs` in execution settings
- Exclude more directories in config

## 📈 Performance

- **Scan Speed**: ~140-250 seconds for full multi-drive scan
- **Directories Scanned**: 6,000+ directories
- **Projects Discovered**: Varies by system (typically 100-1000+)
- **Execution**: Background jobs with configurable concurrency

## 🔄 Integration

This system integrates with:
- **Storage Management Suite**: Located in `../storage-management/`
- **Domain Controller**: Can be deployed to `G:\DomainController`
- **Multi-Drive Workspace**: Designed for systems with multiple drives

## 📚 Related Documentation

- See main repository README.md
- Storage Management: `../storage-management/README.md`
- Domain Controller: `G:\DomainController\README.md` (if deployed)

---

*Created: November 27, 2025*  
*Designed for Windows 11 with PowerShell 5.1+*  
*Part of A6-9V Organization Project Management Suite*

