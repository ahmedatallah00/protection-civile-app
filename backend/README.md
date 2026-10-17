# Protection Civile Backend

## Prerequisites
- Node.js >= 18
- MongoDB (running on localhost:27017)

## Setup
```bash
cd backend
npm install
```

## Run
```bash
# Start MongoDB first (if not running as service):
# mongod --dbpath C:\data\db

# Seed sample data:
npm run seed

# Start server:
npm start
```

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /auth/register | No | Register new user |
| POST | /auth/login | No | Login (CIN/phone/email + password) |
| GET | /auth/me | Yes | Get current user |
| PUT | /auth/me | Yes | Update profile |
| DELETE | /auth/me | Yes | Deactivate account |
| GET | /incidents | Yes | List incidents |
| POST | /incidents | Yes | Report incident (multipart/form-data) |
| GET | /incidents/mine | Yes | Get user's incidents |
| GET | /alerts | No | Get all active alerts |
| GET | /alerts/zone/:governorate | No | Get alerts for a governorate |
| GET | /health | No | Health check |

## Test User (after seeding)
- **CIN**: AA123456
- **Email**: test@example.com  
- **Password**: password123
