# Web Research Service - Perplexity AI Finance Research
$ErrorActionPreference = "Continue"
$workspaceRoot = "C:\Users\USER\OneDrive"
$logsPath = "C:\Users\USER\OneDrive\vps-logs"

function Start-PerplexityResearch {
    param(
        [string]$query = "finance trading market analysis"
    )
    
    $firefoxPath = Get-Command firefox -ErrorAction SilentlyContinue
    if (-not $firefoxPath) {
        $firefoxPaths = @(
            "C:\Program Files\Mozilla Firefox\firefox.exe",
            "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
        )
        foreach ($path in $firefoxPaths) {
            if (Test-Path $path) {
                $firefoxPath = $path
                break
            }
        }
    } else {
        $firefoxPath = $firefoxPath.Source
    }
    
    if ($firefoxPath) {
        $url = "https://www.perplexity.ai/finance?q=" + [System.Web.HttpUtility]::UrlEncode($query)
        Start-Process -FilePath $firefoxPath -ArgumentList $url
        Write-Host "[$(Get-Date)] Started Perplexity research: $query" | Out-File -Append "$logsPath\research-service.log"
    }
}

# Research schedule (every 6 hours)
while ($true) {
    $queries = @(
        "forex market analysis today",
        "trading opportunities EURUSD",
        "cryptocurrency market trends",
        "stock market analysis",
        "economic calendar events"
    )
    
    foreach ($query in $queries) {
        Start-PerplexityResearch -Query $query
        Start-Sleep -Seconds 3600  # Wait 1 hour between queries
    }
    
    Start-Sleep -Seconds 21600  # Wait 6 hours before next cycle
}
