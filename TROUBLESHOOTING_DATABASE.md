# Database Troubleshooting Guide

## Common Errors & Solutions

### Error 1: "Table does not exist"
```
The table `public.Admin` does not exist
The table `public.Visit` does not exist
```

**Cause:** Migrations not run yet

**Solution:**
```bash
cd backend
npx prisma migrate dev --name initial_setup
npx prisma generate
```

---

### Error 2: "Cannot connect to database"
```
Can't reach database server at `localhost:5432`
```

**Cause:** PostgreSQL not running

**Solution:**
- **Windows:** Start PostgreSQL service
  - Services → PostgreSQL → Start
- **Mac:** `brew services start postgresql`
- **Linux:** `sudo systemctl start postgresql`

---

### Error 3: "Database does not exist"
```
Database 'tracking_db' does not exist
```

**Cause:** Database not created

**Solution:**
```bash
# PostgreSQL command line
createdb tracking_db

# Or in psql
psql -U postgres
CREATE DATABASE tracking_db;
\q
```

---

### Error 4: "Migration failed"
```
Migration failed to apply
```

**Cause:** Conflicting migrations or schema

**Solution:**
```bash
cd backend
npx prisma migrate reset
npx prisma migrate dev --name initial_setup
```

⚠️ This deletes all data!

---

### Error 5: "Authentication failed"
```
password authentication failed for user "postgres"
```

**Cause:** Wrong database credentials

**Solution:**
Check `.env` file:
```env
DATABASE_URL="postgresql://USERNAME:PASSWORD@localhost:5432/tracking_db"
```

Replace USERNAME and PASSWORD with your PostgreSQL credentials.

---

### Error 6: "Port 5432 already in use"
```
Port 5432 is already allocated
```

**Cause:** Another PostgreSQL instance running

**Solution:**
- Stop other PostgreSQL instances
- Or change port in DATABASE_URL

---

### Error 7: "Prisma Client not generated"
```
Cannot find module '@prisma/client'
```

**Cause:** Prisma client not generated

**Solution:**
```bash
cd backend
npx prisma generate
```

---

### Error 8: "Permission denied"
```
permission denied to create database
```

**Cause:** Database user lacks permissions

**Solution:**
```sql
-- In psql as superuser
ALTER USER your_username CREATEDB;
```

---

## Diagnostic Commands

### Check PostgreSQL Status
```bash
# Windows
sc query postgresql-x64-14

# Mac
brew services list | grep postgresql

# Linux
sudo systemctl status postgresql
```

### Check Database Exists
```bash
psql -U postgres -l
```

Should show `tracking_db` in the list.

### Check Tables Exist
```bash
cd backend
npx prisma studio
```

Opens http://localhost:5555
- Should see 7 models in sidebar
- If not, run migrations

### Check Prisma Client
```bash
cd backend
ls node_modules/@prisma/client
```

Should show files. If not, run `npx prisma generate`.

### Check Migrations
```bash
cd backend
ls prisma/migrations
```

Should show migration folders. If empty, run migrations.

---

## Complete Reset (Nuclear Option)

If nothing works, start fresh:

### Step 1: Drop Database
```sql
-- In psql
DROP DATABASE IF EXISTS tracking_db;
CREATE DATABASE tracking_db;
\q
```

### Step 2: Delete Migrations
```bash
cd backend
rm -rf prisma/migrations
# Windows: rmdir /s /q prisma\migrations
```

### Step 3: Run Fresh Migration
```bash
npx prisma migrate dev --name initial_setup
npx prisma generate
npm run db:seed
npm start
```

---

## Verification Checklist

After setup, verify:

- [ ] PostgreSQL is running
- [ ] Database `tracking_db` exists
- [ ] `.env` has correct DATABASE_URL
- [ ] Migrations folder exists
- [ ] Prisma client generated
- [ ] Prisma Studio shows 7 models
- [ ] Admin user exists
- [ ] Backend starts without errors
- [ ] Can access http://localhost:5000

---

## Quick Fixes

### Fix 1: Can't Connect
```bash
# Check PostgreSQL is running
# Windows: Services → PostgreSQL → Start
# Mac: brew services start postgresql
# Linux: sudo systemctl start postgresql
```

### Fix 2: Tables Missing
```bash
cd backend
npx prisma migrate dev --name initial_setup
npx prisma generate
```

### Fix 3: Admin Missing
```bash
cd backend
npm run db:seed
```

### Fix 4: Everything Broken
```bash
cd backend
npx prisma migrate reset
npx prisma migrate dev --name initial_setup
npx prisma generate
npm run db:seed
npm start
```

---

## Environment Setup

### .env File Template
```env
# Database
DATABASE_URL="postgresql://postgres:password@localhost:5432/tracking_db"

# JWT
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"

# Server
PORT=5000
NODE_ENV=development
```

### PostgreSQL Connection String Format
```
postgresql://USERNAME:PASSWORD@HOST:PORT/DATABASE
```

Example:
```
postgresql://postgres:admin123@localhost:5432/tracking_db
```

---

## Getting Help

### Check Logs
```bash
# Backend logs
cd backend
npm start

# PostgreSQL logs
# Windows: C:\Program Files\PostgreSQL\14\data\log
# Mac: /usr/local/var/log/postgresql@14.log
# Linux: /var/log/postgresql/postgresql-14-main.log
```

### Prisma Debug
```bash
cd backend
DEBUG=* npx prisma migrate dev
```

### Test Database Connection
```bash
cd backend
npx prisma db pull
```

If this works, connection is good.

---

## Success Indicators

✅ **PostgreSQL Running**
```bash
psql -U postgres -c "SELECT version();"
```

✅ **Database Exists**
```bash
psql -U postgres -l | grep tracking_db
```

✅ **Tables Created**
```bash
npx prisma studio
# Shows 7 models
```

✅ **Backend Running**
```bash
curl http://localhost:5000
# Returns: {"ok":true,"message":"Tracking backend Running Successfully !!"}
```

✅ **Admin Exists**
```bash
# In Prisma Studio
# Admin model shows 1 record
```

---

## Summary

**Most Common Issue:** Migrations not run

**Quick Fix:**
```bash
cd backend
npx prisma migrate dev --name initial_setup
npx prisma generate
npm run db:seed
npm start
```

**If That Fails:**
```bash
npx prisma migrate reset
npx prisma migrate dev --name initial_setup
npx prisma generate
npm run db:seed
npm start
```

**Still Failing?**
1. Check PostgreSQL is running
2. Check DATABASE_URL in .env
3. Check database exists
4. Try complete reset (see above)

---

## Contact Points

If you're still stuck:
1. Check `DATABASE_SETUP_COMPLETE.md`
2. Check `FIX_DATABASE_NOW.md`
3. Check PostgreSQL logs
4. Check backend console output
5. Try Prisma Studio to see what exists

Good luck! 🚀
