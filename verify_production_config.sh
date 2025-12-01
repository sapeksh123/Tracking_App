#!/bin/bash

echo "=========================================="
echo "Production Backend Configuration Verification"
echo "=========================================="
echo ""

echo "1. Checking production backend availability..."
echo "   URL: https://tracking-app-8rsa.onrender.com"
echo ""

# Test backend connection
response=$(curl -s https://tracking-app-8rsa.onrender.com/)
if [[ $response == *"Tracking backend Running Successfully"* ]]; then
    echo "   ✅ Backend is ONLINE and responding"
else
    echo "   ❌ Backend is not responding correctly"
fi
echo ""

echo "2. Checking Flutter API configuration..."
echo ""

# Check api_service.dart
if grep -q "https://tracking-app-8rsa.onrender.com" frontend/lib/services/api_service.dart; then
    echo "   ✅ api_service.dart configured correctly"
else
    echo "   ❌ api_service.dart not configured"
fi

# Check background_location_service.dart
if grep -q "https://tracking-app-8rsa.onrender.com" frontend/lib/services/background_location_service.dart; then
    echo "   ✅ background_location_service.dart configured correctly"
else
    echo "   ❌ background_location_service.dart not configured"
fi
echo ""

echo "3. Checking Android permissions..."
if grep -q "android.permission.INTERNET" frontend/android/app/src/main/AndroidManifest.xml; then
    echo "   ✅ INTERNET permission present"
else
    echo "   ❌ INTERNET permission missing"
fi
echo ""

echo "=========================================="
echo "Configuration Summary"
echo "=========================================="
echo ""
echo "Production URL: https://tracking-app-8rsa.onrender.com"
echo ""
echo "Modified Files:"
echo "  - frontend/lib/services/api_service.dart"
echo "  - frontend/lib/services/background_location_service.dart"
echo "  - frontend/README.md"
echo ""
echo "To run the app:"
echo "  cd frontend"
echo "  flutter pub get"
echo "  flutter run"
echo ""
echo "=========================================="
