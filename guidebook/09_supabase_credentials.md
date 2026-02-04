# Supabase Credentials and Repository Secrets

This document provides information about the Supabase organization credentials and how to securely manage them using GitHub repository secrets.

## Supabase Organization Details

- **Organization**: A6-9V
- **Organization ID**: ntjdaoifwrjtcyozomys
- **Dashboard URL**: https://supabase.com/dashboard/org/ntjdaoifwrjtcyozomys
- **Password**: Stored securely in GitHub repository secrets (see below)

## Setting Up GitHub Repository Secret

To securely store the Supabase password in GitHub repository secrets, follow these steps:

### Prerequisites

- Repository admin or maintainer access
- Access to the Supabase organization credentials

### Steps to Add Repository Secret

1. Navigate to your GitHub repository: https://github.com/A6-9V/NUNA

2. Click on **Settings** (top menu bar)

3. In the left sidebar, under **Security**, click **Secrets and variables** → **Actions**

4. Click **New repository secret**

5. Add the following secret:
   - **Name**: `SUPABASE_PASSWORD`
   - **Secret**: `Leng3A69V[@Una]`

6. Click **Add secret** to save

### Using the Secret in GitHub Actions

Once the secret is created, you can reference it in your GitHub Actions workflows:

```yaml
steps:
  - name: Use Supabase credentials
    env:
      SUPABASE_PASSWORD: ${{ secrets.SUPABASE_PASSWORD }}
    run: |
      # Your commands here that need the password
      echo "Password is securely stored"
```

### Additional Secrets You May Need

Depending on your Supabase integration needs, you might also want to add:

- `SUPABASE_URL`: Your project's API URL
- `SUPABASE_ANON_KEY`: Public anonymous key
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key (keep highly secure)

## Security Best Practices

### ✅ DO:
- Store all passwords and sensitive credentials in GitHub Secrets
- Rotate passwords regularly
- Use service role keys only in secure environments (GitHub Actions, backend servers)
- Enable two-factor authentication (2FA) on Supabase account
- Limit access to repository secrets to trusted team members only
- Use environment-specific secrets for different deployment stages

### ❌ DON'T:
- Never commit passwords, API keys, or tokens directly to the repository
- Don't share secrets via email, chat, or other insecure channels
- Avoid logging or printing secret values in CI/CD logs
- Don't use production credentials in development/testing environments
- Never expose service role keys in client-side code

## Accessing Supabase Dashboard

To access the Supabase dashboard:

1. Go to https://supabase.com/dashboard/org/ntjdaoifwrjtcyozomys
2. Log in with the organization credentials
3. Use the password stored in GitHub secrets (accessible to authorized team members)

## Revoking or Rotating Credentials

If you need to change the Supabase password:

1. Log into Supabase dashboard
2. Change the password in Supabase account settings
3. Update the `SUPABASE_PASSWORD` secret in GitHub repository settings
4. Notify team members who may need the updated credentials

## Troubleshooting

### Secret Not Available in Workflow

- Ensure the secret name matches exactly (case-sensitive)
- Verify you have the correct permissions
- Check that the workflow has access to secrets (some events like `pull_request` from forks don't)

### Access Denied to Supabase

- Verify the password is correct
- Check if the account requires 2FA
- Ensure the organization hasn't changed access permissions

## Related Documentation

- [Supabase Documentation](https://supabase.com/docs)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [OAuth Setup Guide](06_oauth_setup.md)
- [Quick Start Guide](07_quick_start.md)

---

*Last Updated: 2026-02-04*
