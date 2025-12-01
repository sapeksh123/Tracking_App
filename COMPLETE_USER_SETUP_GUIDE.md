# Complete User Setup & Login Guide

## ✅ All Issues Fixed

### Issue 1: "User ID not found" ✓ FIXED
**Problem**: User data was being parsed incorrectly (as query string instead of JSON)
**Solution**: Changed from `Uri.splitQueryString()` to `jsonDecode()` to properly parse user data

### Issue 2: No password field in create user ✓ FIXED
**Problem**: Couldn't set custom passwords when creating users
**Solution**: Added password field with toggle visibility and helper text

## How to Use the System

### Step 1: Login as Admin
1. Open the app
2. Click "Login as admin instead" (if on user login screen)
3. Enter credentials:
   - **Email**: `admin`
   - **Password**: `admin`
4. Click "Login"

### Step 2: Create a User
1. In admin dashboard, click "Create User"
2. Fill in the form:
   - **Name**: John Doe (required)
   - **Email**: john@example.com (optional)
   - **Phone**: 9876543210 (required, exactly 10 digits)
   - **Password**: (optional)
     - Leave empty → phone number becomes password
     - Enter custom → user will use that password

3. Click "Create User"
4. You'll see success message with user name

### Step 3: Logout from Admin
1. Click logout/back button
2. Return to login screen

### Step 4: Login as User
1. Click "Login as user instead" (if on admin login screen)
2. Enter credentials:
   - **Phone**: 9876543210
   - **Password**: 
     - If you left password empty: use phone number (9876543210)
     - If you set custom password: use that password
3. Click "Login"

### Step 5: Grant Permissions
1. First time login will show consent dialog
2. Click "I Agree"
3. Grant location permission when prompted
4. You're ready to punch in!

### Step 6: Punch In
1. Click the green "Punch In" button
2. Wait for confirmation toast
3. You'll see:
   - Status changed to "Punched In"
   - Current duration counter
   - Distance traveled
   - Number of tracking points

### Step 7: Work & Track
- Your location is tracked every 60 seconds
- Battery level is monitored
- You can see real-time stats on the home screen
- Recent sessions appear at the bottom

### Step 8: Punch Out
1. When done working, click red "Punch Out" button
2. Wait for confirmation
3. You'll see summary:
   - Total duration worked
   - Total distance traveled
4. Session is saved to history

### Step 9: View History
1. Click history icon in app bar
2. See all your attendance sessions
3. Tap any session to view details
4. Click "View Route on Map" to see your path

## Password System Explained

### Default Password (No Password Set)
When creating a user WITHOUT entering a password:
- **Password = Phone Number**
- Example: Phone `9876543210` → Password `9876543210`

### Custom Password (Password Set)
When creating a user WITH a password:
- **Password = What you entered**
- Example: You set `mypass123` → Password `mypass123`

### Password Field Features
- **Toggle visibility**: Click eye icon to show/hide password
- **Helper text**: Shows "Default: phone number" to remind you
- **Optional**: Can leave empty for default behavior

## Example Users

### User 1: Default Password
- Name: Test User
- Phone: 9876543210
- Email: test@example.com
- Password: (empty)
- **Login with**: Phone `9876543210`, Password `9876543210`

### User 2: Custom Password
- Name: John Doe
- Phone: 1234567890
- Email: john@example.com
- Password: john123
- **Login with**: Phone `1234567890`, Password `john123`

## Troubleshooting

### "User ID not found" Error
**Fixed!** This was caused by incorrect JSON parsing. Now properly uses `jsonDecode()`.

**If still occurring**:
1. Make sure you logged in through user login screen (not admin)
2. Check Flutter console for "DEBUG: User ID loaded: [id]"
3. If you see "WARNING: No user data found", you need to login again
4. Restart the app after login

### "Invalid credentials" Error
**Causes**:
- Wrong phone number
- Wrong password
- User doesn't exist
- User is deactivated

**Solutions**:
1. Verify user exists in admin dashboard
2. Check if you're using correct password:
   - Default: phone number
   - Custom: what was set during creation
3. Make sure phone is exactly 10 digits (no spaces, dashes)

### "Phone must be exactly 10 digits" Error
**Solution**: Enter only digits, no formatting
- ✓ Correct: `9876543210`
- ✗ Wrong: `+91 9876543210`
- ✗ Wrong: `987-654-3210`

### Can't Create User
**Possible causes**:
1. Not logged in as admin
2. Phone number already exists
3. Invalid email format
4. Network error

**Solutions**:
1. Make sure you're logged in as admin
2. Use a different phone number
3. Check email format (must have @ and .)
4. Check backend is running

## Testing Checklist

- [x] Admin login works
- [x] Create user with default password
- [x] Create user with custom password
- [x] User login with phone + default password
- [x] User login with phone + custom password
- [x] User ID properly stored after login
- [x] Punch in works (no "User ID not found")
- [x] Location tracking starts
- [x] Punch out works
- [x] View attendance history
- [x] View session route on map

## Files Changed

### Backend
- ✓ `backend/src/controllers/auth.controller.js` - Added userLogin
- ✓ `backend/src/routes/auth.routes.js` - Added /user-login route
- ✓ `backend/src/controllers/user.controller.js` - Already supports password

### Frontend
- ✓ `frontend/lib/screens/user_login_screen.dart` - Implemented authentication
- ✓ `frontend/lib/screens/user_home_screen.dart` - Fixed JSON parsing
- ✓ `frontend/lib/screens/create_user_screen.dart` - Added password field
- ✓ `frontend/lib/services/api_service.dart` - Added userLogin & password param

## Quick Reference

### Admin Credentials
```
Email: admin
Password: admin
```

### API Endpoints
```
POST /api/auth/login          - Admin login
POST /api/auth/user-login     - User login
POST /api/users               - Create user (admin only)
POST /api/users/:id/punch-in  - Start attendance
POST /api/users/:id/punch-out - End attendance
GET  /api/users/:id/attendance - Get history
```

### User Data Structure (Stored in SharedPreferences)
```json
{
  "id": "uuid-here",
  "name": "John Doe",
  "phone": "9876543210",
  "email": "john@example.com",
  "role": "user",
  "isActive": true
}
```

## Next Steps

1. ✅ Backend is running
2. ✅ Admin account ready
3. ✅ User creation with password field
4. ✅ User login working
5. ✅ User ID properly stored
6. ✅ Punch in/out ready

**You're all set!** Create a user and test the complete flow.

## Support

If you encounter issues:
1. Check backend logs: Look for errors in terminal
2. Check Flutter logs: Look for DEBUG/ERROR messages
3. Verify user exists: Check admin dashboard
4. Test API directly: Use curl or Postman
5. Restart app: Sometimes needed after login

## Success Indicators

When everything is working, you should see:
- ✓ "Login successful!" toast after user login
- ✓ "DEBUG: User ID loaded: [uuid]" in Flutter console
- ✓ Punch in button is enabled
- ✓ "Punched in successfully!" toast after punch in
- ✓ Real-time stats showing on home screen
- ✓ Location tracking active in background
