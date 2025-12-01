# Database Migration - Visit Table

## ⚠️ Error
```
The table `public.Visit` does not exist in the current database.
```

## ✅ Solution

You need to run the database migration to create the Visit table.

### Step 1: Stop Backend Server
Press `Ctrl+C` in the terminal where backend is running

### Step 2: Run Migration
Open a **NEW** terminal/command prompt and run:

```bash
cd backend
npx prisma migrate dev --name add_visits
```

This will:
1. Create the Visit table in database
2. Add all necessary columns
3. Create indexes
4. Generate Prisma client

### Step 3: Restart Backend
```bash
npm start
```

## Alternative: Manual SQL

If migration fails, you can run this SQL directly in your database:

```sql
-- Create Visit table
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
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Create indexes
CREATE INDEX "Visit_userId_visitTime_idx" ON "Visit"("userId", "visitTime");
CREATE INDEX "Visit_sessionId_idx" ON "Visit"("sessionId");
```

Then run:
```bash
cd backend
npx prisma generate
npm start
```

## Verification

After migration, verify the table exists:

```bash
cd backend
npx prisma studio
```

This opens a browser at http://localhost:5555
- Check if "Visit" model appears in the left sidebar
- If yes, migration successful!

## Quick Commands

**Windows (CMD):**
```cmd
cd backend
npx prisma migrate dev --name add_visits
npx prisma generate
npm start
```

**Windows (PowerShell):**
```powershell
cd backend
npx prisma migrate dev --name add_visits
npx prisma generate
npm start
```

## Expected Output

When migration succeeds, you should see:
```
✔ Generated Prisma Client
✔ The migration has been created successfully
✔ Applied migration: add_visits
```

## Troubleshooting

### Issue: "Migration failed"
**Solution:** Check if database is running and accessible

### Issue: "Cannot connect to database"
**Solution:** Check DATABASE_URL in .env file

### Issue: "Table already exists"
**Solution:** Table might already exist, just run:
```bash
npx prisma generate
```

## After Migration

Once migration is complete:
1. ✅ Visit table will be created
2. ✅ Backend will start without errors
3. ✅ "Mark Visit" feature will work
4. ✅ Visits will be saved to database
5. ✅ Admin can see visit markers on map

## Test After Migration

1. **User App:**
   - Punch in
   - Tap "Mark Visit"
   - Add location name and notes
   - Should see success message

2. **Admin Dashboard:**
   - Select user
   - Should see orange visit markers on map
   - Click markers to see visit details

## Summary

Run these 3 commands in backend folder:
```bash
npx prisma migrate dev --name add_visits
npx prisma generate
npm start
```

That's it! The Visit feature will work after migration.
