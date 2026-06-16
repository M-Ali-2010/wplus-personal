# W+ — Creator Economy Platform

Flutter mobile app + NestJS backend for live streams, GIF gifts, donations, AI battles, and wallet.

## Project Structure

```
WPlus/
├── lib/              # Flutter app (UI + API client)
├── backend/          # NestJS API + WebSocket + PostgreSQL
└── ТЗ/               # Technical specification (PDF, presentation, mockups)
```

## Quick Start

### 1. Backend

```bash
cd backend
docker compose up -d          # PostgreSQL + Redis
cp .env.example .env
npm install
npm run seed                # Test accounts + 16 gifts
npm run start:dev           # http://localhost:3000
```

### 2. Flutter App

```bash
flutter pub get
flutter run
```

The app connects to `http://localhost:3000` (iOS sim) or `http://10.0.2.2:3000` (Android emulator).

Toggle mock mode in `lib/core/config/app_config.dart` → `useBackend = false`.

## Phase 1 Features (Updated)

- **Auth** — Login / Register screens (JWT)
- **Live Streams** — LiveKit SDK + local camera fallback (stub mode)
- **GIF Gifts** — 16 gifts with animated rendering
- **Donate Instead of Like**
- **Paid Messages** — Highlighted chat messages (5 W)
- **Premium / Subscriptions** — Subscribe + premium posts
- **Internal Wallet** (W coins, top-up, transactions)
- **AI Chat Bots** (mock AI / OpenAI ready)
- **AI Battles** (Classic / Speed / Survival)
- **Creator Dashboard**
- **Admin Panel** — `admin_panel/index.html`
- **WebSocket realtime** (comments, gifts, donations, paid messages, battles)

## Test Accounts

| Email | Password | Role |
|-------|----------|------|
| user@wplus.dev | password123 | Creator |
| creator@wplus.dev | password123 | Creator (Rita) |
| viewer@wplus.dev | password123 | Viewer |
| admin@wplus.dev | admin123 | Admin |

## Admin Panel

Open `admin_panel/index.html` in browser (backend must be running on :3000).

## Next Steps

- LiveKit Cloud credentials in `.env` for production video
- OpenAI for AI comments
- Firebase push notifications
- Integration into client's social network app

See `backend/README.md` for full API documentation.
