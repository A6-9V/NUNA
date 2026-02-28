# SSL/TLS Certificate Setup Guide

This guide explains how to configure and use the Cloudflare SSL/TLS certificates
in the NUNA project.

## Overview

The project includes Cloudflare-managed SSL/TLS certificates for securing HTTPS
connections. These certificates enable encrypted communication between clients
and the NUNA services.

## Certificate Information

- **Provider**: Cloudflare, Inc.
- **Certificate Type**: Managed CA
- **Validity Period**: 10 years (2026-02-05 to 2036-02-03)
- **Key Algorithm**: RSA 2048-bit
- **Purpose**: TLS Web Client Authentication
- **Supported Protocols**: TLSv1.2, TLSv1.3

## Files

The SSL certificates are located in the `certs/` directory:

```bash
certs/
├── README.md                 # Certificate documentation
├── cloudflare-cert.pem       # SSL certificate (public)
└── cloudflare-key.pem        # Private key (sensitive)

```bash

## Quick Start

### 1. Environment Configuration

Copy the SSL configuration from `.env.example` to your `.env` file:

```bash

# SSL/TLS CERTIFICATES

SSL_ENABLED=true
SSL_CERT_PATH=./certs/cloudflare-cert.pem
SSL_KEY_PATH=./certs/cloudflare-key.pem
SSL_PORT=8443
SSL_PROTOCOLS=TLSv1.2,TLSv1.3
SSL_CIPHERS=HIGH:!aNULL:!MD5
SSL_VERIFY_CLIENT=false

```bash

### 2. Verify Certificate Installation

```bash

# Check certificate details

openssl x509 -in certs/cloudflare-cert.pem -noout -text

# Verify certificate dates

openssl x509 -in certs/cloudflare-cert.pem -noout -dates

# Verify certificate and key match

openssl x509 -noout -modulus -in certs/cloudflare-cert.pem | openssl md5
openssl rsa -noout -modulus -in certs/cloudflare-key.pem | openssl md5

```bash

### 3. File Permissions

Ensure proper file permissions are set:

```bash
chmod 644 certs/cloudflare-cert.pem  # Certificate readable by all
chmod 600 certs/cloudflare-key.pem   # Private key owner-only

```bash

## Integration Options

### Option 1: Docker Compose

Update `docker-compose.yml` to mount certificates:

```yaml
services:
  trading-bridge:
    volumes:

      - ./certs:/app/certs:ro
    environment:

      - SSL_ENABLED=${SSL_ENABLED:-false}
      - SSL_CERT_PATH=${SSL_CERT_PATH:-./certs/cloudflare-cert.pem}
      - SSL_KEY_PATH=${SSL_KEY_PATH:-./certs/cloudflare-key.pem}
      - SSL_PORT=${SSL_PORT:-8443}

```bash

### Option 2: Python Application

#### Flask Example

```python
from flask import Flask
import ssl

app = Flask(__name__)

if SSL_ENABLED:
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(
        certfile='certs/cloudflare-cert.pem',
        keyfile='certs/cloudflare-key.pem'
    )
    
    # Or use tuple shorthand

    ssl_context = ('certs/cloudflare-cert.pem', 'certs/cloudflare-key.pem')
    
    app.run(host='0.0.0.0', port=8443, ssl_context=ssl_context)
else:
    app.run(host='0.0.0.0', port=8000)

```bash

#### Django Example

Update `settings.py`:

```python
import os

SSL_ENABLED = os.getenv('SSL_ENABLED', 'false').lower() == 'true'
SSL_CERT_PATH = os.getenv('SSL_CERT_PATH', './certs/cloudflare-cert.pem')
SSL_KEY_PATH = os.getenv('SSL_KEY_PATH', './certs/cloudflare-key.pem')

if SSL_ENABLED:
    SECURE_SSL_REDIRECT = True
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

```bash

Run with:

```bash
gunicorn --certfile=certs/cloudflare-cert.pem \

         --keyfile=certs/cloudflare-key.pem \
         --bind 0.0.0.0:8443 \
         myproject.wsgi:application

```bash

### Option 3: Nginx Reverse Proxy

Create `nginx-ssl.conf`:

```nginx
upstream backend {
    server localhost:8000;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/certs/cloudflare-cert.pem;
    ssl_certificate_key /path/to/certs/cloudflare-key.pem;

    # SSL Configuration

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security headers

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Redirect HTTP to HTTPS

server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

```bash

### Option 4: Apache Configuration

Create SSL virtual host:

```apache
<VirtualHost *:443>
    ServerName your-domain.com
    
    SSLEngine on
    SSLCertificateFile /path/to/certs/cloudflare-cert.pem
    SSLCertificateKeyFile /path/to/certs/cloudflare-key.pem
    
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite HIGH:!aNULL:!MD5
    SSLHonorCipherOrder on
    
    Header always set Strict-Transport-Security "max-age=31536000"
    
    ProxyPass / http://localhost:8000/
    ProxyPassReverse / http://localhost:8000/
</VirtualHost>

<VirtualHost *:80>
    ServerName your-domain.com
    Redirect permanent / https://your-domain.com/
</VirtualHost>

```bash

## Testing SSL Configuration

### Test Local HTTPS Server

```bash

# Start a test HTTPS server with Python

python3 -c "
import ssl
from http.server import HTTPServer, SimpleHTTPRequestHandler

context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain('certs/cloudflare-cert.pem', 'certs/cloudflare-key.pem')

server = HTTPServer(('0.0.0.0', 8443), SimpleHTTPRequestHandler)
server.socket = context.wrap_socket(server.socket, server_side=True)
print('Serving on https://localhost:8443')
server.serve_forever()
"

```bash

### Verify SSL Connection

```bash

# Test SSL connection

curl -v --cacert certs/cloudflare-cert.pem https://localhost:8443

# Or ignore certificate validation (testing only)

curl -k https://localhost:8443

# Use OpenSSL s_client

openssl s_client -connect localhost:8443 -showcerts

# Check SSL certificate details

echo | openssl s_client -connect localhost:8443 2>/dev/null | openssl x509 -noout -text

```bash

### SSL Labs Test

For production environments, test your SSL configuration:

```bash

# Using SSL Labs (requires public domain)

# Visit: https://www.ssllabs.com/ssltest/

# Using testssl.sh

git clone https://github.com/drwetter/testssl.sh.git
cd testssl.sh
./testssl.sh localhost:8443

```bash

## Security Considerations

### ⚠️ Critical Security Notes

1. **Private Key Protection**
   - The `cloudflare-key.pem` contains sensitive cryptographic material
   - File permissions are set to `600` (owner read/write only)
   - Never share or expose the private key publicly
   - Keep backups in secure, encrypted storage

2. **Certificate Validation**

   - This is a Cloudflare-managed certificate
   - Valid for 10 years (until 2036-02-03)
   - Set calendar reminders for renewal before expiration

3. **Production Deployment**

   - Use environment variables for certificate paths
   - Consider using secrets management (e.g., HashiCorp Vault, AWS Secrets Manager)
   - Implement certificate rotation procedures
   - Monitor certificate expiration dates

4. **Access Control**

   - Restrict file system access to certificate files
   - Use appropriate user/group permissions
   - Implement least-privilege principles

5. **Transport Security**

   - Always use TLSv1.2 or higher
   - Disable weak ciphers and protocols
   - Enable HTTP Strict Transport Security (HSTS)
   - Use strong cipher suites

## Monitoring and Maintenance

### Certificate Expiration Monitoring

Set up automated monitoring:

```bash

#!/bin/bash

# check-cert-expiration.sh

CERT_FILE="certs/cloudflare-cert.pem"
DAYS_WARNING=30

EXPIRY_DATE=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))

echo "Certificate expires in $DAYS_LEFT days"

if [ $DAYS_LEFT -lt $DAYS_WARNING ]; then
    echo "WARNING: Certificate expires soon!"

    # Send notification (email, Slack, etc.)

fi

```bash

### Log SSL Errors

Monitor application logs for SSL-related errors:

```bash

# Check for SSL errors in logs

grep -i "ssl\|tls\|certificate" logs/*.log

# Monitor in real-time

tail -f logs/*.log | grep -i "ssl\|tls\|certificate"

```bash

## Troubleshooting

### Common Issues

#### 1. Certificate/Key Mismatch

**Error**: `SSL: error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch`

**Solution**:

```bash

# Verify certificate and key match

openssl x509 -noout -modulus -in certs/cloudflare-cert.pem | openssl md5
openssl rsa -noout -modulus -in certs/cloudflare-key.pem | openssl md5

# Both should output the same hash

```bash

#### 2. Permission Denied

**Error**: `Permission denied: 'certs/cloudflare-key.pem'`

**Solution**:

```bash

# Fix file permissions

chmod 600 certs/cloudflare-key.pem
chown $USER:$USER certs/cloudflare-key.pem

```bash

#### 3. Certificate Not Found

**Error**: `FileNotFoundError: [Errno 2] No such file or directory: 'certs/cloudflare-cert.pem'`

**Solution**:

```bash

# Verify files exist

ls -la certs/

# Check working directory

pwd

# Use absolute paths in configuration

SSL_CERT_PATH=/absolute/path/to/certs/cloudflare-cert.pem

```bash

#### 4. SSL Handshake Failed

**Error**: `SSL: CERTIFICATE_VERIFY_FAILED`

**Solution**:
- Verify certificate chain is complete
- Check system CA certificates are up to date
- For development, may need to add certificate to system trust store

## Certificate Renewal

When approaching certificate expiration:

1. **Request New Certificate**
   - Contact Cloudflare or regenerate through dashboard
   - Obtain new certificate and private key

2. **Backup Old Certificate**

```bash
mv certs/cloudflare-cert.pem certs/cloudflare-cert.pem.old
mv certs/cloudflare-key.pem certs/cloudflare-key.pem.old
```

3. **Install New Certificate**

```bash

   # Copy new files

cp new-cert.pem certs/cloudflare-cert.pem
cp new-key.pem certs/cloudflare-key.pem
   
   # Set permissions

chmod 644 certs/cloudflare-cert.pem
chmod 600 certs/cloudflare-key.pem
```

4. **Restart Services**

```bash

   # Docker

docker-compose restart
   
   # Systemd

sudo systemctl restart your-service
```

5. **Verify New Certificate**

```bash
openssl x509 -in certs/cloudflare-cert.pem -noout -dates
curl -v https://localhost:8443
```

## Best Practices

1. **Automated Certificate Management**
   - Consider using cert-manager for Kubernetes
   - Implement automated renewal processes
   - Set up monitoring and alerting

2. **Secrets Management**

   - Use environment variables for sensitive paths
   - Consider HashiCorp Vault or similar
   - Never commit `.env` files with real paths

3. **Backup Strategy**

   - Keep encrypted backups of certificates and keys
   - Store backups in separate secure location
   - Document backup and recovery procedures

4. **Security Hardening**

   - Disable SSLv3, TLSv1.0, TLSv1.1
   - Use strong cipher suites only
   - Enable Perfect Forward Secrecy (PFS)
   - Implement HSTS headers

5. **Documentation**

   - Document certificate sources
   - Maintain renewal procedures
   - Record configuration changes

## Support and Resources

- **Cloudflare Documentation**: https://developers.cloudflare.com/ssl/
- **OpenSSL Documentation**: https://www.openssl.org/docs/
- **SSL Labs**: https://www.ssllabs.com/
- **Mozilla SSL Configuration Generator**: https://ssl-config.mozilla.org/

For project-specific issues:

- Check `certs/README.md` for certificate details
- Review application logs for SSL errors
- Consult NUNA project documentation

---

**Last Updated**: 2026-02-05  
**Certificate Expiration**: 2036-02-03  
**Next Review Date**: 2036-01-03 (30 days before expiration)
