# Viva Demo Seed Data

Use this for the viva-ready Supabase dataset:

```powershell
.\tool\seed_viva_demo_supabase.ps1
```

The script is idempotent. It upserts fixed demo rows, so running it again refreshes the same demo data instead of creating duplicate users and jobs.

The visible viva data is Sinhala/Tamil script data, not English/transliterated placeholder data. This includes mobile user names, job titles, job descriptions, categories, review comments, SMS logs, pending approvals, and chat messages.

## What It Seeds

- 24 mobile users: 12 Sinhala-script users and 12 Tamil-script users.
- 20 keyed jobs across construction, transport, agriculture, cleaning, repair, catering, beauty, trade, IT, fishing, care, arts, and security, written in Sinhala/Tamil.
- Applications, accepted workers, completed jobs, payment logs, reviews, chats, chat messages, SMS logs, pending user registrations, pending job posts, and volunteers.
- Profile photo URLs for every seeded user.
- District and DS values are stored as mobile-app-compatible keys.
- A small legacy cleanup step rewrites old demo rows such as `Build a house`, `Test Job`, and temporary form-import users into Sinhala/Tamil demo values if those rows still exist.

## Main Demo Logins

| Role | ID / NIC | PIN / Password |
| --- | --- | --- |
| Admin Portal | `PIN` | `9421` |
| Sinhala mobile user | `200100000001` | `1234` |
| Tamil mobile user | `200200000001` | `1234` |
| Sinhala volunteer | `COL-SI-001` | `123456` |
| Tamil volunteer | `COL-TA-001` | `123456` |

## Useful Demo Flow

1. Login to the mobile app as `200100000001 / 1234`.
2. Open Jobs and apply to a matching job.
3. Open Profile or Settings and update the profile photo.
4. Login to Admin Portal with PIN `9421` and show rich stats, users, jobs, volunteers, pending requests, SMS logs, and applications.
5. Login to Volunteer Panel as `COL-SI-001 / 123456` or `COL-TA-001 / 123456`, open a pending request, correct district/DS keys, and approve it.

## Notes

- The seed script uses `SUPABASE_SERVICE_ROLE_KEY` if it is set. If not, it uses `SUPABASE_ANON_KEY`, then falls back to the mobile app publishable key.
- For a production database, prefer the service role key when seeding.
- Without `SUPABASE_SERVICE_ROLE_KEY`, protected tables such as volunteers and pending approvals may be blocked by Supabase RLS. The mobile-visible users, jobs, reviews, SMS logs, and chats still seed with the current publishable key.
- Profile-photo upload needs the `profile-photos` storage bucket from `SMS System/supabase_schema.sql`.
- The live database already has working volunteer accounts such as `COL-SI-001 / 123456` and `COL-TA-001 / 123456`.
