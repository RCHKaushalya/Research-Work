#!/usr/bin/env python3
"""
Demo Data Seeding Script for Workforce Platform
Populates Supabase with realistic demo data for testing and demonstrations.
"""

import os
import json
import random
from datetime import datetime, timedelta
from typing import List, Dict, Any
import requests

from pathlib import Path

# Load local environment variables
_ENV_FILE = Path(__file__).parent / ".env"
if _ENV_FILE.exists():
    for raw_line in _ENV_FILE.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://your-project.supabase.co")
# Try service role key, fall back to anon key
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
if not SUPABASE_SERVICE_ROLE_KEY:
    SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_ANON_KEY", "")

def api_headers():
    return {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
    }

# Demo Data
DEMO_USERS = [
    {
        "nic": "199512345678",
        "first_name": "Priya",
        "last_name": "Kumari",
        "phone": "+94771234567",
        "district": "Colombo",
        "ds_area": "Colombo North",
        "language": "ta",
        "verified": True,
        "rating": 4.5,
        "completed_jobs_count": 12,
        "abandoned_jobs_count": 1,
        "posted_jobs_count": 0,
        "applied_jobs_count": 8,
    },
    {
        "nic": "198612349876",
        "first_name": "Saman",
        "last_name": "Silva",
        "phone": "+94772567890",
        "district": "Gampaha",
        "ds_area": "Gampaha North",
        "language": "si",
        "verified": True,
        "rating": 4.8,
        "completed_jobs_count": 25,
        "abandoned_jobs_count": 0,
        "posted_jobs_count": 0,
        "applied_jobs_count": 30,
    },
    {
        "nic": "199801234567",
        "first_name": "Annika",
        "last_name": "Fernandez",
        "phone": "+94773456789",
        "district": "Matara",
        "ds_area": "Matara South",
        "language": "en",
        "verified": True,
        "rating": 4.2,
        "completed_jobs_count": 8,
        "abandoned_jobs_count": 2,
        "posted_jobs_count": 0,
        "applied_jobs_count": 15,
    },
    {
        "nic": "199602348765",
        "first_name": "Mohammed",
        "last_name": "Rasheed",
        "phone": "+94774567891",
        "district": "Kandy",
        "ds_area": "Kandy Central",
        "language": "en",
        "verified": True,
        "rating": 4.9,
        "completed_jobs_count": 35,
        "abandoned_jobs_count": 0,
        "posted_jobs_count": 0,
        "applied_jobs_count": 40,
    },
    {
        "nic": "199512346789",
        "first_name": "Lakshmi",
        "last_name": "Patel",
        "phone": "+94775123456",
        "district": "Colombo",
        "ds_area": "Colombo South",
        "language": "ta",
        "verified": False,  # Pending verification
        "rating": 0.0,
        "completed_jobs_count": 0,
        "abandoned_jobs_count": 0,
        "posted_jobs_count": 0,
        "applied_jobs_count": 0,
    },
]

DEMO_EMPLOYERS = [
    {
        "nic": "EMPLOYER001",
        "first_name": "Rajesh",
        "last_name": "Construction Ltd",
        "phone": "+94779999999",
        "district": "Colombo",
        "ds_area": "Colombo West",
        "language": "si",
        "verified": True,
        "rating": 4.6,
    },
    {
        "nic": "EMPLOYER002",
        "first_name": "Green",
        "last_name": "Agriculture Co",
        "phone": "+94778888888",
        "district": "Kandy",
        "ds_area": "Kandy Rural",
        "language": "en",
        "verified": True,
        "rating": 4.3,
    },
]

DEMO_JOBS = [
    {
        "title": "Construction Worker - Residential Project",
        "description": "Experienced construction worker needed for residential building project in Colombo. 3 months duration. Must have experience with concrete work and safety compliance.",
        "employer_nic": "EMPLOYER001",
        "location": "Colombo",
        "category": "Construction",
        "status": "open",
        "required_skills": ["Concrete Work", "Safety Compliance", "Team Work"],
        "applied_worker_ids": ["199512345678", "198612349876"],
        "accepted_worker_ids": ["198612349876"],
    },
    {
        "title": "Farm Labor - Tea Plantation",
        "description": "Tea plantation workers needed for harvesting season. Daily wages, flexible hours. No experience necessary but willingness to learn required.",
        "employer_nic": "EMPLOYER002",
        "location": "Kandy",
        "category": "Agriculture",
        "status": "open",
        "required_skills": ["Physical Stamina", "Farm Work"],
        "applied_worker_ids": ["199801234567", "199512346789"],
        "accepted_worker_ids": ["199801234567"],
    },
    {
        "title": "Electrician - Building Wiring",
        "description": "Electrician needed for building wiring project. Must be experienced with low-voltage and high-voltage systems. License/certification required.",
        "employer_nic": "EMPLOYER001",
        "location": "Colombo",
        "category": "Electrical",
        "status": "in_progress",
        "required_skills": ["Electrical Work", "Safety", "Wire Management"],
        "applied_worker_ids": ["199602348765", "199512345678", "198612349876"],
        "accepted_worker_ids": ["199602348765", "198612349876"],
    },
    {
        "title": "Domestic Helper - House Cleaning",
        "description": "Part-time domestic helper needed for house cleaning services. 3 days per week. Must be reliable and trustworthy.",
        "employer_nic": "EMPLOYER002",
        "location": "Colombo",
        "category": "Domestic Service",
        "status": "completed",
        "required_skills": ["Cleaning", "Reliability"],
        "applied_worker_ids": ["199512345678"],
        "accepted_worker_ids": ["199512345678"],
    },
]

DEMO_APPLICATIONS = [
    {
        "job_id_idx": 0,
        "worker_nic": "199512345678",
        "status": "applied",
    },
    {
        "job_id_idx": 0,
        "worker_nic": "198612349876",
        "status": "accepted",
    },
    {
        "job_id_idx": 1,
        "worker_nic": "199801234567",
        "status": "accepted",
    },
    {
        "job_id_idx": 1,
        "worker_nic": "199512346789",
        "status": "applied",
    },
    {
        "job_id_idx": 2,
        "worker_nic": "199602348765",
        "status": "accepted",
    },
    {
        "job_id_idx": 2,
        "worker_nic": "199512345678",
        "status": "applied",
    },
    {
        "job_id_idx": 2,
        "worker_nic": "198612349876",
        "status": "accepted",
    },
]

DEMO_REVIEWS = [
    {
        "reviewer_nic": "EMPLOYER001",
        "worker_nic": "199512345678",
        "rating": 4.5,
        "comment": "Good work, reliable, but sometimes came in late.",
    },
    {
        "reviewer_nic": "EMPLOYER001",
        "worker_nic": "198612349876",
        "rating": 4.9,
        "comment": "Excellent work quality, very professional, always on time.",
    },
    {
        "reviewer_nic": "EMPLOYER002",
        "worker_nic": "199801234567",
        "rating": 4.7,
        "comment": "Very reliable, good work ethic, learns quickly.",
    },
]


def seed_users():
    """Seed demo users into Supabase."""
    print("Seeding users...")
    all_users = DEMO_USERS + DEMO_EMPLOYERS
    
    for user in all_users:
        try:
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/users",
                headers=api_headers(),
                json={
                    **user,
                    "password_hash": "demo_password_hash",
                    "profile_photo_url": None,
                    "created_at": (datetime.utcnow() - timedelta(days=random.randint(1, 30))).isoformat() + "Z",
                },
                timeout=10
            )
            if response.status_code in [201, 409]:  # 201 = created, 409 = conflict (already exists)
                print(f"  [OK] {user['first_name']} {user['last_name']}")
            else:
                print(f"  [FAIL] {user['first_name']} {user['last_name']}: {response.status_code}")
        except Exception as e:
            print(f"  [FAIL] {user['first_name']} {user['last_name']}: {e}")


def seed_jobs():
    """Seed demo jobs into Supabase."""
    print("\nSeeding jobs...")
    
    for job in DEMO_JOBS:
        try:
            job_data = {
                **job,
                "created_at": (datetime.utcnow() - timedelta(days=random.randint(1, 30))).isoformat() + "Z",
            }
            
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/jobs",
                headers=api_headers(),
                json=job_data,
                timeout=10
            )
            
            if response.status_code == 201:
                print(f"  [OK] {job['title']}")
            else:
                print(f"  [FAIL] {job['title']}: {response.status_code}")
        except Exception as e:
            print(f"  [FAIL] {job['title']}: {e}")


def seed_applications():
    """Seed demo applications into Supabase."""
    print("\nSeeding applications...")
    
    # First, get all job IDs from Supabase
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/jobs",
            headers=api_headers(),
            params={"select": "id,title"},
            timeout=10
        )
        jobs = response.json()
        job_ids = {i: job['id'] for i, job in enumerate(jobs[:len(DEMO_JOBS)])}
    except Exception as e:
        print(f"Error fetching jobs: {e}")
        return
    
    for app in DEMO_APPLICATIONS:
        try:
            job_id = job_ids.get(app["job_id_idx"])
            if not job_id:
                continue
            
            app_data = {
                "job_id": job_id,
                "worker_nic": app["worker_nic"],
                "status": app["status"],
                "applied_at": (datetime.utcnow() - timedelta(days=random.randint(1, 15))).isoformat() + "Z",
            }
            
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/applications",
                headers=api_headers(),
                json=app_data,
                timeout=10
            )
            
            if response.status_code in [201, 409]:
                print(f"  [OK] Application: {app['worker_nic']} for job")
            else:
                print(f"  [FAIL] Application failed: {response.status_code}")
        except Exception as e:
            print(f"  [FAIL] Application error: {e}")


def seed_reviews():
    """Seed demo reviews into Supabase."""
    print("\nSeeding reviews...")
    
    for review in DEMO_REVIEWS:
        try:
            review_data = {
                **review,
                "created_at": (datetime.utcnow() - timedelta(days=random.randint(1, 30))).isoformat() + "Z",
            }
            
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/reviews",
                headers=api_headers(),
                json=review_data,
                timeout=10
            )
            
            if response.status_code in [201, 409]:
                print(f"  [OK] Review: {review['reviewer_nic']} -> {review['worker_nic']}")
            else:
                print(f"  [FAIL] Review failed: {response.status_code}")
        except Exception as e:
            print(f"  [FAIL] Review error: {e}")


def verify_seeding():
    """Verify that demo data was seeded successfully."""
    print("\n\nVerification:")
    print("-" * 50)
    
    try:
        # Count users
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users",
            headers=api_headers(),
            params={"select": "count"},
            timeout=10
        )
        users_count = len(response.json())
        print(f"[OK] Users: {users_count}")
        
        # Count jobs
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/jobs",
            headers=api_headers(),
            params={"select": "count"},
            timeout=10
        )
        jobs_count = len(response.json())
        print(f"[OK] Jobs: {jobs_count}")
        
        # Count applications
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/applications",
            headers=api_headers(),
            params={"select": "count"},
            timeout=10
        )
        apps_count = len(response.json())
        print(f"[OK] Applications: {apps_count}")
        
        # Count reviews
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/reviews",
            headers=api_headers(),
            params={"select": "count"},
            timeout=10
        )
        reviews_count = len(response.json())
        print(f"[OK] Reviews: {reviews_count}")
        
        print("-" * 50)
        print("[OK] Demo data seeding completed successfully!")
        
    except Exception as e:
        print(f"Verification failed: {e}")


def main():
    """Run the seeding process."""
    print("=" * 50)
    print("Workforce Platform - Demo Data Seeding")
    print("=" * 50)
    
    if not SUPABASE_SERVICE_ROLE_KEY:
        print(
            "\n⚠️  Error: Neither SUPABASE_SERVICE_ROLE_KEY nor SUPABASE_ANON_KEY environment variable is set!"
        )
        return
    
    seed_users()
    seed_jobs()
    seed_applications()
    seed_reviews()
    verify_seeding()


if __name__ == "__main__":
    main()
