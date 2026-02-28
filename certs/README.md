# Certificate Management

## Overview
This directory contains SSL/TLS certificates for secure communication.

## Files
- `server.crt`: Public certificate.
- `server.key`: Private key.
- `ca.pem`: Certificate Authority bundle.

## Security
Never commit private keys to the repository. Use Kubernetes Secrets for production.
