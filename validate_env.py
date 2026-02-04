#!/usr/bin/env python3
"""
Validate NUNA environment configuration files.

This script checks if all required environment variables are set
and provides helpful feedback for missing or misconfigured values.
"""

import os
import sys
from pathlib import Path

# Required variables by category
REQUIRED_VARS = {
    'vps': [
        'VPS_PROVIDER',
        'VPS_REGION',
        'VPS_NODE',
        'TERMINAL_NAME',
    ],
    'mt5': [
        'MT5_BUILD',
        'MT5_PATH',
        'EA_NAME',
    ],
    'secrets': [
        'GITHUB_TOKEN',
        'DOCKER_TOKEN',
    ],
}

# Placeholder values that should be replaced
PLACEHOLDER_VALUES = [
    'YOUR_TOKEN_HERE',
    'YOUR_FOLDER_ID',
    'YOUR_SHARE_LINK',
    'xxxx',
]


def load_env_file(filepath):
    """Load environment variables from a file."""
    env_vars = {}
    if not filepath.exists():
        return env_vars
    
    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip comments and empty lines
            if not line or line.startswith('#'):
                continue
            # Parse KEY=VALUE
            if '=' in line:
                key, value = line.split('=', 1)
                env_vars[key.strip()] = value.strip()
    
    return env_vars


def check_placeholders(env_vars):
    """Check if any placeholder values are still present."""
    issues = []
    for key, value in env_vars.items():
        for placeholder in PLACEHOLDER_VALUES:
            if placeholder in value:
                issues.append(f"  ⚠️  {key} contains placeholder value: {value}")
    return issues


def validate_config(config_type='combined'):
    """Validate environment configuration."""
    base_dir = Path(__file__).parent
    
    print("=" * 60)
    print("NUNA Environment Configuration Validator")
    print("=" * 60)
    print()
    
    if config_type == 'combined':
        # Check single .env file
        env_file = base_dir / '.env'
        if not env_file.exists():
            print("❌ Error: .env file not found")
            print("   Run: cp .env.example .env")
            return False
        
        print("✓ Found .env file")
        env_vars = load_env_file(env_file)
        
        # Check all required variables
        all_required = []
        for category_vars in REQUIRED_VARS.values():
            all_required.extend(category_vars)
        
        missing = [var for var in all_required if var not in env_vars]
        
    else:
        # Check separate files
        files_to_check = {
            '.env.vps': REQUIRED_VARS['vps'],
            '.env.mt5': REQUIRED_VARS['mt5'],
            '.env.secrets': REQUIRED_VARS['secrets'],
        }
        
        env_vars = {}
        missing = []
        
        for filename, required_vars in files_to_check.items():
            filepath = base_dir / filename
            if not filepath.exists():
                print(f"❌ Error: {filename} not found")
                print(f"   Run: cp {filename}.example {filename}")
                return False
            
            print(f"✓ Found {filename}")
            file_vars = load_env_file(filepath)
            env_vars.update(file_vars)
            
            # Check required variables for this file
            file_missing = [var for var in required_vars if var not in file_vars]
            missing.extend(file_missing)
    
    print()
    print("-" * 60)
    
    # Report results
    if missing:
        print("❌ Missing required variables:")
        for var in missing:
            print(f"  • {var}")
        print()
        status = False
    else:
        print("✅ All required variables are present")
        print()
        status = True
    
    # Check for placeholder values
    placeholder_issues = check_placeholders(env_vars)
    if placeholder_issues:
        print("⚠️  Warning: Found placeholder values that should be replaced:")
        for issue in placeholder_issues:
            print(issue)
        print()
    
    # Summary
    print("-" * 60)
    if status and not placeholder_issues:
        print("✅ Configuration validation passed!")
        print("   Your environment is ready to use.")
    elif status:
        print("⚠️  Configuration validation passed with warnings")
        print("   Please replace placeholder values with actual credentials.")
    else:
        print("❌ Configuration validation failed")
        print("   Please fix the issues above and run again.")
    
    print()
    return status and not placeholder_issues


def main():
    """Main entry point."""
    # Check if using separate files or combined
    base_dir = Path(__file__).parent
    
    # Check which configuration style is being used
    has_separate = (
        (base_dir / '.env.vps').exists() or
        (base_dir / '.env.mt5').exists() or
        (base_dir / '.env.secrets').exists()
    )
    has_combined = (base_dir / '.env').exists()
    
    if has_separate and not has_combined:
        print("Detected: Separate configuration files")
        success = validate_config('separate')
    elif has_combined:
        print("Detected: Combined configuration file")
        success = validate_config('combined')
    else:
        print("❌ No configuration files found!")
        print()
        print("Please create your configuration files:")
        print("  Option 1 (Separate): cp .env.*.example to .env.*")
        print("  Option 2 (Combined): cp .env.example .env")
        print()
        print("See ENV_CONFIG.md for detailed instructions.")
        return 1
    
    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())
