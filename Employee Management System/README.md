# Employee Management System Setup

The Employee Management System is a PyQt6 desktop application for large employers to manage jobs, applications, and worker reviews.

## Requirements

- Python 3.9+
- PyQt6
- requests

## Installation

1. Install dependencies:
```bash
pip install PyQt6 requests
```

Or using the requirements file:
```bash
pip install -r requirements_ems.txt
```

2. Set environment variables:
```bash
# Linux/macOS
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
export BACKEND_URL="http://localhost:8000"

# Windows (PowerShell)
$env:SUPABASE_URL="https://your-project.supabase.co"
$env:SUPABASE_ANON_KEY="your-anon-key"
$env:BACKEND_URL="http://localhost:8000"
```

## Running the Application

```bash
python employee_management_system.py
```

The application will open a window with the employer management interface.

## Features

### Job Management
- Post new jobs with title, description, and location
- View all posted jobs with applicant counts
- Track job status (open, in_progress, completed, cancelled)

### Application Management
- View applications for each job
- Review applicant details
- Accept or reject applications
- Track application status

### Worker Reviews
- Submit reviews and ratings (1-5 stars) for workers
- Add comments to reviews
- View review history
- Edit existing reviews

## Architecture

The application communicates with the Supabase backend via REST APIs:

```
Employee Management System (PyQt6)
    ↓
Supabase REST API
    ↓
PostgreSQL Database
    └─ jobs, applications, reviews, users
```

## User Flow

1. **Employer Login**: Application prompts for employer NIC (currently hardcoded to "EMPLOYER001")
2. **Post Jobs**: Employer can quickly post jobs by filling in title, description, location
3. **View Applications**: Applications appear in real-time as workers apply via mobile app or SMS
4. **Manage Workers**: Employer can accept/reject applications and assign workers to tasks
5. **Submit Reviews**: After job completion, employer submits ratings and comments for workers

## Testing

### Test Job Posting:
1. Open the Employee Management System
2. Fill in job title, description, location
3. Click "Post Job"
4. Verify the job appears in the Jobs table
5. Verify the job appears in the mobile app within 1 minute

### Test Application Review:
1. Have a worker apply for a job via mobile app or SMS
2. In the Employee Management System, the application appears in the Applications tab
3. Review and accept/reject the application
4. Worker receives SMS notification of application status

### Test Reviews:
1. After a job is completed, enter worker NIC, rating, comment
2. Click "Submit Review"
3. Verify the review appears in the Reviews tab
4. Verify the worker's rating is updated in Supabase

## Architecture Notes

The Employee Management System is designed to work seamlessly with:
- **Flutter Mobile App**: Workers browse and apply for jobs posted here
- **SMS Gateway**: Feature phone users receive job alerts for jobs posted here
- **Volunteer Panel**: Volunteers can see and support workers matched to jobs
- **Supabase Backend**: All data is stored and synchronized in real-time

## Future Enhancements

1. **Worker Assignment**: Drag-and-drop interface to assign workers to job tasks
2. **Task Tracking**: Sub-tasks and milestones for each job
3. **Payment Tracking**: Record and track payments to workers
4. **Document Upload**: Upload contracts, photos, or proof-of-work
5. **Analytics Dashboard**: Charts for job completion rates, worker performance, revenue
6. **Mobile App for Employers**: iOS/Android app for on-the-go job management
7. **Integration with Accounting Software**: Export job records and payments to accounting systems
