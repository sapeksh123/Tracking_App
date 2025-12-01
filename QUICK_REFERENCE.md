# Quick Reference Card

## 🚀 Run the App
```bash
cd frontend
flutter clean && flutter pub get && flutter run
```

## 🔑 Test Credentials
- **User Phone**: `8888888888`
- **Admin Email**: Check backend for admin credentials

## 📍 Production Backend
```
https://tracking-app-8rsa.onrender.com
```

## ✅ Features Checklist
- [x] Production backend integration
- [x] Live location tracking (60s intervals)
- [x] Survives app kill
- [x] Background tracking
- [x] Persistent notifications
- [x] Comprehensive permissions
- [x] Battery optimization
- [x] Admin panel ready

## 🔐 Required Permissions
1. **Location** - GPS tracking
2. **Background Location** - Track when app closed
3. **Notifications** - Show tracking status
4. **Battery Optimization** - Prevent service kill

## 📡 API Endpoints

### Track Location (Auto)
```
POST /realtime/track
Body: { userId, latitude, longitude, battery, timestamp }
```

### Get Live Location (Admin)
```
GET /realtime/user/:userId/live
Response: { latitude, longitude, battery, lastSeen }
```

### Get History (Admin)
```
GET /realtime/user/:userId/history?from=...&to=...
Response: { locations: [...] }
```

## 🧪 Quick Test
1. Login as user
2. Click "Punch In"
3. Grant all permissions
4. Close app from recent apps
5. Wait 2 minutes
6. Check notification still shows
7. ✅ Success!

## 📱 Notification
**When Tracking:**
```
Attendance Tracking Active
Location updates: 5 | Battery: 85%
```

**When GPS Off:**
```
Attendance Tracking - GPS Off
Please enable location services
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Tracking stops | Grant battery optimization exemption |
| No updates | Enable GPS, check permissions |
| No notification | Grant notification permission (Android 13+) |
| High battery drain | Normal: 5-10% per 8 hours |

## 📚 Documentation

| File | Purpose |
|------|---------|
| [FINAL_SUMMARY.md](FINAL_SUMMARY.md) | Complete overview |
| [LIVE_TRACKING_SETUP.md](LIVE_TRACKING_SETUP.md) | Setup guide |
| [TESTING_GUIDE.md](TESTING_GUIDE.md) | How to test |
| [TRACKING_FEATURES.md](TRACKING_FEATURES.md) | Feature details |

## 🎯 Success Criteria
- ✅ App launches without errors
- ✅ Permissions granted successfully
- ✅ Tracking starts on punch-in
- ✅ Notification appears
- ✅ Survives app kill
- ✅ Backend receives updates
- ✅ Admin can see live location

## 💡 Quick Tips
- First backend request may take 30-60s (cold start)
- Test outdoors for best GPS accuracy
- Battery optimization exemption is critical
- Notification must show for tracking to work
- Update frequency: 60 seconds (customizable)

## 🔧 Customization

### Change Update Frequency
Edit `background_location_service.dart`:
```dart
Timer.periodic(const Duration(seconds: 60), ...) // Change 60
```

### Change Accuracy
Edit `background_location_service.dart`:
```dart
LocationSettings(
  accuracy: LocationAccuracy.high, // or .medium, .low
)
```

## 📞 Need Help?
1. Check [TESTING_GUIDE.md](TESTING_GUIDE.md)
2. Check [TRACKING_FEATURES.md](TRACKING_FEATURES.md)
3. Review Android Studio logs
4. Check backend logs

## ✨ You're Ready!
Everything is configured and ready for production testing!
