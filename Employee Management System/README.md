# Employee Management System

PyQt6 desktop application for large employers. It lets an employer post jobs, view worker requests, accept/reject applications, manage worker groups, log payments, send direct chat messages, send SMS messages, and submit reviews.

This is a desktop system, not the shared backend. It uses Supabase directly and sends SMS through the SMS Gateway API inside this codebase.

## Main Files

- `main.py`: organized app entry point.
- `app/config.py`: environment loading, Supabase headers, SMS Gateway helper.
- `app/ui/dashboard.py`: employer dashboard, jobs, workers, requests, reviews.
- `employee_management_system.py`: older single-file version kept for compatibility.
- `.env.example`: safe local configuration template.

## Local Setup

```powershell
cd "Employee Management System"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
python main.py
```

## Required Environment Variables

```text
SUPABASE_URL=
SUPABASE_ANON_KEY=
SMS_GATEWAY_URL=https://app.sms-gateway.app/services/send.php
SMS_GATEWAY_API_KEY=
SMS_GATEWAY_DEVICES=10959|1
DEFAULT_COUNTRY_CODE=+94
```

## SMS Behavior

The EMS sends SMS directly to the SMS Gateway API when:

- a new job is posted and matching workers need a job alert
- an employer sends a direct SMS to a worker from the worker messaging dialog

It does not call the `SMS System` FastAPI service.

## Hosting Note

This application is PyQt6 desktop software. It should be run locally or packaged as a desktop executable for employers. Render is for web services/static sites, so hosting this GUI app directly on Render is not recommended unless the EMS is converted into a web app.
