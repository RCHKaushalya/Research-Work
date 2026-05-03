from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
import uuid
import os
import shutil
import models, schemas, database, auth
import datetime

# Create database tables
models.Base.metadata.create_all(bind=database.engine)

# Ensure upload directories exist
for path in ["uploads", "uploads/profiles", "uploads/portfolio"]:
    if not os.path.exists(path):
        os.makedirs(path)

app = FastAPI(title="Workforce Platform API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve static files for uploads and Admin Web App
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
app.mount("/admin-ui", StaticFiles(directory="admin_portal", html=True), name="admin-ui")

def map_job_with_apps(job: models.Job):
    job_dict = {c.name: getattr(job, c.name) for c in job.__table__.columns}
    job_dict['applied_worker_ids'] = [app.worker_id for app in job.applications]
    return job_dict

# Auth Endpoints
@app.post("/auth/register", response_model=schemas.User)
def register_user(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.nic == user.nic).first()
    if db_user:
        raise HTTPException(status_code=400, detail="NIC already registered")
    
    hashed_pin = auth.get_pin_hash(user.pin)
    new_user = models.User(
        **user.dict(exclude={'pin'}),
        pin_hash=hashed_pin
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/auth/login")
def login(user_credentials: schemas.UserLogin, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.nic == user_credentials.nic).first()
    if not db_user:
        raise HTTPException(status_code=400, detail="Invalid NIC")
    if db_user.is_blocked:
        raise HTTPException(status_code=403, detail="Your account has been blocked by admin.")
    if not auth.verify_pin(user_credentials.pin, db_user.pin_hash):
        raise HTTPException(status_code=400, detail="Invalid PIN")
    
    access_token = auth.create_access_token(data={"sub": db_user.nic})
    return {"access_token": access_token, "token_type": "bearer"}

# User Endpoints
@app.get("/users/me", response_model=schemas.User)
def get_me(current_user: models.User = Depends(auth.get_current_user)):
    return current_user

@app.put("/users/me", response_model=schemas.User)
def update_me(user_update: schemas.UserUpdate, current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    for key, value in user_update.dict(exclude_unset=True).items():
        setattr(current_user, key, value)
    db.commit()
    db.refresh(current_user)
    return current_user

@app.post("/users/me/photo")
async def upload_profile_photo(file: UploadFile = File(...), current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    file_extension = os.path.splitext(file.filename)[1]
    file_name = f"{current_user.nic}_{uuid.uuid4()}{file_extension}"
    file_path = os.path.join("uploads", "profiles", file_name)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    current_user.profile_photo_path = file_path.replace("\\", "/")
    db.commit()
    return {"profile_photo_path": current_user.profile_photo_path}

@app.post("/users/me/portfolio")
async def upload_portfolio_photo(file: UploadFile = File(...), current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    file_extension = os.path.splitext(file.filename)[1]
    file_name = f"{current_user.nic}_{uuid.uuid4()}{file_extension}"
    file_path = os.path.join("uploads", "portfolio", file_name)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    db_portfolio = models.PortfolioItem(user_id=current_user.nic, photo_path=file_path.replace("\\", "/"))
    db.add(db_portfolio)
    db.commit()
    return {"photo_path": db_portfolio.photo_path}

# Job Endpoints
@app.post("/jobs", response_model=schemas.Job)
def create_job(job: schemas.JobCreate, current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    job_id = str(uuid.uuid4())
    new_job = models.Job(
        **job.dict(),
        id=job_id,
        employer_id=current_user.nic,
        employer_language=current_user.language
    )
    current_user.posted_jobs_count += 1
    db.add(new_job)
    db.commit()
    db.refresh(new_job)
    return map_job_with_apps(new_job)

@app.get("/jobs", response_model=list[schemas.Job])
def list_jobs(area: str = None, db: Session = Depends(database.get_db)):
    query = db.query(models.Job).filter(models.Job.status == "open")
    if area:
        query = query.filter(models.Job.area == area)
    jobs = query.all()
    return [map_job_with_apps(j) for j in jobs]

@app.put("/jobs/{job_id}/status", response_model=schemas.Job)
def update_job_status(job_id: str, status_update: schemas.JobStatusUpdate, current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    job = db.query(models.Job).filter(models.Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    if job.employer_id != current_user.nic:
        raise HTTPException(status_code=403, detail="Only employer can update job status")

    new_status = status_update.status
    if new_status == "assigned" and status_update.assigned_worker_id:
        job.assigned_worker_id = status_update.assigned_worker_id
    elif new_status == "completed":
        current_user.completed_jobs_count += 1
        if job.assigned_worker_id:
            worker = db.query(models.User).filter(models.User.nic == job.assigned_worker_id).first()
            if worker: worker.completed_jobs_count += 1
    elif new_status == "cancelled":
        current_user.removed_jobs_count += 1

    job.status = new_status
    db.commit()
    db.refresh(job)
    return map_job_with_apps(job)

@app.post("/jobs/{job_id}/apply")
def apply_to_job(job_id: str, current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    job = db.query(models.Job).filter(models.Job.id == job_id).first()
    if not job or job.status != "open":
        raise HTTPException(status_code=404, detail="Job not found or not open")
    
    existing_app = db.query(models.JobApplication).filter(
        models.JobApplication.job_id == job_id,
        models.JobApplication.worker_id == current_user.nic
    ).first()
    if existing_app:
        raise HTTPException(status_code=400, detail="Already applied")
    
    new_app = models.JobApplication(job_id=job_id, worker_id=current_user.nic)
    current_user.applied_jobs_count += 1
    
    db.add(new_app)
    db.commit()
    return {"message": "Application successful"}

@app.get("/jobs/posted", response_model=list[schemas.Job])
def get_posted_jobs(current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    jobs = db.query(models.Job).filter(models.Job.employer_id == current_user.nic).all()
    return [map_job_with_apps(j) for j in jobs]

@app.get("/jobs/applied", response_model=list[schemas.Job])
def get_applied_jobs(current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    # Find all job IDs where user has an application
    app_job_ids = db.query(models.JobApplication.job_id).filter(models.JobApplication.worker_id == current_user.nic).all()
    job_ids = [r[0] for r in app_job_ids]
    jobs = db.query(models.Job).filter(models.Job.id.in_(job_ids)).all()
    return [map_job_with_apps(j) for j in jobs]

# Admin Endpoints
@app.post("/admin/login")
def admin_login(payload: dict):
    pin = payload.get("pin")
    if pin == "9421":
        token = auth.create_access_token(data={"sub": "admin", "role": "admin"})
        return {"access_token": token, "token_type": "bearer"}
    raise HTTPException(status_code=401, detail="Invalid Admin PIN")

@app.get("/admin/stats")
def get_admin_stats(db: Session = Depends(database.get_db)):
    total_users = db.query(models.User).count()
    total_jobs = db.query(models.Job).count()
    active_jobs = db.query(models.Job).filter(models.Job.status == "open").count()
    total_apps = db.query(models.JobApplication).count()
    return {
        "total_users": total_users,
        "total_jobs": total_jobs,
        "active_jobs": active_jobs,
        "total_applications": total_apps
    }

@app.get("/admin/users", response_model=list[schemas.User])
def get_admin_users(db: Session = Depends(database.get_db)):
    return db.query(models.User).all()

@app.post("/admin/users/{nic}/block")
def block_user(nic: str, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.nic == nic).first()
    if not user: raise HTTPException(status_code=404, detail="User not found")
    user.is_blocked = 1 if user.is_blocked == 0 else 0
    db.commit()
    return {"message": "User status updated", "is_blocked": user.is_blocked}

@app.get("/admin/jobs", response_model=list[schemas.Job])
def get_admin_jobs(db: Session = Depends(database.get_db)):
    jobs = db.query(models.Job).all()
    return [map_job_with_apps(j) for j in jobs]

@app.delete("/admin/jobs/{job_id}")
def delete_job(job_id: str, db: Session = Depends(database.get_db)):
    job = db.query(models.Job).filter(models.Job.id == job_id).first()
    if not job: raise HTTPException(status_code=404, detail="Job not found")
    db.delete(job)
    db.commit()
    return {"message": "Job deleted"}

@app.get("/admin/applications")
def get_admin_applications(db: Session = Depends(database.get_db)):
    apps = db.query(models.JobApplication).all()
    results = []
    for app in apps:
        job = db.query(models.Job).filter(models.Job.id == app.job_id).first()
        results.append({
            "id": app.id,
            "job_title": job.title if job else "N/A",
            "worker_id": app.worker_id,
            "applied_at": app.applied_at
        })
    return results

# SMS Gateway Endpoints
@app.post("/sms/incoming")
def receive_incoming_sms(sms: schemas.SMSMessageCreate, db: Session = Depends(database.get_db)):
    new_sms = models.SMSMessage(
        phone_number=sms.phone_number,
        message=sms.message,
        direction="incoming",
        status="received"
    )
    db.add(new_sms)
    db.commit()
    return {"message": "SMS received and stored"}

@app.get("/sms/pending", response_model=list[schemas.SMSMessage])
def get_pending_sms(db: Session = Depends(database.get_db)):
    return db.query(models.SMSMessage).filter(
        models.SMSMessage.direction == "outgoing",
        models.SMSMessage.status == "pending"
    ).all()

@app.post("/sms/sent/{sms_id}")
def mark_sms_as_sent(sms_id: int, db: Session = Depends(database.get_db)):
    sms = db.query(models.SMSMessage).filter(models.SMSMessage.id == sms_id).first()
    if not sms:
        raise HTTPException(status_code=404, detail="SMS not found")
    sms.status = "sent"
    sms.sent_at = datetime.datetime.utcnow()
    db.commit()
    return {"message": "SMS marked as sent"}

@app.post("/sms/queue", response_model=schemas.SMSMessage)
def queue_sms(sms: schemas.SMSMessageCreate, db: Session = Depends(database.get_db)):
    new_sms = models.SMSMessage(
        phone_number=sms.phone_number,
        message=sms.message,
        direction="outgoing",
        status="pending"
    )
    db.add(new_sms)
    db.commit()
    db.refresh(new_sms)
    return new_sms

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
