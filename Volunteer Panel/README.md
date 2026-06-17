# Volunteer Panel

Static HTML/CSS/JavaScript panel for community volunteers. Volunteers can help non-technical users by reviewing pending registrations, approving/rejecting records, posting jobs on behalf of users, submitting applications, and adding reviews.

This panel uses Supabase directly. It does not depend on the `SMS System` FastAPI service.

## Main Files

- `index.html`: volunteer panel layout.
- `volunteer.css`: panel styling.
- `volunteer.js`: Supabase reads/writes and volunteer workflows.
- `config.js`: local/deployment Supabase config. This file is ignored by Git.

## Local Setup

Create `config.js` inside this folder:

```javascript
window.APP_CONFIG = {
  SUPABASE_URL: "https://your-project.supabase.co",
  SUPABASE_KEY: "your-supabase-anon-key"
};
```

Then open `index.html` in a browser or serve the folder with a static file server.

## Deployment

Deploy this folder separately as a static site/web service. For Render static hosting, publish this folder and provide `config.js` through the deployment environment or build step.

## Notes

- Keep `config.js` out of GitHub.
- Volunteer workflows write directly to Supabase.
- SMS for feature-phone users belongs in `SMS System`; this panel should not call SMS System endpoints.
