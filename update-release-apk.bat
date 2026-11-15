@echo off
echo ========================================================
echo   BUOY ERP - 1-Click Release APK Compiler & Web Sync
echo ========================================================
echo.

echo [1/4] Running Flutter Clean & Getting Dependencies...
call flutter clean
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Flutter pub get failed.
    pause
    exit /b %errorlevel%
)

echo.
echo [2/4] Building Production Release APK...
call flutter build apk --release --no-tree-shake-icons
if %errorlevel% neq 0 (
    echo [ERROR] Flutter build apk failed.
    pause
    exit /b %errorlevel%
)

echo.
echo [3/4] Copying fresh APK to web/download/buoy-erp.apk...
if not exist "web\download" mkdir "web\download"
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "web\download\buoy-erp.apk"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to copy APK to web/download.
    pause
    exit /b %errorlevel%
)

echo.
echo [4/4] Syncing to Git repository...
git add web/download/buoy-erp.apk
git commit -m "chore(release): update latest buoy-erp.apk web download binary"
git push origin main

echo.
echo ========================================================
echo   SUCCESS! Release APK updated and published.
echo   Users downloading from the web will get this build!
echo ========================================================
pause

