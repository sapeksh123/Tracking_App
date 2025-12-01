# Testing Guide - Live Location Tracking

## 🧪 Quick Test (5 minutes)

### 1. Build and Run
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

### 2. Login as User
- Phone: `8888888888`
- Password: (your user password)

### 3. Grant Permissions
1. Click "Punch In"
2. Permission dialog appears
3. Click "Grant Permissions"
4. Allow all permissions when prompted

### 4. Verify Tracking Started
- ✅ Notification appears: "Attendance Tracking Active"
- ✅ Toast shows: "Punched in successfully! Tracking started."
- ✅ UI shows "Punched In" status

### 5. Test Background Tracking
1. Press home button (don't close app)
2. Wait 60 seconds
3. Pull down notification shade
4. Check notification updates: "Location updates: 1 | Battery: X%"

### 6. Test App Kill
1. Open recent apps (square button)
2. Swipe away the app
3. Wait 60 seconds
4. Pull down notification shade
5. ✅ Notification still there
6. ✅ Counter increased: "Location updates: 2 | Battery: X%"

### 7. Verify Backend
```bash
# Check if location updates are being received
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  https://tracking-app-8rsa.onrender.com/realtime/user/USER_ID/live
```

Expected response:
```json
{
  "userId": "...",
  "latitude": 12.345,
  "longitude": 67.890,
  "battery": 85,
  "timestamp": "2024-12-01T10:30:00.000Z",
  "lastSeen": "2024-12-01T10:30:00.000Z"
}
```

### 8. Stop Tracking
1. Open app again
2. Click "Punch Out"
3. ✅ Notification disappears
4. ✅ Toast shows: "Punched out successfully!"

## 🔬 Detailed Testing

### Test 1: Permission Flow
**Objective**: Verify all permissions are requested correctly

**Steps**:
1. Fresh install app (or clear app data)
2. Login as user
3. Click "Punch In"
4. Permission Setup Dialog appears

**Verify**:
- [ ] Dialog shows 4 permissions
- [ ] Each permission has icon and description
- [ ] All show red X (not granted)
- [ ] "Grant Permissions" button visible

**Steps**:
5. Click "Grant Permissions"
6. Android prompts for Location
7. Select "While using the app"

**Verify**:
- [ ] Location permission granted
- [ ] Dialog updates to show green check for Location
- [ ] Android prompts for Background Location
- [ ] Options: "Allow all the time", "Allow only while using", "Deny"

**Steps**:
8. Select "Allow all the time"

**Verify**:
- [ ] Background Location shows green check
- [ ] Android prompts for Notifications (Android 13+)

**Steps**:
9. Allow notifications
10. Battery optimization prompt appears

**Verify**:
- [ ] All 4 permissions show green checks
- [ ] "Done" button appears
- [ ] Can close dialog

### Test 2: Tracking Accuracy
**Objective**: Verify location updates are accurate

**Steps**:
1. Punch in
2. Walk around (outdoor for best GPS)
3. Wait for 3-4 location updates (3-4 minutes)
4. Check backend for location history

**Verify**:
- [ ] Locations form a path matching your movement
- [ ] Accuracy is < 20 meters
- [ ] Timestamps are ~60 seconds apart
- [ ] Battery level is included

### Test 3: Background Persistence
**Objective**: Verify tracking survives various scenarios

**Scenario A: App in Background**
1. Punch in
2. Press home button
3. Use other apps for 5 minutes
4. Check notification

**Verify**:
- [ ] Notification still visible
- [ ] Update count increased
- [ ] Battery level updated

**Scenario B: Screen Off**
1. Punch in
2. Turn off screen
3. Wait 5 minutes
4. Turn on screen
5. Check notification

**Verify**:
- [ ] Notification still visible
- [ ] Updates continued while screen off

**Scenario C: App Killed**
1. Punch in
2. Kill app from recent apps
3. Wait 5 minutes
4. Check notification

**Verify**:
- [ ] Notification still visible
- [ ] Updates continued after app kill

**Scenario D: Device Idle**
1. Punch in
2. Leave device idle for 10 minutes
3. Check notification

**Verify**:
- [ ] Notification still visible
- [ ] Updates continued during idle

### Test 4: Battery Optimization
**Objective**: Verify battery optimization exemption works

**Steps**:
1. Go to Settings → Apps → Tracker
2. Go to Battery
3. Check battery optimization setting

**Verify**:
- [ ] Shows "Unrestricted" or "Not optimized"
- [ ] If not, tracking may stop after 1 hour

### Test 5: Notification Updates
**Objective**: Verify notification shows correct information

**Steps**:
1. Punch in
2. Wait for 3 updates (3 minutes)
3. Check notification content

**Verify**:
- [ ] Title: "Attendance Tracking Active"
- [ ] Content: "Location updates: 3 | Battery: X%"
- [ ] Battery percentage matches device battery
- [ ] Update count increases each minute

**Steps**:
4. Turn off GPS
5. Wait 1 minute
6. Check notification

**Verify**:
- [ ] Title changes to: "Attendance Tracking - GPS Off"
- [ ] Content: "Please enable location services"

**Steps**:
7. Turn on GPS
8. Wait 1 minute

**Verify**:
- [ ] Title back to: "Attendance Tracking Active"
- [ ] Updates resume

### Test 6: Admin Panel Integration
**Objective**: Verify admin can see live locations

**Steps**:
1. User punches in on mobile
2. Admin logs in on web/another device
3. Admin calls API: `GET /realtime/user/:userId/live`

**Verify**:
- [ ] Returns current location
- [ ] Latitude/longitude are valid
- [ ] Battery level matches device
- [ ] Timestamp is recent (< 2 minutes old)
- [ ] lastSeen is recent

**Steps**:
4. Wait 2 minutes
5. Call API again

**Verify**:
- [ ] Location updated (if user moved)
- [ ] Timestamp is newer
- [ ] lastSeen is newer

### Test 7: Error Handling
**Objective**: Verify app handles errors gracefully

**Scenario A: No Internet**
1. Punch in
2. Turn off WiFi and mobile data
3. Wait 2 minutes
4. Turn on internet

**Verify**:
- [ ] Notification still shows
- [ ] No crashes
- [ ] Updates resume when internet returns

**Scenario B: GPS Disabled**
1. Punch in
2. Turn off GPS
3. Check notification

**Verify**:
- [ ] Shows "GPS Off" message
- [ ] No crashes
- [ ] Updates resume when GPS enabled

**Scenario C: Low Battery**
1. Punch in
2. Let battery drain to < 15%
3. Check tracking

**Verify**:
- [ ] Tracking continues
- [ ] Battery level reported correctly
- [ ] No crashes

### Test 8: Multiple Sessions
**Objective**: Verify tracking works across multiple punch in/out cycles

**Steps**:
1. Punch in → Wait 2 min → Punch out
2. Wait 1 minute
3. Punch in → Wait 2 min → Punch out
4. Repeat 3 times

**Verify**:
- [ ] Each punch in starts tracking
- [ ] Each punch out stops tracking
- [ ] Notification appears/disappears correctly
- [ ] No memory leaks
- [ ] No crashes

### Test 9: Android Version Compatibility
**Objective**: Verify works on different Android versions

**Test on**:
- [ ] Android 10 (API 29)
- [ ] Android 11 (API 30)
- [ ] Android 12 (API 31)
- [ ] Android 13 (API 33)
- [ ] Android 14 (API 34)

**Verify for each**:
- [ ] App installs
- [ ] Permissions requested correctly
- [ ] Tracking works
- [ ] Survives app kill
- [ ] No crashes

### Test 10: Performance
**Objective**: Verify app performs well

**Metrics to check**:
- [ ] App launch time < 3 seconds
- [ ] Punch in response < 2 seconds
- [ ] Location update processing < 1 second
- [ ] Memory usage < 100 MB
- [ ] Battery drain < 10% per 8 hours
- [ ] No ANR (App Not Responding)
- [ ] No crashes

## 🐛 Common Issues & Solutions

### Issue: Tracking stops after 1 hour
**Cause**: Battery optimization not disabled
**Solution**: Grant battery optimization exemption

### Issue: No location updates
**Cause**: GPS disabled or no permission
**Solution**: Enable GPS, grant location permission

### Issue: Notification not showing
**Cause**: Notification permission denied (Android 13+)
**Solution**: Grant notification permission

### Issue: "GPS Off" message
**Cause**: Location services disabled
**Solution**: Enable location in device settings

### Issue: High battery drain
**Cause**: Too frequent updates or other apps
**Solution**: Check update interval (currently 60s), close other GPS apps

### Issue: Inaccurate locations
**Cause**: Poor GPS signal
**Solution**: Test outdoors, wait for GPS lock

## ✅ Test Results Template

```
Date: ___________
Tester: ___________
Device: ___________
Android Version: ___________

Test 1: Permission Flow          [ ] Pass [ ] Fail
Test 2: Tracking Accuracy        [ ] Pass [ ] Fail
Test 3: Background Persistence   [ ] Pass [ ] Fail
Test 4: Battery Optimization     [ ] Pass [ ] Fail
Test 5: Notification Updates     [ ] Pass [ ] Fail
Test 6: Admin Panel Integration  [ ] Pass [ ] Fail
Test 7: Error Handling           [ ] Pass [ ] Fail
Test 8: Multiple Sessions        [ ] Pass [ ] Fail
Test 9: Android Compatibility    [ ] Pass [ ] Fail
Test 10: Performance             [ ] Pass [ ] Fail

Notes:
_________________________________
_________________________________
_________________________________

Overall Result: [ ] Pass [ ] Fail
```

## 📊 Success Criteria

For production release, all tests must pass with:
- ✅ 100% permission flow success
- ✅ < 20m location accuracy
- ✅ Tracking survives app kill
- ✅ < 10% battery drain per 8 hours
- ✅ No crashes in 24-hour test
- ✅ Works on Android 10-14
- ✅ Admin can see live locations
- ✅ Notification always visible when tracking

## 🎯 Next Steps After Testing

1. **If all tests pass**: Ready for production!
2. **If some tests fail**: Check troubleshooting guide
3. **If performance issues**: Adjust update frequency
4. **If battery drain high**: Reduce accuracy or frequency
5. **If crashes**: Check logs and fix bugs

Happy Testing! 🚀
