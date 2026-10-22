Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Starting Public Cloudflare Tunnel for Admin Portal (5173)..." -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Look for the https://*.trycloudflare.com URL below!" -ForegroundColor Green
Write-Host "You can open that URL in any browser on any device!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan

$tunnelExe = Join-Path $PSScriptRoot "tools\cloudflared.exe"
& $tunnelExe tunnel --url http://localhost:5173
