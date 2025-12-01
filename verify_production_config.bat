@echo off
echo ==========================================
echo Production Backend Configuration Verification
echo ==========================================
echo.

echo 1. Checking production backend availability...
echo    URL: https://tracking-app-8rsa.onrender.com
echo.

curl -s https://tracking-app-8rsa.onrender.com/
echo.
echo    Check above response for "Tracking backend Running Successfully"
echo.

echo 2. Checking Flutter API configuration...
echo.

findstr /C:"https://tracking-app-8rsa.onrender.com" frontend\lib\services\api_service.dart >nul
if %errorlevel% equ 0 (
    echo    [OK] api_service.dart configured correctly
) else (
    echo    [ERROR] api_service.dart not configured
)

findstr /C:"https://tracking-app-8rsa.onrender.com" frontend\lib\services\background_location_service.dart >nul
if %errorlevel% equ 0 (
    echo    [OK] background_location_service.dart configured correctly
) else (
    echo    [ERROR] background_location_service.dart not configured
)
echo.

echo 3. Checking Android permissions...
findstr /C:"android.permission.INTERNET" frontend\android\app\src\main\AndroidManifest.xml >nul
if %errorlevel% equ 0 (
    echo    [OK] INTERNET permission present
) else (
    echo    [ERROR] INTERNET permission missing
)
echo.

echo ==========================================
echo Configuration Summary
echo ==========================================
echo.
echo Production URL: https://tracking-app-8rsa.onrender.com
echo.
echo Modified Files:
echo   - frontend\lib\services\api_service.dart
echo   - frontend\lib\services\background_location_service.dart
echo   - frontend\README.md
echo.
echo To run the app:
echo   cd frontend
echo   flutter pub get
echo   flutter run
echo.
echo ==========================================
pause
