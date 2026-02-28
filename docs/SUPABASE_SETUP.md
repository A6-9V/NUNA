# Supabase Setup Quick Reference

## Organization Details

- **Organization**: A6-9V
- **Dashboard**: https://supabase.com/dashboard/org/ntjdaoifwrjtcyozomys
- **Password**: See GitHub Repository Secrets

> **Note**: Repository administrators can find the actual password in the
`.supabase-credentials.CONFIDENTIAL` file (not committed to repository).

## Quick Setup

### Step 1: Add GitHub Secret

1. Go to: https://github.com/A6-9V/NUNA/settings/secrets/actions
2. Click **New repository secret**
3. Name: `SUPABASE_PASSWORD`
4. Value: `[Contact repository administrator for password]`
5. Click **Add secret**

### Step 2: Verify Access

Visit the Supabase dashboard at:
https://supabase.com/dashboard/org/ntjdaoifwrjtcyozomys

## Complete Documentation

For comprehensive documentation including:

- Detailed setup instructions
- Security best practices
- GitHub Actions integration examples
- Troubleshooting guide

See:
[guidebook/09_supabase_credentials.md](guidebook/09_supabase_credentials.md)

---

**⚠️ Security Reminder**: Never commit passwords or API keys directly to the repository. Always use GitHub Secrets or environment variables.
