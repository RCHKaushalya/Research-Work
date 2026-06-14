# Google Forms Integration Setup

This document describes how to set up Google Forms for job posting and user registration, with automatic syncing to Supabase via Zapier webhooks.

## Overview

The Workforce Platform supports two Google Forms:
1. **Job Posting Form** - For employers to post jobs without needing a mobile app
2. **User Registration Form** - For workers to register without needing the mobile app (SMS-assisted)

Both forms integrate with the backend via Zapier, which automatically syncs submissions to Supabase.

## Architecture

```
Google Form
    ↓
Google Sheets (auto-captured)
    ↓
Zapier (webhook trigger)
    ↓
Backend API (/forms/job-posting or /forms/user-registration)
    ↓
Supabase PostgreSQL
```

## Step 1: Create Google Form for Job Posting

### Form Fields:
1. **Employer Name** (Short answer) - Required
2. **Employer Phone** (Short answer) - Required
3. **Job Title** (Short answer) - Required
4. **Job Description** (Long answer) - Required
5. **Location/District** (Short answer) - Required
6. **Category** (Multiple choice or Short answer) - Optional
7. **Required Skills** (Long answer, comma-separated) - Optional

### Setup Instructions:
1. Go to [Google Forms](https://forms.google.com/)
2. Create a new form titled "Workforce Platform - Job Posting"
3. Add the fields listed above
4. In the form settings, enable "Collect email addresses" but don't require it
5. Set the form to "Accepting responses"
6. Note the form URL (share link)

## Step 2: Create Google Form for User Registration

### Form Fields:
1. **Phone Number** (Short answer) - Required
   - Pattern: `^\+?[0-9\-\s]{7,}$`
2. **First Name** (Short answer) - Required
3. **Last Name** (Short answer) - Required
4. **District** (Multiple choice dropdown) - Required
   - Options: Colombo, Gampaha, Kalutara, Matara, Galle, Hamantota, Jaffna, Mullaitivu, Batticaloa, Ampara, Trincomalee, Matara, Kandy, Matale, Nuwara Eliya, Kegalle, Kurunegala, Puttalam, Anuradhapura, Polonnaruwa, Monaragala, Ratnapura, Kegalle
5. **DS Area** (Short answer) - Optional
6. **Preferred Language** (Radio buttons) - Optional
   - Options: Sinhala (si), Tamil (ta), English (en)

### Setup Instructions:
1. Go to [Google Forms](https://forms.google.com/)
2. Create a new form titled "Workforce Platform - User Registration"
3. Add the fields listed above
4. Set the form to "Accepting responses"
5. Note the form URL (share link)

## Step 3: Set Up Zapier Integration

### For Job Posting Form:

1. Go to [Zapier](https://zapier.com/) and sign in
2. Create a new Zap:
   - **Trigger**: Google Forms → Form submission
   - **Select Form**: Choose your "Job Posting" form
3. Create Action:
   - **App**: Webhooks by Zapier
   - **Action**: POST
   - **URL**: `http://{YOUR_BACKEND_URL}/forms/job-posting`
   - **Payload Type**: JSON
   - **Data**:
     ```json
     {
       "employer_name": "{{First Name|1}}",
       "employer_phone": "{{Phone Number|2}}",
       "job_title": "{{Job Title|3}}",
       "job_description": "{{Job Description|4}}",
       "location": "{{Location|5}}",
       "category": "{{Category|6}}",
       "required_skills": "{{Required Skills|7}}"
     }
     ```
4. Test the zap and turn it on

### For User Registration Form:

1. Create a new Zap in Zapier:
   - **Trigger**: Google Forms → Form submission
   - **Select Form**: Choose your "User Registration" form
2. Create Action:
   - **App**: Webhooks by Zapier
   - **Action**: POST
   - **URL**: `http://{YOUR_BACKEND_URL}/forms/user-registration`
   - **Payload Type**: JSON
   - **Data**:
     ```json
     {
       "phone_number": "{{Phone Number|1}}",
       "first_name": "{{First Name|2}}",
       "last_name": "{{Last Name|3}}",
       "district": "{{District|4}}",
       "ds_area": "{{DS Area|5}}",
       "language": "{{Language|6}}"
     }
     ```
3. Test the zap and turn it on

## Backend Endpoints

### POST /forms/job-posting
Receives job posting form submissions from Zapier.

**Request Body:**
```json
{
  "employer_name": "John Silva",
  "employer_phone": "+94771234567",
  "job_title": "Construction Worker",
  "job_description": "Looking for experienced construction workers for residential project",
  "location": "Colombo",
  "category": "Construction",
  "required_skills": "Carpentry, Safety Awareness"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Job posted successfully via Google Form"
}
```

### POST /forms/user-registration
Receives user registration form submissions from Zapier.

**Request Body:**
```json
{
  "phone_number": "+94771234567",
  "first_name": "Priya",
  "last_name": "Kumari",
  "district": "Colombo",
  "ds_area": "Colombo North",
  "language": "si"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Registration submitted, pending volunteer verification"
}
```

## Testing

### Test Job Posting Form:
1. Fill out the job posting form
2. Check Zapier logs to confirm the webhook was sent
3. Check Supabase console under `jobs` table to see the new job
4. Verify job appears in the mobile app within 1 minute

### Test User Registration Form:
1. Fill out the user registration form with a test phone number
2. Check Zapier logs to confirm the webhook was sent
3. Check Supabase console under `users` table to see the pending user
4. Confirm SMS is sent to the phone number
5. Go to volunteer panel and verify the pending registration appears
6. Volunteer approves the registration, and user receives PIN via SMS

## Troubleshooting

### Zapier webhook not triggering:
- Check that the form is set to "Accepting responses"
- Check Zapier task history for errors
- Verify the backend URL is correct and accessible

### Data not appearing in Supabase:
- Check backend logs for any errors
- Verify Supabase credentials in environment variables
- Ensure the Supabase project has the correct schema tables

### SMS not being sent:
- Verify SMS gateway is configured properly
- Check backend SMS logs
- Verify phone number format

## Future Enhancements

1. **Automatic NIC Assignment**: When a volunteer verifies a user from Google Forms, assign a proper NIC
2. **Email Notifications**: Send confirmation emails to employers when jobs are posted
3. **Response Handling**: Allow workers to apply to jobs via SMS reply to alerts
4. **Form Analytics**: Track conversion rates from form submission to registration completion
