# Workforce Connect

Workforce Connect is a multi-modal employment platform for Sri Lanka's informal workforce. The project is based on the research report in `report.txt`: the system is designed for workers with different levels of digital access, from smartphone users to feature-phone users who only use SMS.

## Project Purpose

The platform helps informal workers register, manage their profiles, discover jobs, apply for work, receive alerts, and communicate with employers. It supports Sinhala, Tamil, and English, uses NIC/PIN-style identity instead of email-first access, and stores shared data in Supabase PostgreSQL.

## Systems

```text
Workforce Platform/
├── Users Mobile App/              Flutter mobile app for smartphone users
├── SMS System/                    FastAPI SMS portal for feature-phone users
├── Volunteer Panel/               Web panel for volunteer-assisted support
├── Admin Portal/                  Web dashboard for platform administration
├── Employee Management System/    PyQt6 desktop employer portal
├── report.txt                     Research report and source of truth
└── render.yaml                    Render blueprint for SMS System
```

## Architecture

- Flutter Mobile App -> Supabase REST/Realtimes APIs.
- SMS System -> SMS Gateway API + Supabase.
- Volunteer Panel -> Supabase REST API.
- Admin Portal -> Supabase REST API + direct SMS Gateway sending.
- Employee Management System -> Supabase REST API + direct SMS Gateway sending.
- Google Forms/Sheets flow is described in the report as a low-barrier registration/job-posting channel and should sync into Supabase outside the SMS System folder.

## Hosting Plan

- `SMS System`: deploy as a Python web service on Render.
- `Admin Portal`: deploy separately as a static web service/site.
- `Volunteer Panel`: deploy separately as a static web service/site.
- `Users Mobile App`: build/install as a mobile app, not a Render service.
- `Employee Management System`: PyQt6 desktop application. It should be run locally or packaged for desktop users; Render is not suitable for hosting a GUI desktop app without converting it to a web app.

## Environment And Secrets

Do not commit real secrets. Use local `.env` files or ignored `config.js` files:

- `SMS System/.env`
- `Employee Management System/.env`
- `Admin Portal/config.js`
- `Volunteer Panel/config.js`

Safe examples are provided where appropriate as `.env.example` or `config.example.js`.

## Local Virtual Environments

Keep Python virtual environments inside the Python system folders only:

```text
SMS System/.venv/
Employee Management System/.venv/
```

There should be no root-level `.venv`.

## Shared Backend

Supabase is the shared backend for:

- users
- jobs
- applications
- messages
- reviews
- SMS message logs where used

The schema used by the SMS service is in `SMS System/supabase_schema.sql`.
