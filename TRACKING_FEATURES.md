# Live Location Tracking Features

## ✅ Implemented Features

### 1. Real-Time Location Tracking
- **Background Service**: Tracks location every 60 seconds even when app is closed
- **Foreground Notification**: Shows persistent notification with tracking status
- **Battery Monitoring**: Includes battery level in location updates
- **Accuracy Tracking**: Records GPS accuracy for each location point

### 2. Survives App Kill
The tracking service is designed to survive:
- ✅ App closed from recent apps
- ✅ Device idle/doze mode (with battery optimization exemption)
- ✅ Low memory situations
- ✅ Screen off

**How it works:**
- Uses Android Foreground Service with location type
- Persistent notification keeps service alive
- Battery optimization exemption prevents Android from killing the service

### 3. Comprehensive Permissions

#### Required Permissions:
1. **Location (ACCESS_FINE_LOCATION)**
   - Required to get GPS coordinates
   - Requested on first punch-in

2. **Background Location (ACCESS_BACKGROUND_LOCATION)**
   - Required for tracking when app is closed
   - Android 10+ requires separate permission
   - Requested after location permission

3. **Notifications (POST_NOTIFICATIONS)**
   - Required on Android 13+
   - Shows tracking status notification
   - Requested with other permissions

4. **Battery Optimization Exemption**
   - Prevents Android from stopping the service
   - Critical for reliable tracking
   - Requested during permission setup

#### Permission Flow:
```
User clicks "Punch In"
  ↓
Check if permissions granted
  ↓
If not → Show Permission Setup Dialog
  ↓
Request all permissions sequentially
  ↓
Show status for each permission
  ↓
Allow punch-in when location granted
  ↓
Warn if other permissions missing
```

### 4. Admin Panel Live View

#### Backend Endpoint:
```
GET /realtime/user/:userId/live
```

Returns:
```json
{
  "userId": "user-id",
  "latitude": 12.345,
  "longitude": 67.890,
  "battery": 85,
  "accuracy": 10.5,
  "speed": 2.3,
  "timestamp": "2024-12-01T10:30:00Z",
  "lastSeen": "2024-12-01T10:30:00Z"
}
```

#### Location Update Endpoint:
```
POST /realtime/track
```

Payload:
```json
{
  "userId": "user-id",
  "androidId": "device-id",
  "latitude": 12.345,
  "longitude": 67.890,
  "battery": 85,
  "accuracy": 10.5,
  "speed": 2.3,
  "timestamp": "2024-12-01T10:30:00Z"
}
```

### 5. Notification Features

The persistent notification shows:
- **Title**: "Attendance Tracking Active"
- **Content**: "Location updates: X | Battery: Y%"
- **Icon**: App icon
- **Priority**: Low (doesn't disturb user)
- **Ongoing**: Cannot be dismissed while tracking

Updates in real-time:
- Location update count
- Current battery level
- GPS status (if GPS is off)

## 📱 User Experience

### Starting Tracking:
1. User opens app and logs in
2. User clicks "Punch In"
3. If permissions not granted → Permission Setup Dialog appears
4. User grants all permissions
5. Tracking starts immediately
6. Notification appears showing tracking status
7. User can close app - tracking continues

### While Tracking:
- Notification shows in status bar
- Location sent to server every 60 seconds
- Battery level monitored
- Works even when:
  - App is closed
  - Screen is off
  - Device is idle
  - User is using other apps

### Stopping Tracking:
1. User opens app
2. User clicks "Punch Out"
3. Tracking stops
4. Notification disappears
5. Final location recorded

## 🔧 Technical Implementation

### Background Service Configuration:
```dart
AndroidConfiguration(
  onStart: onStart,
  autoStart: false,
  autoStartOnBoot: false,  // Disabled for Android 12+ compatibility
  isForegroundMode: true,
  notificationChannelId: 'attendance_tracking_channel',
  initialNotificationTitle: 'Attendance Tracking',
  initialNotificationContent: 'Tracking your location...',
  foregroundServiceNotificationId: 888,
  foregroundServiceTypes: [AndroidForegroundType.location],
)
```

### Location Settings:
```dart
LocationSettings(
  accuracy: LocationAccuracy.high,  // Best accuracy
  distanceFilter: 10,               // Update every 10 meters
)
```

### Update Frequency:
- **Timer-based**: Every 60 seconds
- **Distance-based**: Every 10 meters (when moving)
- **Fallback**: If GPS unavailable, skips update

## 🛡️ Privacy & Battery

### Privacy:
- Tracking only when user is punched in
- User must explicitly start tracking
- Clear notification shows tracking is active
- User can stop tracking anytime

### Battery Optimization:
- Updates every 60 seconds (not continuous)
- Uses high accuracy only when needed
- Skips updates if GPS is off
- Efficient HTTP requests with timeout
- Low priority notification (doesn't wake screen)

### Battery Impact:
- **Estimated**: 5-10% per 8-hour shift
- **Factors**:
  - GPS accuracy setting
  - Update frequency
  - Network conditions
  - Device model

## 📊 Admin Dashboard Integration

### View Live Locations:
```dart
// Get live location for a user
final response = await apiService.getLiveTracking(userId);

// Response includes:
// - Current location
// - Battery level
// - Last update time
// - Accuracy
// - Speed
```

### View History:
```dart
// Get tracking history
final response = await apiService.getTrackingHistory(
  userId,
  from: DateTime.now().subtract(Duration(hours: 8)),
  to: DateTime.now(),
);

// Returns array of location points
```

### Display on Map:
- Use Google Maps Flutter plugin
- Show user marker at current location
- Draw polyline for route history
- Update marker in real-time (poll every 30-60 seconds)

## 🚨 Troubleshooting

### Tracking Stops After App Kill:
**Cause**: Battery optimization not disabled
**Solution**: 
1. Open Permission Setup Dialog
2. Grant battery optimization exemption
3. Or manually: Settings → Apps → Tracker → Battery → Unrestricted

### No Location Updates:
**Cause**: GPS disabled or no permission
**Solution**:
1. Check GPS is enabled
2. Check location permission granted
3. Check background location permission granted
4. Check notification shows "GPS Off" message

### Notification Not Showing:
**Cause**: Notification permission denied (Android 13+)
**Solution**:
1. Open Permission Setup Dialog
2. Grant notification permission
3. Or manually: Settings → Apps → Tracker → Notifications → Allow

### High Battery Drain:
**Cause**: Too frequent updates or high accuracy
**Solution**:
- Current settings are optimized (60 second intervals)
- Consider increasing interval if needed
- Check other apps aren't also using GPS

## 🔄 Update Frequency Customization

To change update frequency, edit `background_location_service.dart`:

```dart
// Change from 60 seconds to desired interval
Timer.periodic(const Duration(seconds: 60), (timer) async {
  // ... location update code
});
```

**Recommendations**:
- **30 seconds**: More accurate, higher battery usage
- **60 seconds**: Balanced (current setting)
- **120 seconds**: Lower battery, less accurate
- **300 seconds**: Minimal battery, basic tracking

## ✨ Future Enhancements

Potential improvements:
- [ ] Adaptive update frequency based on movement
- [ ] Geofencing for automatic punch in/out
- [ ] Offline location caching with sync
- [ ] Movement detection (walking, driving, stationary)
- [ ] Route optimization suggestions
- [ ] Team location sharing
- [ ] SOS/Emergency button
- [ ] Custom notification actions (pause/resume)

## 📝 Testing Checklist

- [ ] Punch in starts tracking
- [ ] Notification appears
- [ ] Location updates sent to server
- [ ] Admin can see live location
- [ ] Tracking continues when app closed
- [ ] Tracking continues with screen off
- [ ] Tracking survives app kill from recent apps
- [ ] Punch out stops tracking
- [ ] Notification disappears
- [ ] Battery optimization exemption works
- [ ] All permissions requested properly
- [ ] Permission dialog shows correct status
- [ ] Works on Android 10, 11, 12, 13, 14
