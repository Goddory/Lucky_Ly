# Lucky Ly Auth API (Secure)

## 1) Prepare database
Run:

1. `database/init_lucky_ly_postgres.sql` (root project)
2. `backend/database/add_auth_refresh_tokens.sql`

## 2) Configure env

```bash
cd backend
cp .env.example .env
```

Update `.env` with production-safe values.

## 3) Install and run

```bash
npm install
npm run dev
```

Server starts at `http://localhost:4000`.

## 4) Endpoints

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `GET /api/health`

## 5) Security implemented

- Password hashing with bcrypt
- JWT access token (short TTL)
- Opaque refresh token rotation + revoke
- SQL injection protection (parameterized query)
- Input validation with Zod
- Helmet security headers
- Rate limiting for auth routes
- Generic login error to reduce user enumeration
