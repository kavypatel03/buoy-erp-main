@echo off
echo ========================================================
echo   BUOY ERP - 1-Click Release APK Compiler & Web Sync
echo ========================================================
echo.

echo [1/5] Auto-incrementing App Version & Build Number...
call node scripts/auto_increment_version.js
if %errorlevel% neq 0 (
    echo [WARNING] Node auto-increment script skipped or failed. Continuing with existing version...
)

echo.
echo [2/5] Running Flutter Clean & Getting Dependencies...
call flutter clean
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Flutter pub get failed.
    pause
    exit /b %errorlevel%
)

echo.
echo [3/5] Building Production Release APK...
call flutter build apk --release --no-tree-shake-icons
if %errorlevel% neq 0 (
    echo [ERROR] Flutter build apk failed.
    pause
    exit /b %errorlevel%
)

echo.
echo [4/5] Copying fresh APK to web/download/buoy-erp.apk...
if not exist "web\download" mkdir "web\download"
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "web\download\buoy-erp.apk"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to copy APK to web/download.
    pause
    exit /b %errorlevel%
)

echo.
echo [5/5] Syncing updated APK & new Version to Git...
git add pubspec.yaml lib/app/constants/app_constants.dart web/download/buoy-erp.apk
git commit -m "chore(release): auto-increment app version and update release APK"
git push origin main

echo.
echo ========================================================
echo   SUCCESS! Release APK updated and published.
echo   Users downloading from the web will get this build!
echo ========================================================
pause

