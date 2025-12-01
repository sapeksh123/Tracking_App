# Admin Tracking - Visual Guide

## 📱 Screen Layout

```
┌─────────────────────────────────────────┐
│  ← Track User                    🔄     │ App Bar
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐ │
│  │ 👤 Select User to Track          │ │
│  ├───────────────────────────────────┤ │
│  │ [Select User ▼]                  │ │
│  │ [Select Session ▼]               │ │
│  │ ✓ User is currently punched in   │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │         MAP VIEW                  │ │
│  │                                   │ │
│  │  ┌─────────┐                     │ │
│  │  │ Legend  │                     │ │ Legend (top-right)
│  │  │ 🟢 In   │                     │ │
│  │  │ 🔴 Out  │                     │ │
│  │  │ 🔵 Now  │                     │ │
│  │  │ 🟠 Visit│                     │ │
│  │  │ ─ Route │                     │ │
│  │  └─────────┘                     │ │
│  │                                   │ │
│  │         🟢 ─────────── 🟠        │ │ Route with markers
│  │              ─────────            │ │
│  │                   ─── 🟠         │ │
│  │                      ───          │ │
│  │                         🔵        │ │ Current location
│  │                                   │ │
│  │  ┌─────────────────────────────┐ │ │
│  │  │ ⏱️ 4h 30m │ 🛣️ 12.5km      │ │ │ Statistics (bottom)
│  │  │ 📍 156    │ 📌 3 visits    │ │ │
│  │  │ ● Live Tracking Active      │ │ │
│  │  │ • Auto-refresh every 10s    │ │ │
│  │  └─────────────────────────────┘ │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## 🗺️ Map Markers Explained

### Active Session (User Punched In)
```
    🟢 Punch In (9:00 AM)
     │
     │ ─── Blue Route Line
     │
    🟠 Visit 1 (10:30 AM)
     │    "Client Office"
     │
     │ ─── Blue Route Line
     │
    🟠 Visit 2 (12:00 PM)
     │    "Store #123"
     │
     │ ─── Blue Route Line
     │
    🔵 Current Location (2:45 PM)
        Battery: 75%
        (Updates every 10s)
```

### Completed Session (User Punched Out)
```
    🟢 Punch In (9:00 AM)
     │
     │ ─── Blue Route Line
     │
    🟠 Visit 1 (10:30 AM)
     │
     │ ─── Blue Route Line
     │
    🟠 Visit 2 (12:00 PM)
     │
     │ ─── Blue Route Line
     │
    🔴 Punch Out (5:00 PM)
```

## 📊 Information Display

### Marker Info Windows (Click to View)

**Punch In Marker (Green)**
```
┌─────────────────────┐
│ 🟢 Punch In         │
│ 9:00 AM             │
└─────────────────────┘
```

**Current Location Marker (Blue)**
```
┌─────────────────────┐
│ 👤 Current Location │
│ Battery: 75%        │
│ 2:45 PM             │
└─────────────────────┘
```

**Visit Marker (Orange)**
```
┌─────────────────────┐
│ 📍 Client Office    │
│ Met with John       │
│ 10:30 AM            │
└─────────────────────┘
```

**Punch Out Marker (Red)**
```
┌─────────────────────┐
│ 🔴 Punch Out        │
│ 5:00 PM             │
└─────────────────────┘
```

## 🔄 Auto-Refresh Behavior

### Timeline View
```
Time    Event                   Map Update
────────────────────────────────────────────
9:00    User punches in         🟢 appears
9:01    User starts moving      ─ route starts
10:30   User marks visit        🟠 appears
        
        [Admin opens tracker]
        
2:45    Admin views map         Shows:
                                🟢 Punch in
                                ─ Route (9:00-2:45)
                                🟠 Visit
                                🔵 Current (2:45)
                                
2:46    (10s later)             🔵 moves
                                ─ route extends
                                
2:47    (10s later)             🔵 moves
                                ─ route extends
                                
3:00    User marks visit        🟠 appears (new)
                                
5:00    User punches out        🔵 disappears
                                🔴 appears
                                Auto-refresh stops
```

## 🎨 Color Coding

### Markers
- **Green (🟢)** - Start point (Punch In)
- **Red (🔴)** - End point (Punch Out)
- **Blue (🔵)** - Current location (Live)
- **Orange (🟠)** - Visits marked

### Route Line
- **Blue solid line** - Path traveled
- **Width: 5px** - Easy to see
- **Geodesic: true** - Follows Earth's curve

### Status Indicators
- **Green dot (●)** - Live tracking active
- **Green background** - User punched in
- **Gray** - Session completed

## 📱 User Actions

### What Admin Can Do

**1. Select User**
```
Click dropdown → Select user → Sessions load
```

**2. Select Session**
```
Click dropdown → Select session → Map updates
```

**3. View Current Location**
```
Active session → Blue marker shows current position
```

**4. View Visits**
```
Orange markers → Click for details
```

**5. Refresh Data**
```
Click 🔄 button → Manual refresh
OR
Wait 10s → Auto-refresh (active sessions)
```

**6. Zoom/Pan Map**
```
Pinch to zoom
Drag to pan
Click markers for info
```

## 📈 Statistics Explained

### Bottom Card Shows:

**Duration**
```
⏱️ 4h 30m
Total time from punch in to now/punch out
```

**Distance**
```
🛣️ 12.5km
Total distance traveled
```

**Points**
```
📍 156
Number of location updates recorded
```

**Visits**
```
📌 3 visits
Number of locations marked as visits
```

**Live Status** (Active sessions only)
```
● Live Tracking Active
• Auto-refresh every 10s
```

## 🔍 What Admin Sees

### Scenario 1: Field Worker
```
User: John (Sales Rep)
Status: Punched In (Active)

Map Shows:
🟢 Office (9:00 AM)
  ↓ 5km route
🟠 Client A (10:30 AM) - "Quarterly review"
  ↓ 8km route
🟠 Client B (1:00 PM) - "Product demo"
  ↓ 3km route
🔵 Current Location (2:45 PM)
   Battery: 75%

Stats:
⏱️ 5h 45m | 🛣️ 16km | 📍 345 | 📌 2 visits
● Live Tracking Active
```

### Scenario 2: Delivery Driver
```
User: Sarah (Driver)
Status: Punched In (Active)

Map Shows:
🟢 Warehouse (8:00 AM)
  ↓ 12km route
🟠 Stop 1 (9:15 AM) - "123 Main St"
  ↓ 5km route
🟠 Stop 2 (10:00 AM) - "456 Oak Ave"
  ↓ 8km route
🟠 Stop 3 (11:30 AM) - "789 Pine Rd"
  ↓ 6km route
🔵 Current Location (12:15 PM)
   Battery: 68%

Stats:
⏱️ 4h 15m | 🛣️ 31km | 📍 255 | 📌 3 visits
● Live Tracking Active
```

### Scenario 3: Completed Shift
```
User: Mike (Technician)
Status: Punched Out (Completed)

Map Shows:
🟢 Office (7:00 AM)
  ↓ 15km route
🟠 Site A (8:30 AM) - "Installation"
  ↓ 20km route
🟠 Site B (11:00 AM) - "Maintenance"
  ↓ 10km route
🟠 Site C (2:00 PM) - "Repair"
  ↓ 15km route
🔴 Office (4:00 PM)

Stats:
⏱️ 9h 0m | 🛣️ 60km | 📍 540 | 📌 3 visits
(No auto-refresh - session ended)
```

## 💡 Tips for Admins

### Best Practices

1. **Check Live Status**
   - Green indicator = User is working
   - No indicator = Session ended

2. **Monitor Battery**
   - Click current location marker
   - See battery percentage
   - Low battery? User may need to charge

3. **Verify Visits**
   - Click orange markers
   - Check visit notes
   - Confirm client visits

4. **Review Routes**
   - Blue line shows actual path
   - Check for unusual patterns
   - Verify work locations

5. **Use Refresh**
   - Manual refresh for immediate update
   - Auto-refresh for continuous monitoring

## 🎯 Quick Reference

### Marker Colors
| Color  | Meaning          | When Visible        |
|--------|------------------|---------------------|
| 🟢 Green | Punch In       | Always              |
| 🔴 Red   | Punch Out      | After punch out     |
| 🔵 Blue  | Current        | Active sessions     |
| 🟠 Orange| Visit          | When visits marked  |

### Update Frequency
| Type           | Frequency      | Condition           |
|----------------|----------------|---------------------|
| Auto-refresh   | Every 10s      | Active sessions     |
| Manual refresh | On demand      | Any time            |
| Route update   | With refresh   | When data changes   |

### Information Available
| Data Point     | Location       | Details             |
|----------------|----------------|---------------------|
| Duration       | Bottom card    | Total time          |
| Distance       | Bottom card    | Total distance      |
| Points         | Bottom card    | Location count      |
| Visits         | Bottom card    | Visit count         |
| Battery        | Current marker | Current level       |
| Time           | All markers    | Timestamp           |

## Summary

Admin tracking now provides:
✅ Real-time current location
✅ Complete route visualization
✅ Visit markers with details
✅ Auto-refresh every 10 seconds
✅ Clear color-coded markers
✅ Comprehensive statistics
✅ Easy-to-use interface

Everything an admin needs to monitor field workers effectively!
