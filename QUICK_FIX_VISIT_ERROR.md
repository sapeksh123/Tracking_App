# Quick Fix - Visit Table Error

## 🔴 Error Message
```
The table `public.Visit` does not exist in the current database.
```

## ✅ Quick Fix (3 Steps)

### 1. Stop Backend
Press `Ctrl+C` in backend terminal

### 2. Run Migration
```bash
cd backend
npx prisma migrate dev --name add_visits
```

### 3. Start Backend
```bash
npm start
```

## Done! ✅

Visit feature will now work:
- ✅ Mark Visit button works
- ✅ Visits saved to database
- ✅ Admin sees visit markers
- ✅ No more errors

## If Migration Fails

Run Prisma Studio to check:
```bash
cd backend
npx prisma studio
```

Open browser: http://localhost:5555
- Look for "Visit" in left sidebar
- If not there, migration didn't work

## Alternative: Reset Database

If nothing works, reset and migrate:
```bash
cd backend
npx prisma migrate reset
npx prisma migrate dev --name add_visits
npm run seed
npm start
```

⚠️ Warning: This will delete all data!

## Need Help?

Check `RUN_DATABASE_MIGRATION.md` for detailed instructions.
