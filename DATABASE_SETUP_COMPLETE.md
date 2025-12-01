# Complete Database Setup Guide

## 🔴 Error
```
The table `public.Admin` does not exist in the current database.
The table `public.Visit` does not exist in the current database.
```

## ✅ Solution: Run Migrations First

You need to create all database tables before seeding data.

## Step-by-Step Setup

### Step 1: Check Database Connection

Make sure your database is running and `.env` file has correct DATABASE_URL:

```env
DATABASE_URL="postgresql://username:password@localhost:5432/tracking_db"
```

### Step 2: Run Migrations (Creates All Tables)

```bash
cd backend
npx prisma migrate dev --name initial_setup
```

This will create ALL tables:
- Admin
- User
- Location
- TrackingData
- AttendanceSession
- Trip
- Visit

### Step 3: Generate Prisma Client

```bash
npx prisma generate
```

### Step 4: Seed Admin User

```bash
npm run db:seed
```

This creates the default admin:
- Email: admin@example.com
- Password: admin123

### Step 5: Start Backend

```bash
npm start
```

## Complete Commands (Copy-Paste)

```bash
cd backend
npx prisma migrate dev --name initial_setup
npx prisma generate
npm run db:seed
npm start
```

## If Migration Fails

### Option 1: Reset Database (Clean Start)

⚠️ Warning: This deletes all existing data!

```bash
cd backend
npx prisma migrate reset
npx prisma migrate dev --name initial_setup
npx prisma generate
npm run db:seed
npm start
```

### Option 2: Check Database Status

```bash
cd backend
npx prisma studio
```

Opens browser at http://localhost:5555
- Check if tables exist
- If not, run migrations again

### Option 3: Manual Database Creation

If Prisma migrations don't work, create database manually:

```sql
-- Connect to PostgreSQL and run:
CREATE DATABASE tracking_db;
```

Then run migrations:
```bash
cd backend
npx prisma migrate dev --name initial_setup
```

## Verify Setup

After running all commands, verify:

### 1. Check Tables Exist
```bash
npx prisma studio
```

Should see these models:
- ✅ Admin
- ✅ User
- ✅ Location
- ✅ TrackingData
- ✅ AttendanceSession
- ✅ Trip
- ✅ Visit

### 2. Check Admin User
In Prisma Studio:
- Click "Admin" model
- Should see 1 record
- Email: admin@example.com

### 3. Test Backend
```bash
npm start
```

Should see:
```
Server running on port 5000
```

No errors about missing tables.

## Common Issues

### Issue 1: "Cannot connect to database"
**Solution:** 
- Check PostgreSQL is running
- Check DATABASE_URL in .env
- Check database exists

### Issue 2: "Migration failed"
**Solution:**
- Delete `prisma/migrations` folder
- Run `npx prisma migrate dev --name initial_setup` again

### Issue 3: "Table already exists"
**Solution:**
- Run `npx prisma migrate reset`
- Then run migrations again

### Issue 4: "Permission denied"
**Solution:**
- Check database user has CREATE TABLE permission
- Check database user owns the database

## Database Schema

After migration, you'll have these tables:

### Admin
- id, email, password, name, createdAt

### User
- id, name, email, phone, password, role, isActive
- androidId, deviceModel, trackingConsent
- isPunchedIn, currentSession
- lastSeen, createdAt

### AttendanceSession
- id, userId, punchInTime, punchInLocation
- punchOutTime, punchOutLocation
- totalDistance, totalDuration, isActive

### Visit
- id, userId, sessionId
- latitude, longitude, address, notes
- visitTime, battery, createdAt

### TrackingData
- id, userId, androidId, sessionId
- latitude, longitude, battery
- accuracy, speed, timestamp

### Location
- id, userId, latitude, longitude
- accuracy, timestamp, metadata

### Trip
- id, userId, startedAt, endedAt
- startLat, startLng, endLat, endLng
- distanceMeters, summary

## Environment Variables

Make sure `.env` file exists in backend folder:

```env
DATABASE_URL="postgresql://postgres:password@localhost:5432/tracking_db"
JWT_SECRET="your-secret-key-here"
PORT=5000
```

## Testing After Setup

### 1. Test Admin Login
```bash
# Using curl or Postman
POST http://localhost:5000/auth/login
{
  "email": "admin@example.com",
  "password": "admin123"
}
```

Should return JWT token.

### 2. Test User Creation
Login to admin dashboard:
- Email: admin@example.com
- Password: admin123
- Create a test user

### 3. Test User Login
Login with test user credentials

### 4. Test Attendance
- Punch in
- Mark visit
- Punch out

### 5. Test Admin Tracking
- Admin dashboard
- Track user
- See live location

## Quick Reference

### Create Database
```bash
# PostgreSQL
createdb tracking_db

# Or in psql
CREATE DATABASE tracking_db;
```

### Run Migrations
```bash
cd backend
npx prisma migrate dev --name initial_setup
```

### Generate Client
```bash
npx prisma generate
```

### Seed Data
```bash
npm run db:seed
```

### Start Server
```bash
npm start
```

### Reset Everything
```bash
npx prisma migrate reset
npx prisma migrate dev --name initial_setup
npm run db:seed
npm start
```

## Summary

**Correct Order:**
1. ✅ Create database
2. ✅ Run migrations (creates tables)
3. ✅ Generate Prisma client
4. ✅ Seed admin user
5. ✅ Start backend

**Don't:**
- ❌ Seed before migrations
- ❌ Start server before migrations
- ❌ Skip Prisma generate

**Do:**
- ✅ Run migrations first
- ✅ Check tables exist (Prisma Studio)
- ✅ Then seed data
- ✅ Then start server

## Need Help?

If still having issues:
1. Check PostgreSQL is running
2. Check DATABASE_URL is correct
3. Try `npx prisma migrate reset`
4. Run migrations again
5. Check Prisma Studio to verify tables

## Success Indicators

✅ Migrations complete without errors
✅ Prisma Studio shows all 7 models
✅ Admin user created successfully
✅ Backend starts without errors
✅ Can login to admin dashboard
✅ Can create users
✅ Can track attendance
✅ Can mark visits

All done! 🎉
