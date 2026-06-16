# W+ Backend API

NestJS backend for W+ Creator Economy platform.

## Stack

- **NestJS** — REST API + WebSocket
- **PostgreSQL** — main database
- **Redis** — live viewer counts, cache
- **Socket.IO** — realtime events (`stream.comment`, `stream.gift`, `stream.donation`, `battle.*`)
- **LiveKit** — streaming tokens (stub in dev when not configured)

## Quick Start

```bash
# 1. Start PostgreSQL + Redis
cd backend
docker compose up -d

# 2. Install & configure
cp .env.example .env
npm install

# 3. Seed test data
npm run seed

# 4. Run API
npm run start:dev
```

API: `http://localhost:3000`  
WebSocket: `ws://localhost:3000/streams`

## Test Accounts

| Email | Password | Role |
|-------|----------|------|
| creator@wplus.dev | password123 | Creator (Rita) |
| user@wplus.dev | password123 | Creator (You) |
| viewer@wplus.dev | password123 | User |
| admin@wplus.dev | admin123 | Admin |

## Phase 1 API Endpoints

### Auth
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`

### Wallet (idempotent transactions)
- `GET /api/wallet`
- `GET /api/wallet/transactions`
- `POST /api/wallet/topup` — requires `idempotencyKey`

### Gifts
- `GET /api/gifts`
- `POST /api/gifts/send` — requires `idempotencyKey`

### Donations
- `POST /api/donations` — requires `idempotencyKey`

### Streams
- `GET /api/streams/live`
- `GET /api/streams/stats`
- `POST /api/streams` — create
- `POST /api/streams/:id/start` — returns LiveKit token
- `POST /api/streams/:id/join` — viewer join
- `POST /api/streams/:id/comments`
- `POST /api/streams/:id/end`

### AI
- `POST /api/ai/generate-comment`

### Battles
- `GET /api/battles/opponents`
- `POST /api/battles/start`
- `GET /api/battles/leaderboard`

### Dashboard
- `GET /api/dashboard`

## WebSocket Events

Namespace: `/streams`

| Event | Direction | Description |
|-------|-----------|-------------|
| `stream.join` | client → server | Join stream room |
| `stream.comment` | server → client | New comment |
| `stream.gift` | server → client | Gift animation |
| `stream.donation` | server → client | Donation |
| `stream.viewer_count` | server → client | Viewer count update |
| `stream.ended` | server → client | Stream ended |
| `battle.started` | server → client | Battle started |
| `battle.score_update` | server → client | Score update |
| `battle.ended` | server → client | Battle ended |

## LiveKit Integration

Set in `.env`:
```
LIVEKIT_URL=wss://your-livekit.cloud
LIVEKIT_API_KEY=...
LIVEKIT_API_SECRET=...
```

Without these, stub tokens are returned for UI development.

## Financial Rules (from TZ)

- All payments go through `transactions` table
- Every debit/credit uses `idempotencyKey` — duplicate requests are safe
- Platform commission: 15% (configurable via `PLATFORM_COMMISSION`)
- Balance cannot go negative
