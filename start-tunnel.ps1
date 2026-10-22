Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Starting Public Cloudflare Tunnel for Port 8080..." -ForegroundColor Yellow
Write-Host "Connecting your backend to the global internet..." -ForegroundColor Green
Write-Host "Look for the https://*.trycloudflare.com URL below!" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan
& "$PSScriptRoot\tools\cloudflared.exe" tunnel --url http://localhost:8080
