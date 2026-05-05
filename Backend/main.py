from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import os
from firebase_setup import db
from firebase_admin import firestore

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

app = FastAPI(title="Workforce Platform SMS Gateway")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve the Firebase Admin Web App
app.mount("/admin-ui", StaticFiles(directory=os.path.join(BASE_DIR, "admin_portal"), html=True), name="admin-ui")

# Pydantic models for the SMS Gateway
class SMSMessageBase(BaseModel):
    phone_number: str
    message: str

class SMSMessageCreate(SMSMessageBase):
    pass

def send_sms(phone_number: str, message: str):
    """Queues an SMS in Firestore"""
    doc_ref = db.collection("sms_messages").document()
    sms_data = {
        "id": doc_ref.id,
        "phone_number": phone_number,
        "message": message,
        "direction": "outgoing",
        "status": "pending",
        "created_at": datetime.utcnow().isoformat() + "Z",
        "sent_at": None
    }
    doc_ref.set(sms_data)
    return sms_data

def process_sms_command(phone_number: str, message: str):
    parts = message.strip().split()
    if not parts: return
    
    cmd = parts[0].upper()
    
    users_ref = db.collection("users")
    user_query = users_ref.where(filter=firestore.FieldFilter("phone", "==", phone_number)).limit(1).stream()
    user_docs = list(user_query)
    user_doc = user_docs[0] if user_docs else None
    
    # 1. REG <NIC> <First Name> <Last Name>
    if cmd == "REG" and len(parts) >= 4:
        nic = parts[1].upper()
        first_name = parts[2]
        last_name = " ".join(parts[3:])
        
        user_ref = users_ref.document(nic)
        existing = user_ref.get()
        if not existing.exists:
            user_ref.set({
                "nic": nic,
                "first_name": first_name,
                "last_name": last_name,
                "phone": phone_number,
                "language": "en",
                "district": "",
                "ds_area": "",
                "job_category_ids": [],
                "skill_ids": [],
                "rating": 0.0,
                "completed_jobs_count": 0,
                "abandoned_jobs_count": 0,
                "posted_jobs_count": 0,
                "applied_jobs_count": 0,
                "removed_jobs_count": 0,
                "is_blocked": 0,
                "availability_status": "available",
                "profile_photo_path": None,
                "pin": "" # SMS users won't use email auth, but this keeps schema consistent
            })
        else:
            user_ref.update({
                "first_name": first_name,
                "last_name": last_name,
                "phone": phone_number
            })
        send_sms(phone_number, f"Welcome {first_name}! You are registered. Set your area using 'Area <D_id> <DS_id>' and skills using 'Skill <S_id>'.")

    # 2. Area <D_id> <ds_id>
    elif cmd == "AREA" and len(parts) >= 3:
        if not user_doc:
            send_sms(phone_number, "Please register first using REG <NIC> <First> <Last>")
            return
        district = parts[1]
        ds_area = parts[2]
        user_doc.reference.update({
            "district": district,
            "ds_area": ds_area
        })
        send_sms(phone_number, f"Area updated to {district}, {ds_area}.")

    # 3. Skill <s_id>
    elif cmd == "SKILL" and len(parts) >= 2:
        if not user_doc:
            send_sms(phone_number, "Please register first using REG <NIC> <First> <Last>")
            return
        skill_id = parts[1]
        user_data = user_doc.to_dict()
        skills = user_data.get("skill_ids", [])
        if skill_id not in skills:
            skills.append(skill_id)
            cat_id = f"CAT_{skill_id}"
            cats = user_data.get("job_category_ids", [])
            if cat_id not in cats: cats.append(cat_id)
            user_doc.reference.update({
                "skill_ids": skills,
                "job_category_ids": cats
            })
        send_sms(phone_number, f"Skill {skill_id} added.")

    # 4. JOB
    elif cmd == "JOB":
        if not user_doc or not user_doc.to_dict().get("ds_area"):
            send_sms(phone_number, "Register and set your Area first.")
            return
        
        user_data = user_doc.to_dict()
        ds_area = user_data.get("ds_area")
        user_skills = set(user_data.get("skill_ids", []))
        
        jobs_ref = db.collection("jobs")
        jobs_query = jobs_ref.where(filter=firestore.FieldFilter("status", "==", "open")).where(filter=firestore.FieldFilter("area", "==", ds_area)).stream()
        
        matching_jobs = []
        for job in jobs_query:
            job_data = job.to_dict()
            job_skills = set(job_data.get("skill_ids_needed", []))
            if not user_skills or user_skills.intersection(job_skills):
                matching_jobs.append(job_data)
                if len(matching_jobs) >= 5: break
                
        if not matching_jobs:
            send_sms(phone_number, "No matching jobs found in your area right now.")
        else:
            response = "Jobs for you:\n"
            for j in matching_jobs:
                response += f"- {j.get('title', 'Job')} (ID: {j.get('id', '')[:4]})\n"
            response += "Apply using APPLY <ID>"
            send_sms(phone_number, response)

    # 5. APPLY <job_id>
    elif cmd == "APPLY" and len(parts) >= 2:
        if not user_doc:
            send_sms(phone_number, "Please register first.")
            return
            
        job_id_part = parts[1]
        user_data = user_doc.to_dict()
        nic = user_data.get("nic")
        
        end_str = job_id_part + '\uf8ff'
        jobs_query = db.collection("jobs").where(filter=firestore.FieldFilter("id", ">=", job_id_part)).where(filter=firestore.FieldFilter("id", "<=", end_str)).limit(1).stream()
        
        jobs_list = list(jobs_query)
        if not jobs_list:
            send_sms(phone_number, "Job not found.")
            return
            
        job_doc = jobs_list[0]
        job_data = job_doc.to_dict()
        job_id = job_data.get("id")
        
        app_ref = db.collection("applications").document(f"{job_id}_{nic}")
        if app_ref.get().exists:
            send_sms(phone_number, "You already applied for this job.")
        else:
            app_ref.set({
                "job_id": job_id,
                "worker_id": nic,
                "applied_at": datetime.utcnow().isoformat() + "Z"
            })
            user_doc.reference.update({
                "applied_jobs_count": firestore.Increment(1)
            })
            applied_ids = job_data.get("applied_worker_ids", [])
            if nic not in applied_ids:
                applied_ids.append(nic)
                job_doc.reference.update({"applied_worker_ids": applied_ids})
                
            send_sms(phone_number, f"Successfully applied for {job_data.get('title')}!")
    
    else:
        send_sms(phone_number, "Unknown command. Use REG, Area, Skill, JOB, or APPLY.")

# SMS Gateway Endpoints
@app.post("/sms/incoming")
def receive_incoming_sms(sms: SMSMessageCreate):
    doc_ref = db.collection("sms_messages").document()
    doc_ref.set({
        "id": doc_ref.id,
        "phone_number": sms.phone_number,
        "message": sms.message,
        "direction": "incoming",
        "status": "received",
        "created_at": datetime.utcnow().isoformat() + "Z",
        "sent_at": None
    })
    
    process_sms_command(sms.phone_number, sms.message)
    return {"message": "SMS received and processed"}

@app.get("/sms/pending")
def get_pending_sms():
    query = db.collection("sms_messages").where(filter=firestore.FieldFilter("direction", "==", "outgoing")).where(filter=firestore.FieldFilter("status", "==", "pending")).stream()
    return [doc.to_dict() for doc in query]

@app.post("/sms/sent/{sms_id}")
def mark_sms_as_sent(sms_id: str):
    doc_ref = db.collection("sms_messages").document(sms_id)
    if not doc_ref.get().exists:
        raise HTTPException(status_code=404, detail="SMS not found")
    doc_ref.update({
        "status": "sent",
        "sent_at": datetime.utcnow().isoformat() + "Z"
    })
    return {"message": "SMS marked as sent"}

@app.post("/sms/queue")
def queue_sms(sms: SMSMessageCreate):
    return send_sms(sms.phone_number, sms.message)

@app.post("/admin/login")
def admin_login(payload: dict):
    pin = payload.get("pin")
    if pin == "9421":
        from firebase_admin import auth
        custom_token = auth.create_custom_token("admin_user", {"admin": True})
        return {"access_token": custom_token.decode('utf-8'), "token_type": "bearer"}
    raise HTTPException(status_code=401, detail="Invalid Admin PIN")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
