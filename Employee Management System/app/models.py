from dataclasses import dataclass
from typing import Any, Dict, List

@dataclass
class Job:
    id: str
    title: str
    description: str
    employer_nic: str
    location: str
    status: str
    required_skills: List[str]
    applied_worker_ids: List[str]
    accepted_worker_ids: List[str]
    payments: List[Dict[str, Any]]
    created_at: str

@dataclass
class Application:
    id: str
    job_id: str
    worker_nic: str
    status: str
    applied_at: str

@dataclass
class Review:
    id: str
    reviewer_nic: str
    worker_nic: str
    rating: float
    comment: str
    created_at: str
