# Fix Database - One Command

## 🔴 Problem
Tables don't exist in database

## ✅ Quick Fix

Run this ONE command in backend folder:

```bash
npx prisma migrate dev --name initial_setup && npx prisma generate && npm run db:seed && npm start
```

This will:
1. Create all database tables
2. Generate Prisma client
3. Create admin user
4. Start backend server

## Or Step by Step

If the one-liner doesn't work, run these commands one by one:

```bash
cd backend
npx prisma migrate dev --name initial_setup
npx prisma generate
npm run db:seed
npm start
```

## Expected Output

```
✔ Generated Prisma Client
✔ The migration has been created successfully
✔ Applied migration: initial_setup

Admin user created:
Email: admin@example.com
Password: admin123

Server running on port 5000
```

## If It Fails

Reset and try again:

```bash
npx prisma migrate reset
npx prisma migrate dev --name initial_setup
npx prisma generate
npm run db:seed
npm start
```

## Verify Success

Open browser: http://localhost:5555
```bash
npx prisma studio
```

Should see 7 models:
- Admin ✅
- User ✅
- AttendanceSession ✅
- Visit ✅
- TrackingData ✅
- Location ✅
- Trip ✅

## Done!

Backend is ready. Now you can:
- Login to admin dashboard
- Create users
- Track attendance
- Mark visits

## Login Credentials

**Admin Dashboard:**
- Email: admin@example.com
- Password: admin123
