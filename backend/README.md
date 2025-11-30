## Backend setup

- Install dependencies (if not already):

```powershell
cd backend
npm install
```

- Create `.env` by copying `.env.example` and adding your values. Ensure `DATABASE_URL` is a valid Postgres connection string, without any leading `psql` prefix.

- Run database migrations:

```powershell
npm run migrate
```

- Seed the admin user (values come from `.env`):

```powershell
npm run seed
```

- Start the server (development):

```powershell
npm run dev
```

---

If `DATABASE_URL` is from a provider that includes a `psql` prefix, the server strips it automatically; still prefer the raw connection string.
