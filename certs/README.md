# SSL/TLS Certificates

This directory stores SSL/TLS certificates and private keys used for secure
communication with the Trading Bridge service.

## Security Notice

**IMPORTANT**: Private keys (`.pem`, `.key`) must never be committed to
version control.

## Files

- `cloudflare-cert.pem`: Cloudflare Origin CA certificate.
- `cloudflare-key.pem`: Cloudflare Origin CA private key (placeholder).

## Verification

- **Certificate generation**: Use OpenSSL to generate self-signed certificates
  for development.
- **Key management**: Keys are managed via environment variables in production.
