# Dockerfile for EXNESS Terminal Support Services
# This container runs supporting services that connect to the native MT5 installation

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY docker/trading-bridge/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy bridge service
COPY bridge/ ./bridge/
COPY config/ ./config/

# Expose ports
EXPOSE 5555 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Start the bridge service
CMD ["python", "-m", "bridge.main"]

