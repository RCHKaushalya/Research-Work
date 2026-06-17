# SMS System

FastAPI service for feature-phone and non-smartphone users. This system receives SMS Gateway webhooks, reads plain SMS commands, updates Supabase, and sends SMS replies through the SMS Gateway API.

This folder is only for SMS users. Admin Portal, Volunteer Panel, Google Forms, Employee Management System, and the mobile app should send their own SMS messages inside their own codebases when needed.

## User SMS Commands

```text
HELP
REG 991234567V Nimal Perera
PROFILE
NAME Nimal Perera
AREA Colombo | Maharagama
SKILL plumbing,wiring,driving
POST Painter needed | Colombo | Paint one room tomorrow
JOBS
APPLY A1B2C3
MYJOBS
APPROVE A1B2C3 991234567V
REJECT A1B2C3 991234567V
CLOSE A1B2C3
```

## Response Language

- If the sender phone number is already registered, replies use that user's saved `language` value from Supabase: `si`, `ta`, or `en`.
- If the phone number is not registered, replies use Sinhala and Tamil together.
- SMS command words stay in English uppercase, such as `REG`, `JOBS`, `APPLY`, `APPROVE`, and `REJECT`, because those are the parser commands.

## Main Files

- `main.py`: FastAPI app, webhook handler, SMS command processing.
- `supabase_service.py`: Supabase REST helper functions.
- `supabase_schema.sql`: database schema used by the platform.
- `.env.example`: safe environment variable template.
- `requirements.txt`: Python dependencies.

## Local Setup

```powershell
cd "SMS System"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Open:

```text
http://localhost:8000/docs
```

## Required Environment Variables

```text
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
SMS_GATEWAY_API_KEY=
SMS_GATEWAY_WEBHOOK_KEY=
SMS_GATEWAY_SEND_URL=https://app.sms-gateway.app/services/send.php
SMS_GATEWAY_DEVICES=10959|1
DEFAULT_COUNTRY_CODE=+94
ADMIN_API_KEY=
```

## Render Deployment

Deploy this folder as a Render Python web service.

Build command:

```text
pip install -r requirements.txt
```

Start command:

```text
uvicorn main:app --host 0.0.0.0 --port $PORT
```

Webhook URL for SMS Gateway:

```text
https://your-sms-system.onrender.com/sms/webhook
```

## API Endpoints

- `GET /health`: configuration status.
- `GET /commands`: supported SMS commands.
- `POST /sms/webhook`: real SMS Gateway webhook endpoint.
- `POST /sms/incoming`: local/admin test endpoint.

Render or uptime checks may call `HEAD /` or `HEAD /health`; those are supported and are not SMS messages. Real inbound SMS messages must appear as `POST /sms/webhook` in the Render logs.
