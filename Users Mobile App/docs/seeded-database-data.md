# Viva Demo Seed Data

Run from `Users Mobile App`:

```powershell
.\tool\seed_viva_demo_supabase.ps1
```

The script populates Supabase with Sinhala/Tamil viva demo data:

- 24 mobile users with Sinhala/Tamil script names and profile-photo URLs.
- 20 keyed jobs with Sinhala/Tamil titles, descriptions, categories, open, in-progress, and completed statuses.
- Applications, accepted workers, payments, reviews, chats, SMS logs, pending approvals, and volunteers.
- Legacy cleanup for old English demo rows such as `Build a house`, `Test Job`, and temporary form-import users.

Use `SUPABASE_SERVICE_ROLE_KEY` when available. Without it, Supabase RLS can block protected volunteer and pending-approval tables, but the mobile-visible user/job/review/SMS/chat seed data still updates.

Demo credentials:

| Role | ID / NIC | PIN / Password |
| --- | --- | --- |
| Admin Portal | `PIN` | `9421` |
| Sinhala mobile user | `200100000001` | `1234` |
| Tamil mobile user | `200200000001` | `1234` |
| Sinhala volunteer | `COL-SI-001` | `123456` |
| Tamil volunteer | `COL-TA-001` | `123456` |
