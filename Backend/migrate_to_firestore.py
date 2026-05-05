import sqlite3
import os
from firebase_admin import firestore
import firebase_setup

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "workforce.db")

db = firestore.client()

def migrate_users(cursor):
    print("Migrating users...")
    cursor.execute("SELECT * FROM users")
    columns = [description[0] for description in cursor.description]
    for row in cursor.fetchall():
        user_data = dict(zip(columns, row))
        
        # Parse arrays stored as JSON strings in SQLite (if they were) or adjust as needed
        # Assuming skill_ids and job_category_ids were stored as strings or JSON
        import json
        try:
            skill_ids = json.loads(user_data.get('skill_ids', '[]')) if user_data.get('skill_ids') else []
        except:
            skill_ids = []
            
        try:
            job_category_ids = json.loads(user_data.get('job_category_ids', '[]')) if user_data.get('job_category_ids') else []
        except:
            job_category_ids = []

        firestore_user = {
            "nic": user_data.get("nic"),
            "first_name": user_data.get("first_name"),
            "last_name": user_data.get("last_name"),
            "phone": user_data.get("phone"),
            "language": user_data.get("language"),
            "district": user_data.get("district"),
            "ds_area": user_data.get("ds_area"),
            "job_category_ids": job_category_ids,
            "skill_ids": skill_ids,
            "rating": user_data.get("rating", 0.0),
            "completed_jobs_count": user_data.get("completed_jobs_count", 0),
            "abandoned_jobs_count": user_data.get("abandoned_jobs_count", 0),
            "posted_jobs_count": user_data.get("posted_jobs_count", 0),
            "applied_jobs_count": user_data.get("applied_jobs_count", 0),
            "removed_jobs_count": user_data.get("removed_jobs_count", 0),
            "is_blocked": user_data.get("is_blocked", 0),
            "availability_status": user_data.get("availability_status", "available"),
            "profile_photo_url": user_data.get("profile_photo_path"),
            # Save the hashed pin if we ever need it, or ignore since Firebase uses plain PIN during register
        }
        
        db.collection("users").document(user_data["nic"]).set(firestore_user)
    print("Users migrated.")

def migrate_jobs(cursor):
    print("Migrating jobs...")
    cursor.execute("SELECT * FROM jobs")
    columns = [description[0] for description in cursor.description]
    for row in cursor.fetchall():
        job_data = dict(zip(columns, row))
        
        import json
        try:
            skill_ids_needed = json.loads(job_data.get('skill_ids_needed', '[]')) if job_data.get('skill_ids_needed') else []
        except:
            skill_ids_needed = []

        # Find applications for this job
        cursor.execute("SELECT worker_id FROM job_applications WHERE job_id = ?", (job_data["id"],))
        applied_workers = [r[0] for r in cursor.fetchall()]

        firestore_job = {
            "id": job_data["id"],
            "title": job_data["title"],
            "description": job_data["description"],
            "area": job_data["area"],
            "skill_ids_needed": skill_ids_needed,
            "employer_id": job_data["employer_id"],
            "employer_language": job_data["employer_language"],
            "assigned_worker_id": job_data.get("assigned_worker_id"),
            "status": job_data["status"],
            "applied_worker_ids": applied_workers,
            "created_at": job_data["created_at"]
        }
        
        db.collection("jobs").document(job_data["id"]).set(firestore_job)
    print("Jobs migrated.")

def migrate_applications(cursor):
    print("Migrating applications...")
    cursor.execute("SELECT * FROM job_applications")
    columns = [description[0] for description in cursor.description]
    for row in cursor.fetchall():
        app_data = dict(zip(columns, row))
        doc_id = f"{app_data['job_id']}_{app_data['worker_id']}"
        firestore_app = {
            "job_id": app_data["job_id"],
            "worker_id": app_data["worker_id"],
            "applied_at": app_data["applied_at"]
        }
        db.collection("applications").document(doc_id).set(firestore_app)
    print("Applications migrated.")

def migrate_sms(cursor):
    print("Migrating SMS messages...")
    cursor.execute("SELECT * FROM sms_messages")
    columns = [description[0] for description in cursor.description]
    for row in cursor.fetchall():
        sms_data = dict(zip(columns, row))
        
        doc_id = str(sms_data["id"])
        firestore_sms = {
            "id": doc_id,
            "phone_number": sms_data["phone_number"],
            "message": sms_data["message"],
            "direction": sms_data["direction"],
            "status": sms_data["status"],
            "created_at": sms_data["created_at"],
            "sent_at": sms_data.get("sent_at")
        }
        db.collection("sms_messages").document(doc_id).set(firestore_sms)
    print("SMS messages migrated.")

if __name__ == "__main__":
    if not os.path.exists(DB_PATH):
        print(f"SQLite DB not found at {DB_PATH}")
        exit(1)
        
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        migrate_users(cursor)
        migrate_jobs(cursor)
        migrate_applications(cursor)
        migrate_sms(cursor)
        print("Migration complete!")
    except Exception as e:
        print(f"Migration failed: {e}")
    finally:
        conn.close()
