# 🔧 Mark Visit Troubleshooting Guide

## Issue
"Failed to mark visit" error when trying to mark a visit.

## Enhanced Backend Logging

I've added detailed logging to the backend to help identify the issue:

### Backend Logs to Check:
```
📍 Mark visit request received: { body: {...}, headers: {...} }
✓ Validation passed, creating visit...
✓ Visit created successfully: visit-id
```

Or error logs:
```
❌ Missing userId
❌ Missing latitude
❌ Invalid latitude: value
❌ Mark visit error: error details
```

## Common Causes & Solutions

### 1. User Not Punched In
**Symptom**: Visit button not showing or disabled
**Solution**: User must punch in first before marking visits

**Check**:
```dart
// In user_home_screen_v2.dart
if (_isPunchedIn) {
  // Visit button should be visible
}
```

### 2. GPS/Location Issues
**Symptoms**:
- "GPS is turned off" message
- "Location permission not granted" message

**Solutions**:
- Enable GPS on device
- Grant location permission
- Test outdoors for better GPS signal

### 3. Missing Session ID
**Symptom**: Visit created but not linked to session
**Solution**: Ensure user is punched in and has active session

**Check**:
```dart
debugPrint('📍 Session ID: ${_currentSession?['id']}');
// Should print a valid session ID
```

### 4. Network/Backend Issues
**Symptoms**:
- "Failed to mark visit" with no specific error
- Timeout errors
- Connection refused

**Solutions**:
- Check backend is running
- Check network connectivity
- Check backend URL is correct

### 5. Database Issues
**Symptoms**:
- Backend error with Prisma error code
- Foreign key constraint errors

**Solutions**:
- Check user exists in database
- Check session exists if sessionId provided
- Run database migrations

## Testing Steps

### Step 1: Check Backend is Running
```bash
cd backend
npm start

# Should see:
# Server running on port 5000
```

### Step 2: Test Backend Directly
```bash
curl -X POST http://localhost:5000/visits/mark \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "your-user-id",
    "latitude": 12.345,
    "longitude": 67.890,
    "address": "Test Location",
    "notes": "Test visit"
  }'

# Should return:
# {"success":true,"message":"Visit marked successfully","visit":{...}}
```

### Step 3: Check Frontend Logs
```dart
// In Flutter app, check debug console for:
📍 Marking visit for user: user-id
📍 Session ID: session-id
📍 Address: address
📍 Notes: notes
✓ Visit marked successfully: {...}

// Or error:
✗ Failed to mark visit: error message
```

### Step 4: Check Backend Logs
```bash
# In backend terminal, should see:
📍 Mark visit request received: {...}
✓ Validation passed, creating visit...
✓ Visit created successfully: visit-id

# Or error:
❌ Missing userId
❌ Invalid latitude: value
❌ Mark visit error: {...}
```

## Debugging Checklist

- [ ] Backend is running
- [ ] User is logged in
- [ ] User is punched in
- [ ] GPS is enabled
- [ ] Location permission granted
- [ ] Network connectivity working
- [ ] Backend URL correct in frontend
- [ ] Database is accessible
- [ ] User exists in database
- [ ] Session exists (if provided)

## Error Messages Explained

### "User ID not found. Please login again."
- **Cause**: User not logged in or session expired
- **Solution**: Logout and login again

### "GPS is turned off. Please enable location services."
- **Cause**: Device GPS disabled
- **Solution**: Enable GPS in device settings

### "Location permission not granted"
- **Cause**: App doesn't have location permission
- **Solution**: Grant location permission in app settings

### "Failed to mark visit: userId is required"
- **Cause**: Frontend not sending userId
- **Solution**: Check user is logged in, check _userId variable

### "Failed to mark visit: Invalid latitude"
- **Cause**: GPS coordinates invalid or not available
- **Solution**: Wait for GPS lock, test outdoors

### "Failed to mark visit: Failed to get location"
- **Cause**: GPS timeout or unavailable
- **Solution**: Check GPS is enabled, test outdoors

## Backend Validation Rules

### Required Fields:
- `userId` - Must be valid UUID
- `latitude` - Must be number between -90 and 90
- `longitude` - Must be number between -180 and 180

### Optional Fields:
- `sessionId` - UUID of active session (recommended)
- `address` - String (location name)
- `notes` - String (user notes)
- `battery` - Integer (battery percentage)

### Example Valid Request:
```json
{
  "userId": "123e4567-e89b-12d3-a456-426614174000",
  "sessionId": "123e4567-e89b-12d3-a456-426614174001",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "address": "Bangalore, India",
  "notes": "Client meeting",
  "battery": 85
}
```

## Frontend Code Flow

```dart
User clicks "Mark Visit"
  ↓
Dialog opens (address, notes input)
  ↓
User clicks "Mark Visit" button
  ↓
Check GPS enabled
  ↓
Check location permission
  ↓
Get current location (GPS)
  ↓
Get battery level
  ↓
Call API: POST /visits/mark
  ↓
Success: Show toast, refresh session
  ↓
Error: Show specific error message
```

## Backend Code Flow

```javascript
Receive POST /visits/mark
  ↓
Log request details
  ↓
Validate userId (required)
  ↓
Validate latitude (required, -90 to 90)
  ↓
Validate longitude (required, -180 to 180)
  ↓
Parse coordinates to float
  ↓
Create visit in database
  ↓
Return success response
  ↓
Or return error with details
```

## Quick Fixes

### Fix 1: Restart Backend
```bash
cd backend
# Stop with Ctrl+C
npm start
```

### Fix 2: Clear App Data
```bash
# On Android device:
Settings → Apps → Tracker → Storage → Clear Data
# Then login again
```

### Fix 3: Check Database
```bash
cd backend
npx prisma studio
# Check if User and Visit tables exist
# Check if user exists
```

### Fix 4: Test with Postman
```
POST http://localhost:5000/visits/mark
Content-Type: application/json

{
  "userId": "your-user-id",
  "latitude": 12.345,
  "longitude": 67.890
}
```

## Files to Check

### Backend:
- `backend/src/controllers/visit.controller.js` - Visit logic
- `backend/src/routes/visit.routes.js` - Visit routes
- `backend/prisma/schema.prisma` - Visit model

### Frontend:
- `frontend/lib/screens/user_home_screen_v2.dart` - Mark visit UI
- `frontend/lib/services/visit_service.dart` - Visit service
- `frontend/lib/services/api_service.dart` - API calls

## Next Steps

1. **Restart Backend** with enhanced logging
2. **Try marking a visit** in the app
3. **Check backend logs** for detailed error
4. **Check frontend logs** for error details
5. **Share the specific error message** for further help

## Expected Behavior

### Success Flow:
```
User: Clicks "Mark Visit"
App: Shows dialog
User: Enters address/notes, clicks "Mark Visit"
App: Gets GPS location
App: Sends to backend
Backend: Validates data
Backend: Creates visit
Backend: Returns success
App: Shows "✓ Visit marked successfully!"
App: Refreshes session (visit count increases)
```

### Error Flow:
```
User: Clicks "Mark Visit"
App: Shows dialog
User: Clicks "Mark Visit"
App: Checks GPS → GPS off
App: Shows "GPS is turned off. Please enable location services."
App: Opens location settings
```

## Summary

The backend now has **enhanced logging** to help identify the exact issue. After restarting the backend, try marking a visit and check the logs for specific error messages.

Common issues:
1. ✅ User not punched in
2. ✅ GPS disabled
3. ✅ Location permission denied
4. ✅ Network issues
5. ✅ Backend not running

All should now show specific error messages to help debug!
