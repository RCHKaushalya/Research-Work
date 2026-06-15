from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import os
import secrets
import requests
import hmac
import hashlib
import base64
import json
from fastapi import Request
from supabase_service import is_configured as supabase_is_configured
from supabase_service import (
    insert_sms_message,
    find_job_by_prefix,
    find_open_jobs_for_area,
    find_user_by_phone,
    log_incoming_sms,
    add_application,
    application_exists,
    update_user_by_nic,
    list_pending_sms,
    mark_sms_as_sent as mark_sms_as_sent_supabase,
    upsert_user,
    list_pending_users,
    verify_user,
    list_support_queries,
    respond_to_support_query,
)

SMS_API_KEY = "121a66e53543e2230b8075688522be30180d477c"
SMS_GATEWAY_URL = "https://app.sms-gateway.app/services/send.php"
SMS_DEVICES = '["10959|0","10959|1"]'

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

app = FastAPI(title="Workforce Platform SMS Gateway")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

import socket

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

@app.on_event("startup")
def startup_event():
    ip = get_local_ip()
    url = f"http://{ip}:8000"
    print("==========================================")
    print(f"Backend URL: {url}")
    print("==========================================")

os.makedirs(os.path.join(BASE_DIR, "uploads"), exist_ok=True)
app.mount("/uploads", StaticFiles(directory=os.path.join(BASE_DIR, "uploads")), name="uploads")

import shutil
import uuid

@app.post("/upload")
def upload_image(file: UploadFile = File(...)):
    # Generate unique filename
    ext = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
    filename = f"{uuid.uuid4().hex}.{ext}"
    file_path = os.path.join(BASE_DIR, "uploads", filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return {"path": f"uploads/{filename}"}

# Pydantic models for the SMS Gateway
class SMSMessageBase(BaseModel):
    phone_number: str
    message: str

class SMSMessageCreate(SMSMessageBase):
    pass


class SupportResponseCreate(BaseModel):
    sender_nic: str
    receiver_nic: str
    content: str


class GoogleJobPostingForm(BaseModel):
    """Google Form submission for job posting by employers"""
    employer_name: str
    employer_phone: str
    job_title: str
    job_description: str
    location: str
    category: Optional[str] = None
    required_skills: Optional[str] = None  # comma-separated


class GoogleUserRegistrationForm(BaseModel):
    """Google Form submission for user registration"""
    phone_number: str
    first_name: str
    last_name: str
    district: str
    ds_area: Optional[str] = None
    language: Optional[str] = "si"


def send_sms(phone_number: str, message: str):
    """Queues an SMS and sends via external API"""
    sms_id = uuid.uuid4().hex
    sms_data = {
        "id": sms_id,
        "phone_number": phone_number,
        "message": message,
        "direction": "outgoing",
        "status": "pending",
        "created_at": datetime.utcnow().isoformat() + "Z",
        "sent_at": None
    }
    
    try:
        # Format the phone number (ensure + prefix if missing)
        formatted_number = phone_number if phone_number.startswith('+') else f"+{phone_number}"
        
        # Call external API
        params = {
            "key": SMS_API_KEY,
            "number": formatted_number,
            "message": message,
            "devices": SMS_DEVICES,
            "type": "sms",
            "prioritize": 0
        }
        
        response = requests.get(SMS_GATEWAY_URL, params=params, timeout=10)
        
        if response.status_code == 200:
            sms_data["status"] = "sent"
            sms_data["sent_at"] = datetime.utcnow().isoformat() + "Z"
            print(f"SMS sent successfully to {phone_number}")
        else:
            sms_data["status"] = "failed"
            print(f"Failed to send SMS to {phone_number}: {response.text}")
            
    except Exception as e:
        sms_data["status"] = "error"
        print(f"Error calling SMS API: {e}")

    if not supabase_is_configured():
        raise RuntimeError("Supabase is not configured.")

    insert_sms_message(sms_data)
    return sms_data

def process_sms_command(phone_number: str, message: str):
    parts = message.strip().split()
    if not parts: return
    
    # Check for <job_id_prefix> 1 pattern (apply command shorthand)
    if len(parts) >= 2 and parts[1] == "1":
        job_data = find_job_by_prefix(parts[0])
        if job_data:
            cmd = "APPLY"
            parts = ["APPLY", parts[0]]
        else:
            cmd = parts[0].upper()
    else:
        cmd = parts[0].upper()

    if not supabase_is_configured():
        raise RuntimeError("Supabase is not configured.")

    user_doc = find_user_by_phone(phone_number)
    
    # 1. REGISTER <NIC> [First Name] [Last Name]
    if cmd in {"REG", "REGISTER"} and len(parts) >= 2:
        nic = parts[1].upper()
        first_name = parts[2] if len(parts) >= 3 else "Pending"
        last_name = " ".join(parts[3:]) if len(parts) >= 4 else "User"
        pin = f"{secrets.randbelow(1000000):06d}"

        user_payload = {
            "nic": nic,
            "first_name": first_name,
            "last_name": last_name,
            "phone": phone_number,
            "password_hash": pin,
            "district": "",
            "ds_area": "",
            "language": "en",
            "verified": False,
            "profile_photo_url": None,
            "rating": 0.0,
            "completed_jobs_count": 0,
            "abandoned_jobs_count": 0,
            "posted_jobs_count": 0,
            "applied_jobs_count": 0,
            "removed_jobs_count": 0,
            "availability_status": "available",
        }

        upsert_user(user_payload)
        send_sms(phone_number, f"Welcome {first_name}! Your PIN is {pin}. Set your area using 'Area <D_id> <DS_id>' and skills using 'Skill <S_id>'.")

    # 2. Area <D_id> <ds_id>
    elif cmd == "AREA" and len(parts) >= 3:
        if not user_doc:
            send_sms(phone_number, "Please register first using REG <NIC> <First> <Last>")
            return
        district = parts[1]
        ds_area = parts[2]
        update_user_by_nic(user_doc["nic"], {"district": district, "ds_area": ds_area})
        send_sms(phone_number, f"Area updated to {district}, {ds_area}.")

    # 3. Skill <s_id>
    elif cmd == "SKILL" and len(parts) >= 2:
        if not user_doc:
            send_sms(phone_number, "Please register first using REG <NIC> <First> <Last>")
            return
        skill_id = parts[1]
        user_data = user_doc
        skills = user_data.get("skill_ids", [])
        if skill_id not in skills:
            skills.append(skill_id)
            cat_id = f"CAT_{skill_id}"
            cats = user_data.get("job_category_ids", [])
            if cat_id not in cats: cats.append(cat_id)
            update_user_by_nic(user_data["nic"], {"skill_ids": skills, "job_category_ids": cats})
        send_sms(phone_number, f"Skill {skill_id} added.")

    # 4. JOB
    elif cmd == "JOB":
        if not user_doc:
            send_sms(phone_number, "Register and set your Area first.")
            return
        
        user_data = user_doc
        ds_area = user_data.get("ds_area")
        user_skills = set(user_data.get("skill_ids", []))
        jobs_query = find_open_jobs_for_area(ds_area)
        
        matching_jobs = []
        for job in jobs_query:
            job_data = job
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
        user_data = user_doc
        nic = user_data.get("nic")
        job_data = find_job_by_prefix(job_id_part)
        if not job_data:
            send_sms(phone_number, "Job not found.")
            return
        job_id = job_data.get("id")
        if application_exists(job_id, nic):
            send_sms(phone_number, "You already applied for this job.")
            return
        add_application(job_id, nic)
        send_sms(phone_number, f"Successfully applied for {job_data.get('title')}!")
    
    else:
        send_sms(phone_number, "Unknown command. Use REGISTER, Area, Skill, JOB, or APPLY.")

# SMS Gateway Endpoints
@app.post("/sms/webhook")
async def sms_webhook(request: Request):
    signature = request.headers.get("X-SG-SIGNATURE")
    if not signature:
        raise HTTPException(status_code=400, detail="Signature missing")
    
    # Get form data
    form_data = await request.form()
    messages_json = form_data.get("messages")
    
    if not messages_json:
        # Check if it's a USSD request (not handling for now but returning 200)
        if form_data.get("ussdRequest"):
            return {"status": "success"}
        raise HTTPException(status_code=400, detail="No messages found")
    
    # Verify signature
    expected_hash = base64.b64encode(
        hmac.new(SMS_API_KEY.encode(), messages_json.encode(), hashlib.sha256).digest()
    ).decode()
    
    if expected_hash != signature:
        print(f"Invalid signature. Expected: {expected_hash}, Got: {signature}")
        raise HTTPException(status_code=401, detail="Invalid signature")
    
    try:
        messages = json.loads(messages_json)
        for msg in messages:
            phone = msg.get("number")
            text = msg.get("message")
            
            if phone and text:
                # Log incoming SMS
                log_incoming_sms(phone, text)
                
                # Process command
                process_sms_command(phone, text)
                
        return {"status": "success"}
    except Exception as e:
        print(f"Webhook processing error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/sms/pending")
def get_pending_sms():
    return list_pending_sms()

@app.post("/sms/sent/{sms_id}")
def mark_sms_as_sent(sms_id: str):
    mark_sms_as_sent_supabase(sms_id)
    return {"message": "SMS marked as sent"}

@app.post("/sms/send")
def admin_send_sms(sms: SMSMessageCreate):
    return send_sms(sms.phone_number, sms.message)

@app.get("/volunteer/pending-users")
def volunteer_pending_users():
    return list_pending_users()

@app.post("/volunteer/verify/{nic}")
def volunteer_verify_user(nic: str):
    verify_user(nic)
    return {"message": "User verified"}

@app.get("/volunteer/support-queries")
def volunteer_support_queries():
    return list_support_queries()

@app.post("/volunteer/support-respond")
def volunteer_support_respond(payload: SupportResponseCreate):
    respond_to_support_query(payload.sender_nic, payload.receiver_nic, payload.content)
    return {"message": "Response saved"}


# Google Forms Integration Endpoints (Zapier Webhooks)
@app.post("/forms/job-posting")
def handle_job_posting_form(form: GoogleJobPostingForm):
    """Handle job posting submissions from Google Forms via Zapier"""
    try:
        # Create a job record from the form submission
        job_data = {
            "title": form.job_title,
            "description": form.job_description,
            "employer_name": form.employer_name,
            "employer_phone": form.employer_phone,
            "location": form.location,
            "category": form.category or "General",
            "status": "open",
            "required_skills": form.required_skills.split(",") if form.required_skills else [],
            "applied_worker_ids": [],
            "accepted_worker_ids": [],
            "created_at": datetime.utcnow().isoformat() + "Z",
        }
        
        if not supabase_is_configured():
            raise HTTPException(status_code=500, detail="Supabase is not configured")

        from supabase_service import insert_job
        insert_job(job_data)
        
        return {"status": "success", "message": "Job posted successfully via Google Form"}
    except Exception as e:
        print(f"Error processing job posting form: {e}")
        return {"status": "error", "message": str(e)}, 500


@app.post("/forms/user-registration")
def handle_user_registration_form(form: GoogleUserRegistrationForm):
    """Handle user registration submissions from Google Forms via Zapier"""
    try:
        # Create a user record from the form submission
        user_data = {
            "phone": form.phone_number,
            "first_name": form.first_name,
            "last_name": form.last_name,
            "district": form.district,
            "ds_area": form.ds_area or "",
            "language": form.language or "si",
            "verified": False,  # Will be verified by volunteer panel
            "profile_photo_url": None,
            "rating": 0.0,
            "completed_jobs_count": 0,
            "abandoned_jobs_count": 0,
            "posted_jobs_count": 0,
            "applied_jobs_count": 0,
            "removed_jobs_count": 0,
            "availability_status": "available",
        }
        
        if not supabase_is_configured():
            raise HTTPException(status_code=500, detail="Supabase is not configured")

        # Store in Supabase - generate a placeholder NIC from phone
        from supabase_service import upsert_user_for_registration
        upsert_user_for_registration(form.phone_number, user_data)
        
        # Send confirmation SMS
        send_sms(form.phone_number, f"Thank you for registering! A volunteer will verify your registration soon. You'll receive a PIN via SMS.")
        
        return {"status": "success", "message": "Registration submitted, pending volunteer verification"}
    except Exception as e:
        print(f"Error processing user registration form: {e}")
        return {"status": "error", "message": str(e)}, 500

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
