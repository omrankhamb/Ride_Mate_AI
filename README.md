# RideMate AI

RideMate AI is a demo-ready shared auto ride matching system with separate Rider and Driver interfaces.

## Phase 1 Scope

- Rider signup and login
- Driver signup and login
- Role-based UI after login
- Driver online/offline status
- Rider ride request form
- Local backend API
- Local JSON database for fast MVP development

No KYC, payment gateway, admin dashboard, machine learning model, or production deployment is included in Phase 1.

## Folder Structure

```text
C:\Ai_mitra
├── backend
│   ├── data
│   └── src
├── database
├── docs
└── frontend
    ├── lib
    └── web
```

## Run Backend

```bash
node backend/src/server.js
```

Backend API:

```text
http://localhost:3000
```

## Run Flutter Frontend

Open another terminal:

```bash
cd C:\Ai_mitra\frontend
flutter run -d chrome --web-port=8080
```

Flutter app:

```text
http://localhost:8080
```

## Demo Accounts

Create accounts from the UI using either role:

- Rider
- Driver

The app stores demo data in:

```text
backend/data/db.json
```
