# Visit Marking Feature - Implementation Complete

## ✅ Features Implemented

### 1. GPS Location Handling
**Problem:** If user turns off GPS, location tracking fails
**Solution:** 
- Check if GPS is enabled before getting location
- Show notification "GPS Off - Please enable location services"
- Prompt user to enable GPS with `Geolocator.openLocationSettings()`
- Background service updates notification when GPS is off

### 2. Mark Visit Feature
**What it does:**
- Allows users to mark their current location as a visit
- Saves location with optional name and notes
- Links visit to current attendance session
- Stores battery level and timestamp

**User Flow:**
```
1. User punches in
2. "Mark Visit" button appears on home screen
3. User taps "Mark Visit"
4. Dialog opens asking for:
   - Location Name (optional) - e.g., "Client Office", "Store #123"
   - Notes (optional) - e.g., "Met with John, discussed project"
5. User fills details and taps "Mark Visit"
6. System checks if GPS is enabled
7. If GPS off → Prompts to enable GPS
8. If GPS on → Gets current location and saves visit
9. Success message shown
```

## Database Schema

### Visit Model
```prisma
model Visit {
  id          String   @id @default(uuid())
  userId      String
  sessionId   String?  // Link to attendance session
  latitude    Float
  longitude   Float
  address     String?  // Location name/address
  notes       String?  // User notes about the visit
  visitTime   DateTime @default(now())
  battery     Int?
  createdAt   DateTime @default(now())
  user        User     @relation(fields: [userId], references: [id])
  
  @@index([userId, visitTime])
  @@index([sessionId])
}
```

## Backend API Endpoints

### POST /visits/mark
Mark a new visit
```json
{
  "userId": "user-id",
  "sessionId": "session-id",  // optional
  "latitude": 12.9716,
  "longitude": 77.5946,
  "address": "Client Office",  // optional
  "notes": "Met with team",    // optional
  "battery": 85                // optional
}
```

### GET /visits/user/:userId
Get all visits for a user
Query params: `sessionId`, `from`, `to`, `limit`

### GET /visits/session/:sessionId
Get all visits for a specific session

### PUT /visits/:visitId
Update visit address and notes

### DELETE /visits/:visitId
Delete a visit

## Frontend Implementation

### Files Created:
1. **frontend/lib/services/visit_service.dart** - Visit service
2. **frontend/lib/screens/visits_screen.dart** - Visits list screen
3. **backend/src/controllers/visit.controller.js** - Visit controller
4. **backend/src/routes/visit.routes.js** - Visit routes

### Files Modified:
1. **frontend/lib/services/api_service.dart** - Added visit API methods
2. **frontend/lib/screens/user_home_screen_v2.dart** - Added "Mark Visit" button
3. **frontend/lib/services/tracking_service.dart** - Added GPS check
4. **frontend/lib/services/background_location_service.dart** - Added GPS check
5. **frontend/lib/routes.dart** - Added visits route
6. **backend/src/app.js** - Added visit routes
7. **backend/prisma/schema.prisma** - Added Visit model

## User Interface

### Home Screen (When Punched In)
```
┌─────────────────────────────────┐
│  Punch In/Out Card              │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  📍 Mark Visit                  │
│  Save your current location     │
│  as a visit                  →  │
└─────────────────────────────────┘
        [View All Visits]

┌─────────────────────────────────┐
│  How Attendance Works           │
└─────────────────────────────────┘
```

### Mark Visit Dialog
```
┌─────────────────────────────────┐
│  📍 Mark Visit                  │
├─────────────────────────────────┤
│  Location Name (Optional)       │
│  ┌───────────────────────────┐ │
│  │ e.g., Client Office       │ │
│  └───────────────────────────┘ │
│                                 │
│  Notes (Optional)               │
│  ┌───────────────────────────┐ │
│  │ Add any notes about       │ │
│  │ this visit                │ │
│  └───────────────────────────┘ │
├─────────────────────────────────┤
│  [Cancel]  [✓ Mark Visit]      │
└─────────────────────────────────┘
```

### Visits List Screen
```
┌─────────────────────────────────┐
│  ← All Visits            🔄     │
├─────────────────────────────────┤
│  [Map View - Shows all visits]  │
│                                 │
├─────────────────────────────────┤
│  1  Client Office               │
│     🕐 01/12/2025 10:30        │
│     Met with John              │
│     Lat: 12.971, Lng: 77.594   │
│                              ⋮  │
├─────────────────────────────────┤
│  2  Store #123                  │
│     🕐 01/12/2025 14:15        │
│     Inventory check            │
│     Lat: 12.985, Lng: 77.610   │
│                              ⋮  │
└─────────────────────────────────┘
```

### Visit Actions (⋮ Menu)
- 🗺️ View on Map - Zoom to visit location
- ✏️ Edit - Edit name and notes
- 🗑️ Delete - Remove visit

## GPS Handling

### When GPS is Turned Off

**Background Service:**
```
Notification shows:
"Attendance Tracking - GPS Off"
"Please enable location services"
```

**Mark Visit:**
```
1. User taps "Mark Visit"
2. System checks GPS status
3. If GPS off:
   - Show toast: "GPS is turned off. Please enable location services."
   - Open location settings automatically
4. User enables GPS
5. User tries again
6. Visit marked successfully
```

### Code Implementation

**Check GPS Status:**
```dart
final serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) {
  // GPS is off
  await Geolocator.openLocationSettings();
  return;
}
```

**Background Service GPS Check:**
```dart
// In background_location_service.dart
final serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) {
  service.setForegroundNotificationInfo(
    title: 'Attendance Tracking - GPS Off',
    content: 'Please enable location services',
  );
  return;
}
```

## Admin View

### Admin Dashboard
Admins can see:
1. **User's Route** - Polyline showing movement
2. **Visit Markers** - Blue markers at visit locations
3. **Visit Details** - Click marker to see name, notes, time

### Session Route Screen
Shows:
- Green marker: Punch in location
- Red marker: Punch out location
- Blue line: Route traveled
- Blue markers: Visits marked during session

## Testing Checklist

### GPS Handling
- [ ] Turn off GPS → Try to mark visit → Should prompt to enable GPS
- [ ] Turn off GPS → Background tracking → Notification shows "GPS Off"
- [ ] Turn on GPS → Background tracking → Notification shows normal status
- [ ] Punch in with GPS off → Should show error

### Mark Visit
- [ ] Punch in → "Mark Visit" button appears
- [ ] Tap "Mark Visit" → Dialog opens
- [ ] Fill location name and notes → Mark visit → Success message
- [ ] Mark visit without name/notes → Should work (optional fields)
- [ ] Mark multiple visits → All saved correctly
- [ ] Punch out → "Mark Visit" button disappears

### Visits List
- [ ] View all visits → Shows list and map
- [ ] Tap visit → View on map (zooms to location)
- [ ] Edit visit → Update name/notes → Saved
- [ ] Delete visit → Confirmation → Deleted
- [ ] Filter by session → Shows only session visits

### Admin View
- [ ] Admin views user route → Sees visit markers
- [ ] Admin clicks visit marker → Sees visit details
- [ ] Multiple users with visits → Each shown correctly

## Database Migration

Run this command to create the Visit table:
```bash
cd backend
npx prisma migrate dev --name add_visits
npx prisma generate
```

Or manually run the SQL:
```sql
CREATE TABLE "Visit" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "userId" TEXT NOT NULL,
  "sessionId" TEXT,
  "latitude" DOUBLE PRECISION NOT NULL,
  "longitude" DOUBLE PRECISION NOT NULL,
  "address" TEXT,
  "notes" TEXT,
  "visitTime" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "battery" INTEGER,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY ("userId") REFERENCES "User"("id")
);

CREATE INDEX "Visit_userId_visitTime_idx" ON "Visit"("userId", "visitTime");
CREATE INDEX "Visit_sessionId_idx" ON "Visit"("sessionId");
```

## API Usage Examples

### Mark a Visit
```javascript
POST /visits/mark
{
  "userId": "80cb7dba-48a2-472c-b4da-83cb25f999bd",
  "sessionId": "session-123",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "address": "Client Office - ABC Corp",
  "notes": "Quarterly review meeting with stakeholders",
  "battery": 85
}

Response:
{
  "success": true,
  "message": "Visit marked successfully",
  "visit": {
    "id": "visit-123",
    "userId": "80cb7dba-48a2-472c-b4da-83cb25f999bd",
    "sessionId": "session-123",
    "latitude": 12.9716,
    "longitude": 77.5946,
    "address": "Client Office - ABC Corp",
    "notes": "Quarterly review meeting with stakeholders",
    "visitTime": "2025-12-01T10:30:00.000Z",
    "battery": 85,
    "createdAt": "2025-12-01T10:30:00.000Z"
  }
}
```

### Get User's Visits
```javascript
GET /visits/user/80cb7dba-48a2-472c-b4da-83cb25f999bd

Response:
{
  "success": true,
  "count": 5,
  "visits": [
    {
      "id": "visit-123",
      "userId": "80cb7dba-48a2-472c-b4da-83cb25f999bd",
      "sessionId": "session-123",
      "latitude": 12.9716,
      "longitude": 77.5946,
      "address": "Client Office",
      "notes": "Meeting completed",
      "visitTime": "2025-12-01T10:30:00.000Z",
      "battery": 85
    },
    // ... more visits
  ]
}
```

## Benefits

### For Users
✅ Track important locations during work day
✅ Add context to their route (where they went and why)
✅ Review their visits later
✅ Proof of client visits

### For Admins
✅ See where users visited
✅ Understand user's work pattern
✅ Verify client visits
✅ Better route analysis

### For Business
✅ Field worker accountability
✅ Client visit verification
✅ Route optimization insights
✅ Work pattern analysis

## Summary

✅ **GPS Handling** - Detects when GPS is off, prompts user to enable
✅ **Mark Visit** - Save current location with name and notes
✅ **Visits List** - View all visits in list and map
✅ **Edit/Delete** - Manage visits
✅ **Session Integration** - Visits linked to attendance sessions
✅ **Admin View** - Admins see visit markers on route
✅ **Dynamic Updates** - Real-time visit marking during work

Everything is implemented and ready to test after running the database migration!
