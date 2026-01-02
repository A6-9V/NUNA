---
description: "Security rules for trading system: broker APIs, credentials, and secure communication"
alwaysApply: false
globs: ["trading-bridge/**/*.py", "trading-bridge/**/*.ps1", "trading-bridge/config/*", "*broker*", "*api*", "*credential*"]
---

# Trading System Security Rules

Security standards for trading system components, broker APIs, and credential management.

## Credential Protection

### API Keys and Secrets
- **NEVER** commit API keys, secrets, or credentials to git
- Store all credentials in Windows Credential Manager
- Use `CredentialManager` class for credential access
- Never log or display credential values
- Use environment variables as fallback only

### Configuration Files
- Actual config files (`brokers.json`, `symbols.json`) must be in `.gitignore`
- Use `.example` files for templates
- Never include real credentials in example files
- Use placeholder values: `"api_key": "YOUR_API_KEY_HERE"`

### Credential Storage Priority
1. Windows Credential Manager (primary)
2. Environment variables (fallback)
3. Encrypted local file (last resort, must be gitignored)

## Broker API Security

### API Key Management
- Each broker API key stored separately
- Use descriptive credential names: `TradingBroker_EXNESS_API_KEY`
- Rotate keys regularly
- Never share keys between environments

### API Communication
- Use HTTPS only for all API calls
- Validate SSL certificates
- Implement request signing if required by broker
- Use rate limiting to prevent abuse

### Error Handling
- Never expose API keys in error messages
- Sanitize error responses before logging
- Don't log full API responses (may contain sensitive data)
- Use generic error messages for users

## Secure Communication

### Python-MQL5 Bridge
- Use ZeroMQ with authentication (if available)
- Or use Named Pipes (Windows-specific, more secure)
- Validate all messages before processing
- Implement message signing/verification

### Network Security
- Use localhost/127.0.0.1 for bridge communication
- Configure firewall rules for trading ports
- Don't expose bridge ports to external networks
- Use VPN for VPS communication if needed

## Code Security

### Input Validation
- Validate all trade signals before processing
- Check symbol names against whitelist
- Validate lot sizes (min/max limits)
- Sanitize all user inputs

### Logging Security
- Never log API keys, secrets, or credentials
- Sanitize logs before writing
- Remove sensitive data from error messages
- Use log levels appropriately (DEBUG may contain more info)

### Code Practices
- Don't hardcode any credentials
- Use constants for non-sensitive config
- Implement proper error handling
- Use type hints for better security

## File Security

### Gitignore Requirements
- `trading-bridge/config/brokers.json`
- `trading-bridge/config/*.key`
- `trading-bridge/config/*.secret`
- `trading-bridge/logs/*.log`
- `trading-bridge/data/*.db`
- Any file containing credentials

### File Permissions
- Restrict config file permissions (user-only read)
- Don't create world-readable files
- Use Windows ACLs for sensitive files
- Lock down log directories

## CredentialManager Usage

### Loading Credentials
```python
from security.credential_manager import CredentialManager

cm = CredentialManager()
api_key = cm.get_credential("EXNESS_API_KEY")
# Never log api_key value
```

### Storing Credentials
```python
cm.store_credential("EXNESS_API_KEY", "actual_key_value")
# Only called during setup, never in production code
```

## Security Checklist

Before committing code:
- [ ] No hardcoded credentials
- [ ] All config files in `.gitignore`
- [ ] Credentials use `CredentialManager`
- [ ] No credentials in logs
- [ ] Input validation implemented
- [ ] Error messages sanitized
- [ ] HTTPS used for all APIs
- [ ] Firewall rules configured

## Security Testing

### Credential Leak Detection
- Run `security-check-trading.ps1` before commits
- Check git history for leaked credentials
- Scan logs for credential patterns
- Verify `.gitignore` is working

### API Security Testing
- Test with invalid credentials
- Verify error messages don't leak info
- Test rate limiting
- Verify SSL certificate validation

## Incident Response

If credentials are exposed:
1. Immediately revoke exposed credentials
2. Generate new API keys
3. Update all systems with new keys
4. Review git history and remove if possible
5. Audit logs for unauthorized access
6. Update security procedures

## References

- See `trading-bridge/SECURITY.md` for detailed security guide
- See `security-check-trading.ps1` for automated checks
- See `.gitignore` for excluded files

