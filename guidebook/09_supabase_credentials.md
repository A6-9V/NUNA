# Supabase Credentials Guide

This guide explains how to manage Supabase credentials for the NUNA project.

## Required Credentials

1. **SUPABASE_URL**: Your project URL.
2. **SUPABASE_ANON_KEY**: Anonymous key for client-side access.
3. **SUPABASE_SERVICE_ROLE_KEY**: Service role key for admin access.

## Setting Up GitHub Secrets

Store these credentials as GitHub Secrets for the repository:

1. Go to Settings > Secrets and variables > Actions.
2. Click "New repository secret".
3. Add the keys mentioned above.

## Security Best Practices

- Never commit the actual service role key to the repository.
- Use environment variables to load keys at runtime.
- Rotate keys regularly if you suspect they have been compromised.
