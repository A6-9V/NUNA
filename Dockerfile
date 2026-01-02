FROM mcr.microsoft.com/powershell:7.5-ubuntu-24.04

WORKDIR /repo
COPY . .

# Reduce noise / telemetry in container environments
ENV POWERSHELL_TELEMETRY_OPTOUT=1

# Create an entrypoint script to keep CMD simple and maintainable
RUN mkdir -p /usr/local/bin && \
    cat << 'EOF' > /usr/local/bin/docker-entrypoint.ps1 && \
    chmod +x /usr/local/bin/docker-entrypoint.ps1
Write-Host 'Container ready.'
Write-Host 'This repository is primarily Windows automation (PowerShell 5.1 + admin/UAC).'
Write-Host ''
Write-Host 'If you still want to run a script in the container, specify it explicitly, e.g.:'
Write-Host '  docker run --rm -it <image> pwsh -NoProfile -File ./project-scanner/run-all-projects.ps1 -SkipExecution -SkipConfirmation'
Write-Host ''
Write-Host 'Top-level .ps1 scripts (first 30):'
Get-ChildItem -Path . -Filter '*.ps1' -File |
    Select-Object -First 30 |
    ForEach-Object { '  ' + $_.Name }
EOF

# Default: show a short help message (this repo is primarily Windows automation;
# many scripts won't run meaningfully in a Linux container).
CMD ["pwsh","-NoLogo","-NoProfile","-File","/usr/local/bin/docker-entrypoint.ps1"]

