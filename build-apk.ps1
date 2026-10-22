Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Building Production Android Release APK..." -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan
$env:Path = "C:\src\flutter\bin;" + $env:Path
Set-Location "$PSScriptRoot\mobile-app"
flutter build apk --release
Copy-Item "$PSScriptRoot\mobile-app\build\app\outputs\flutter-apk\app-release.apk" "$PSScriptRoot\Mahima-Tiffin-Centre.apk" -Force
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Success! APK updated at: $PSScriptRoot\Mahima-Tiffin-Centre.apk" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
