# Quick Setup - Visit Feature

## 🚀 Setup Steps

### 1. Database Migration (2 minutes)
```bash
cd backend
npx prisma migrate dev --name add_visits
npx prisma generate
```

### 2. Restart Backend (1 minute)
```bash
# Stop current backend (Ctrl+C)
npm start
```

### 3. Rebuild Flutter App (3 minutes)
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

## ✅ What's New

### User Features
1. **Mark Visit Button** - Appears when punched in
2. **Visit Dialog** - Add location name and notes
3. **Visits List** - View all visits with map
4. **GPS Detection** - Prompts if GPS is off

### Admin Features
1. **Visit Markers** - See user visits on route map
2. **Visit Details** - Click markers for info

## 🧪 Quick Test

### Test 1: Mark Visit (2 minutes)
```
1. Login as user
2. Punch in
3. See "Mark Visit" button
4. Tap "Mark Visit"
5. Enter: "Test Location" and "Test notes"
6. Tap "Mark Visit"
7. Should see success message
```

### Test 2: GPS Off (1 minute)
```
1. Turn off GPS on device
2. Tap "Mark Visit"
3. Should see "GPS is turned off" message
4. Should open location settings
5. Enable GPS
6. Try again - should work
```

### Test 3: View Visits (1 minute)
```
1. Tap "View All Visits"
2. Should see list of visits
3. Should see map with markers
4. Tap a visit
5. Should zoom to location on map
```

### Test 4: Background GPS Check (2 minutes)
```
1. Punch in
2. Turn off GPS
3. Check notification
4. Should show "GPS Off - Please enable location services"
5. Turn on GPS
6. Notification should update to normal
```

## 📱 User Interface

### Home Screen (Punched In)
- ✅ "Mark Visit" card (blue)
- ✅ "View All Visits" link

### Mark Visit Dialog
- ✅ Location Name field (optional)
- ✅ Notes field (optional, multiline)
- ✅ Cancel and Mark Visit buttons

### Visits Screen
- ✅ Map showing all visit markers
- ✅ List of visits with details
- ✅ Edit/Delete options (⋮ menu)

## 🔧 Troubleshooting

### "Visit not saved"
- Check backend is running
- Check database migration completed
- Check network connection

### "GPS is off" always shows
- Enable location services in device settings
- Grant location permission to app
- Restart app

### Visits not showing on map
- Check visits were saved (check list)
- Check map has internet connection
- Check Google Maps API key is valid

## 📊 Database Check

Verify Visit table exists:
```bash
cd backend
npx prisma studio
```
- Open browser at http://localhost:5555
- Check "Visit" model exists
- Check visits are being saved

## 🎯 Success Criteria

✅ Mark visit button appears when punched in
✅ Can mark visit with name and notes
✅ GPS off detection works
✅ Visits list shows all visits
✅ Map shows visit markers
✅ Can edit and delete visits
✅ Background service detects GPS off

## 📝 Notes

- Visits are optional - users don't have to mark any
- Visits are linked to attendance sessions
- Admins can see visits on user routes
- GPS must be enabled to mark visits
- Location name and notes are optional

## 🚀 Ready!

After completing setup steps, the visit feature is ready to use!
