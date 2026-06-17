# Users Mobile App

Flutter mobile application for smartphone users in the Workforce Connect platform. It supports worker registration, NIC/PIN login, profile management, job discovery, job posting, job applications, messaging, reviews, alerts, and Sinhala/Tamil/English localization.

## Main Folders

- `lib/screens/`: app screens and user flows.
- `lib/providers/`: Provider state management.
- `lib/services/`: Supabase, location, seed data, and SMS Gateway helpers.
- `lib/models/`: user, job, chat, and notification models.
- `assets/translations/`: `en.json`, `si.json`, `ta.json`.
- `assets/images/`: app images.

## Local Setup

```bash
flutter pub get
flutter run
```

## Supabase

Supabase configuration is in:

```text
lib/config/supabase_config.dart
```

The mobile app uses Supabase directly for users, jobs, applications, messages, chats, and reviews.

## SMS Gateway For Job Alerts

When a user posts a job, the app can notify matching workers by calling the SMS Gateway API directly.

Run with gateway values:

```bash
flutter run --dart-define=SMS_GATEWAY_API_KEY=your-sms-gateway-api-key --dart-define=SMS_GATEWAY_DEVICES=10959|1
```

Optional override:

```bash
--dart-define=SMS_GATEWAY_URL=https://app.sms-gateway.app/services/send.php
```

## Deployment

This is a mobile application, so it should be built for Android/iOS, not hosted on Render.

Example Android build:

```bash
flutter build apk --release --dart-define=SMS_GATEWAY_API_KEY=your-sms-gateway-api-key --dart-define=SMS_GATEWAY_DEVICES=10959|1
```

## Notes

- The mobile app does not call `SMS System` for SMS sending.
- `SMS System` is only for feature-phone/non-smartphone users who interact by SMS commands.
