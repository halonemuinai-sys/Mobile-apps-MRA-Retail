Write-Host "Building MPI Advisor Trial APK..." -ForegroundColor Cyan

flutter build apk --flavor trial -t lib/main_trial.dart

if ($LASTEXITCODE -eq 0) {
    $src  = "build\app\outputs\flutter-apk\app-trial-release.apk"
    $dest = "build\app\outputs\flutter-apk\MPI-Advisor-Trial.apk"
    Copy-Item $src $dest -Force
    Write-Host ""
    Write-Host "APK siap: $dest" -ForegroundColor Green
} else {
    Write-Host "Build gagal." -ForegroundColor Red
}
