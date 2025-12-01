@echo off
echo ==========================================
echo Starting Tracking App
echo ==========================================
echo.
echo Production Backend: https://tracking-app-8rsa.onrender.com
echo.
echo Cleaning previous build...
cd frontend
call flutter clean
echo.
echo Getting dependencies...
call flutter pub get
echo.
echo Running app...
echo.
echo NOTE: First backend request may take 30-60 seconds (cold start)
echo.
call flutter run
