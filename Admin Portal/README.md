# Admin Portal

Static HTML/CSS/JavaScript dashboard for platform administration. It reads data from Supabase, manages volunteers, approves pending requests, and can send test/broadcast SMS messages directly through the SMS Gateway API.

## Main Files

- `index.html`: admin dashboard layout.
- `admin.css`: dashboard styling.
- `admin.js`: Supabase reads, dashboard actions, volunteer management, approval workflows, and direct SMS Gateway sending.
- `location_data.js`: generated district and DS key catalog copied from the mobile app.
- `config.example.js`: safe template for local/deployment SMS Gateway config.

## Local Setup

Create a local `config.js` file from the example:

```powershell
copy config.example.js config.js
```

Then set:

```javascript
window.APP_CONFIG = {
  SMS_GATEWAY_URL: "https://app.sms-gateway.app/services/send.php",
  SMS_GATEWAY_API_KEY: "your-sms-gateway-api-key",
  SMS_GATEWAY_DEVICES: "10959|1"
};
```

Open `index.html` in a browser or serve the folder with any static file server.

## Deployment

Deploy this folder separately as a static site/web service. Do not deploy it as part of the SMS System.

For Render static hosting, publish this folder and provide a production `config.js` through your deployment process. Do not commit real gateway keys.

## Notes

- Supabase URL/key are currently defined in `admin.js`.
- SMS sending is done directly in `admin.js`.
- Admins can create/manage volunteers and can approve/reject the same pending registration and job-post requests volunteers handle.
- District and DS area values are saved as mobile-app-compatible keys.
- This portal does not depend on `SMS System`.
