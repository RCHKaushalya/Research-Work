from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
import datetime
from database import Base

class User(Base):
    __tablename__ = "users"

    nic = Column(String, primary_key=True, index=True)
    first_name = Column(String)
    last_name = Column(String)
    phone = Column(String)
    pin_hash = Column(String)
    language = Column(String)
    district = Column(String)
    ds_area = Column(String)
    job_category_ids = Column(JSON, default=[])
    skill_ids = Column(JSON, default=[])
    
    # Stats
    posted_jobs_count = Column(Integer, default=0)
    applied_jobs_count = Column(Integer, default=0)
    abandoned_jobs_count = Column(Integer, default=0)
    removed_jobs_count = Column(Integer, default=0)
    completed_jobs_count = Column(Integer, default=0)
    
    rating = Column(Float, default=0.0)
    profile_photo_path = Column(String, nullable=True)
    is_blocked = Column(Integer, default=0) # 0 = active, 1 = blocked

    # Relationships
    posted_jobs = relationship("Job", back_populates="employer", foreign_keys="[Job.employer_id]")
    assigned_tasks = relationship("Job", back_populates="worker", foreign_keys="[Job.assigned_worker_id]")
    portfolio = relationship("PortfolioItem", back_populates="user")

class Job(Base):
    __tablename__ = "jobs"

    id = Column(String, primary_key=True, index=True)
    title = Column(String)
    description = Column(String)
    area = Column(String)
    skill_ids_needed = Column(JSON, default=[])
    employer_id = Column(String, ForeignKey("users.nic"))
    assigned_worker_id = Column(String, ForeignKey("users.nic"), nullable=True)
    employer_language = Column(String)
    status = Column(String, default="open") # open, completed, cancelled
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationships
    employer = relationship("User", foreign_keys=[employer_id], back_populates="posted_jobs")
    worker = relationship("User", foreign_keys=[assigned_worker_id], back_populates="assigned_tasks")
    applications = relationship("JobApplication", back_populates="job")

class JobApplication(Base):
    __tablename__ = "job_applications"

    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(String, ForeignKey("jobs.id"))
    worker_id = Column(String, ForeignKey("users.nic"))
    applied_at = Column(DateTime, default=datetime.datetime.utcnow)

    job = relationship("Job", back_populates="applications")

class PortfolioItem(Base):
    __tablename__ = "portfolio"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.nic"))
    photo_path = Column(String)

    user = relationship("User", back_populates="portfolio")

class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(String, ForeignKey("jobs.id"))
    author_id = Column(String, ForeignKey("users.nic"))
    recipient_id = Column(String, ForeignKey("users.nic"))
    rating = Column(Integer)
    comment = Column(String)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
