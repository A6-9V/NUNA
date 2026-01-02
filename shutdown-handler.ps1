# Shutdown Handler - Preserves restart flag
$flagFile = "C:\Users\USER\OneDrive\.restart-flag"
New-Item -ItemType File -Path $flagFile -Force | Out-Null
