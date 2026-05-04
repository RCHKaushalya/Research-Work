from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class UserBase(BaseModel):
    nic: str
    first_name: str
    last_name: str
    phone: str
    language: str
    district: Optional[str] = None
    ds_area: Optional[str] = None
    job_category_ids: List[str] = []
    skill_ids: List[str] = []

class UserCreate(UserBase):
    pin: str

class UserLogin(BaseModel):
    nic: str
    pin: str

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    language: Optional[str] = None
    district: Optional[str] = None
    ds_area: Optional[str] = None
    job_category_ids: Optional[List[str]] = None
    skill_ids: Optional[List[str]] = None
    availability_status: Optional[str] = None  # available, busy, unavailable

class AvailabilityUpdate(BaseModel):
    status: str  # available, busy, unavailable

class User(UserBase):
    posted_jobs_count: int
    applied_jobs_count: int
    abandoned_jobs_count: int
    removed_jobs_count: int
    completed_jobs_count: int
    rating: float
    profile_photo_path: Optional[str] = None
    is_blocked: int = 0
    availability_status: str = "available"

    class Config:
        from_attributes = True

class JobBase(BaseModel):
    title: str
    description: str
    area: str
    skill_ids_needed: List[str] = []

class JobCreate(JobBase):
    pass

class Job(JobBase):
    id: str
    employer_id: str
    assigned_worker_id: Optional[str] = None
    applied_worker_ids: List[str] = []
    employer_language: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

class JobStatusUpdate(BaseModel):
    status: str # open, assigned, completed, cancelled, abandoned
    assigned_worker_id: Optional[str] = None

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    nic: Optional[str] = None

class SMSMessageBase(BaseModel):
    phone_number: str
    message: str

class SMSMessageCreate(SMSMessageBase):
    pass

class SMSMessage(SMSMessageBase):
    id: int
    direction: str
    status: str
    created_at: datetime
    sent_at: Optional[datetime] = None

    class Config:
        from_attributes = True
