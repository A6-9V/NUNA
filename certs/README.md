# SSL/TLS Certificates

This directory contains SSL/TLS certificates for securing HTTPS connections.

## Contents

- **cloudflare-cert.pem** - Cloudflare-managed SSL certificate
- **cloudflare-key.pem** - Private key for the SSL certificate

## Certificate Details

- **Issuer**: Cloudflare, Inc. (Managed CA)
- **Subject**: Cloudflare
- **Valid From**: February 5, 2026
- **Valid Until**: February 3, 2036
- **Key Type**: RSA 2048-bit
- **Purpose**: TLS Web Client Authentication

## Usage

### Docker Compose

To use these certificates in Docker services, mount them as volumes:

```yaml
services:
  web:
    volumes:
      - ./certs/cloudflare-cert.pem:/etc/ssl/certs/server.crt:ro
      - ./certs/cloudflare-key.pem:/etc/ssl/private/server.key:ro
    environment:
      - SSL_CERT_PATH=/etc/ssl/certs/server.crt
      - SSL_KEY_PATH=/etc/ssl/private/server.key
```

### Environment Variables

Add these to your `.env` file:

```bash
# SSL/TLS Configuration
SSL_ENABLED=true
SSL_CERT_PATH=./certs/cloudflare-cert.pem
SSL_KEY_PATH=./certs/cloudflare-key.pem
```

### Nginx Configuration

Example Nginx SSL configuration:

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /path/to/certs/cloudflare-cert.pem;
    ssl_certificate_key /path/to/certs/cloudflare-key.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # ... rest of your configuration
}
```

### Python (Flask/Django)

```python
import ssl

context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain('certs/cloudflare-cert.pem', 'certs/cloudflare-key.pem')

# Flask
app.run(ssl_context=context, host='0.0.0.0', port=8443)

# Or provide paths directly
app.run(ssl_context=('certs/cloudflare-cert.pem', 'certs/cloudflare-key.pem'))
```

## Security Best Practices

### ⚠️ Important Security Notes

1. **Private Key Protection**
   - The `cloudflare-key.pem` file contains sensitive cryptographic material
   - Never commit private keys to public repositories
   - Restrict file permissions: `chmod 600 cloudflare-key.pem`
   - Consider using environment variables or secrets management for production

2. **Certificate Rotation**
   - Monitor certificate expiration dates
   - Current certificate expires: **February 3, 2036**
   - Set up automated renewal or reminders before expiration

3. **Access Control**
   - Limit access to certificate files to necessary users/services only
   - Use file permissions to restrict read access:
     ```bash
     chmod 644 cloudflare-cert.pem  # Certificate can be world-readable
     chmod 600 cloudflare-key.pem   # Private key should be owner-only
     ```

4. **Backup**
   - Keep secure backups of both certificate and private key
   - Store backups in encrypted form
   - Document the location of backups

5. **Monitoring**
   - Monitor SSL/TLS connections for issues
   - Set up alerts for certificate expiration
   - Regularly verify certificate validity

## Verification Commands

### Verify Certificate

```bash
# Display certificate details
openssl x509 -in cloudflare-cert.pem -noout -text

# Check certificate dates
openssl x509 -in cloudflare-cert.pem -noout -dates

# Verify certificate and key match
openssl x509 -noout -modulus -in cloudflare-cert.pem | openssl md5
openssl rsa -noout -modulus -in cloudflare-key.pem | openssl md5
# Both should produce the same MD5 hash
```

### Test SSL Connection

```bash
# Test HTTPS connection (if server is running)
openssl s_client -connect localhost:443 -showcerts

# Verify certificate chain
openssl verify -CAfile /path/to/ca-bundle.crt cloudflare-cert.pem
```

## Troubleshooting

### Certificate/Key Mismatch

If you encounter errors about certificate and key not matching:

```bash
# Extract modulus from certificate
openssl x509 -noout -modulus -in cloudflare-cert.pem | openssl md5

# Extract modulus from private key
openssl rsa -noout -modulus -in cloudflare-key.pem | openssl md5

# Compare the MD5 hashes - they should match
```

### Permission Errors

If you get permission denied errors:

```bash
# Fix certificate permissions
chmod 644 cloudflare-cert.pem

# Fix private key permissions (owner read-only)
chmod 600 cloudflare-key.pem

# Ensure correct ownership
chown $USER:$USER cloudflare-*.pem
```

### Certificate Expiration

Check when the certificate expires:

```bash
openssl x509 -in cloudflare-cert.pem -noout -enddate
```

## Renewal Process

When the certificate approaches expiration:

1. Obtain new certificate from Cloudflare
2. Backup old certificate and key
3. Replace files in this directory
4. Restart services using the certificates
5. Verify new certificate is being used
6. Test SSL/TLS connections

## Support

For issues related to:
- **Certificate generation**: Contact Cloudflare support
- **Certificate installation**: Refer to your application's SSL documentation
- **Certificate errors**: Check logs and verify certificate/key files

---

**Last Updated**: 2026-02-05  
**Certificate Expiration**: 2036-02-03  
**Certificate Type**: Cloudflare Managed CA
