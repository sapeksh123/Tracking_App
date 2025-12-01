# Android 12+ Foreground Service Fix

## Issue
The app was crashing on Android 12+ devices with:
```
ForegroundServiceStartNotAllowedException: startForegroundService() not allowed
```

## Root Cause
Android 12 (API 31) and above restrict starting foreground services from the background. The boot receiver was trying to start the background location service when the device booted, which is not allowed.

## Solution Applied

### 1. Disabled Auto-Start on Boot
Changed `autoStartOnBoot` from `true` to `false` in `background_location_service.dart`:

```dart
autoStartOnBoot: false, // Disabled to prevent Android 12+ crash
```

### 2. Removed Boot Permission
Removed `RECEIVE_BOOT_COMPLETED` permission from `AndroidManifest.xml` since we're not using auto-start anymore.

## Impact

### What Still Works:
- ✅ Background location tracking when user punches in
- ✅ Foreground service runs while app is active
- ✅ Location updates continue when app is in background
- ✅ All tracking features work normally

### What Changed:
- ❌ Service will NOT auto-start when device reboots
- ℹ️ Users need to open the app and punch in again after device restart

## User Experience
After device reboot, users will need to:
1. Open the app
2. Login (if needed)
3. Punch in to start tracking again

This is actually better for battery life and user privacy, as tracking only happens when explicitly started by the user.

## Testing
1. Clean build: `flutter clean`
2. Get dependencies: `flutter pub get`
3. Run app: `flutter run`
4. Test punch in/out functionality
5. Verify background tracking works

## Alternative Solutions (Not Recommended)
If you absolutely need auto-start on boot, you would need to:
1. Use WorkManager instead of direct foreground service
2. Implement exact alarm permissions (Android 12+)
3. Request SCHEDULE_EXACT_ALARM permission
4. Handle complex edge cases for different Android versions

The current solution is simpler and more reliable.
