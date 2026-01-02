# Trading Bridge Security Guide

Security best practices for the trading bridge system.

## Credential Protection

### Never Commit Credentials

**CRITICAL**: Never commit API keys, secrets, or credentials to git!

Files that must be gitignored:
- `config/brokers.json`
- `config/symbols.json`
- `config/*.key`
- `config/*.secret`
- `logs/*.log`

### Secure Storage Methods

**1. Windows Credential Manager (Recommended)**

```python
from security.credential_manager import CredentialManager

cm = CredentialManager()
cm.store_credential("EXNESS_API_KEY", "your_key")
api_key = cm.get_credential("EXNESS_API_KEY")
```

**2. Environment Variables**

Set in system environment (not in code):
```powershell
$env:TRADINGBRIDGE_EXNESS_API_KEY = "your_key"
```

**3. Encrypted Files (Last Resort)**

If using files, encrypt them and ensure they're gitignored.

## Code Security

### Input Validation

Always validate inputs before processing:

```python
def validate_signal(signal):
    if not signal.symbol or len(signal.symbol) < 3:
        return False, "Invalid symbol"
    if signal.lot_size <= 0:
        return False, "Invalid lot size"
    return True, None
```

### Error Handling

Never expose sensitive information in error messages:

```python
# BAD
except Exception as e:
    print(f"API key {api_key} failed: {e}")

# GOOD
except Exception as e:
    logger.error("API request failed")
    # Log sanitized error
```

### Log Sanitization

Never log credentials:

```python
# BAD
logger.info(f"Using API key: {api_key}")

# GOOD
logger.info("Using API key: [REDACTED]")
```

## Communication Security

### Bridge Communication

- Use localhost (127.0.0.1) for bridge communication
- Don't expose bridge port to external networks
- Use ZeroMQ authentication if available

### Network Security

- Configure firewall rules for trading ports
- Use VPN for VPS communication
- Don't expose broker APIs to public networks

## File Security

### File Permissions

Restrict config file permissions:

```powershell
# Set user-only read/write
$acl = Get-Acl "config\brokers.json"
$acl.SetAccessRuleProtection($true, $false)
Set-Acl "config\brokers.json" $acl
```

### Git Security

Always verify `.gitignore` includes sensitive files:

```powershell
.\security-check-trading.ps1
```

## API Security

### Rate Limiting

Implement rate limiting to prevent abuse:

```python
class ExnessAPI(BaseBroker):
    def __init__(self, config):
        self.min_request_interval = 0.1  # 100ms
        self.last_request_time = 0
    
    def _rate_limit(self):
        elapsed = time.time() - self.last_request_time
        if elapsed < self.min_request_interval:
            time.sleep(self.min_request_interval - elapsed)
```

### Request Signing

If broker requires request signing, implement it securely:

```python
def _sign_request(self, data):
    # Use API secret for signing
    # Never log the secret
    signature = hmac.new(
        self.api_secret.encode(),
        data.encode(),
        hashlib.sha256
    ).hexdigest()
    return signature
```

## Security Checklist

Before deploying:

- [ ] All credentials in CredentialManager (not in code)
- [ ] All config files in `.gitignore`
- [ ] No credentials in logs
- [ ] Input validation implemented
- [ ] Error messages sanitized
- [ ] Firewall rules configured
- [ ] Bridge port not exposed externally
- [ ] Security check passing: `.\security-check-trading.ps1`

## Incident Response

If credentials are exposed:

1. **Immediately revoke** exposed credentials
2. **Generate new** API keys
3. **Update all systems** with new keys
4. **Review git history** and remove if possible
5. **Audit logs** for unauthorized access
6. **Update security** procedures

## Regular Security Maintenance

### Weekly

- Review logs for suspicious activity
- Check for credential leaks
- Verify firewall rules
- Update dependencies

### Monthly

- Rotate API keys
- Review security procedures
- Audit access logs
- Update security documentation

## Security Tools

### Automated Checks

Run security check regularly:

```powershell
.\security-check-trading.ps1
```

### Manual Verification

1. Check `.gitignore` includes all sensitive files
2. Verify no credentials in git history
3. Check file permissions
4. Review error logs for leaks

## Best Practices

1. **Principle of Least Privilege**: Only grant necessary permissions
2. **Defense in Depth**: Multiple security layers
3. **Fail Secure**: Default to secure state on errors
4. **Regular Updates**: Keep dependencies updated
5. **Monitoring**: Monitor for security events

## References

- See `security-check-trading.ps1` for automated checks
- See `.gitignore` for excluded files
- See `credential_manager.py` for secure storage

