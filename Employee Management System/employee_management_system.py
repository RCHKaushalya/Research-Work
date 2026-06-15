#!/usr/bin/env python3
"""
Employee Management System for Workforce Platform
A PyQt6 desktop application for large employers to manage jobs, applications, and workers.
"""

import sys
import os
import json
from datetime import datetime
from typing import Optional, List, Dict, Any
from dataclasses import dataclass, asdict
from enum import Enum

import requests
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QTabWidget, QPushButton, QLineEdit, QTextEdit, QLabel,
    QTableWidget, QTableWidgetItem, QDialog, QComboBox, QDoubleSpinBox,
    QMessageBox, QSpinBox, QDateTimeEdit, QHeaderView
)
from PyQt6.QtCore import Qt, QDateTime, pyqtSignal, QThread
from PyQt6.QtGui import QIcon, QColor, QFont

from pathlib import Path

# Load local environment variables
_ENV_FILE = Path(__file__).parent / ".env"
if _ENV_FILE.exists():
    for raw_line in _ENV_FILE.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))

# Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://your-project.supabase.co")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY") or os.getenv("SUPABASE_KEY") or ""
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8000")

# API Headers
def api_headers():
    return {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json",
    }


@dataclass
class Job:
    id: str
    title: str
    description: str
    employer_nic: str
    location: str
    status: str  # open, in_progress, completed, cancelled
    required_skills: List[str]
    applied_worker_ids: List[str]
    accepted_worker_ids: List[str]
    created_at: str


@dataclass
class Application:
    id: str
    job_id: str
    worker_nic: str
    status: str  # applied, accepted, rejected
    applied_at: str


@dataclass
class Review:
    id: str
    reviewer_nic: str
    worker_nic: str
    rating: float
    comment: str
    created_at: str


class EmployeeManagementSystem(QMainWindow):
    def __init__(self, employer_nic: str = "EMPLOYER001"):
        super().__init__()
        self.employer_nic = employer_nic
        self.jobs: List[Job] = []
        self.applications: List[Application] = []
        self.workers: Dict[str, Dict[str, Any]] = {}
        
        self.setWindowTitle("Workforce Platform - Employer Management System")
        self.setGeometry(100, 100, 1200, 700)
        
        self.init_ui()
        self.load_data()
    
    def init_ui(self):
        """Initialize the UI."""
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        layout = QVBoxLayout()
        central_widget.setLayout(layout)
        
        # Header
        header_layout = QHBoxLayout()
        employer_label = QLabel(f"Employer: {self.employer_nic}")
        employer_label.setFont(QFont("Arial", 12, QFont.Weight.Bold))
        header_layout.addWidget(employer_label)
        header_layout.addStretch()
        
        refresh_btn = QPushButton("Refresh Data")
        refresh_btn.clicked.connect(self.load_data)
        header_layout.addWidget(refresh_btn)
        
        layout.addLayout(header_layout)
        
        # Tabs
        tabs = QTabWidget()
        
        # Job Management Tab
        jobs_widget = self.create_jobs_tab()
        tabs.addTab(jobs_widget, "Jobs")
        
        # Applications Tab
        apps_widget = self.create_applications_tab()
        tabs.addTab(apps_widget, "Applications")
        
        # Worker Reviews Tab
        reviews_widget = self.create_reviews_tab()
        tabs.addTab(reviews_widget, "Reviews")
        
        layout.addWidget(tabs)
    
    def create_jobs_tab(self) -> QWidget:
        """Create the job management tab."""
        widget = QWidget()
        layout = QVBoxLayout()
        
        # New Job Form
        form_layout = QHBoxLayout()
        
        self.job_title_input = QLineEdit()
        self.job_title_input.setPlaceholderText("Job Title")
        form_layout.addWidget(self.job_title_input)
        
        self.job_desc_input = QLineEdit()
        self.job_desc_input.setPlaceholderText("Description")
        form_layout.addWidget(self.job_desc_input)
        
        self.job_location_input = QLineEdit()
        self.job_location_input.setPlaceholderText("Location")
        form_layout.addWidget(self.job_location_input)
        
        post_job_btn = QPushButton("Post Job")
        post_job_btn.clicked.connect(self.post_job)
        form_layout.addWidget(post_job_btn)
        
        layout.addLayout(form_layout)
        
        # Jobs Table
        self.jobs_table = QTableWidget()
        self.jobs_table.setColumnCount(6)
        self.jobs_table.setHorizontalHeaderLabels(["Title", "Location", "Status", "Applied", "Accepted", "Actions"])
        self.jobs_table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        layout.addWidget(self.jobs_table)
        
        widget.setLayout(layout)
        return widget
    
    def create_applications_tab(self) -> QWidget:
        """Create the applications tab."""
        widget = QWidget()
        layout = QVBoxLayout()
        
        # Applications Table
        self.apps_table = QTableWidget()
        self.apps_table.setColumnCount(5)
        self.apps_table.setHorizontalHeaderLabels(["Job Title", "Worker NIC", "Applied At", "Status", "Actions"])
        self.apps_table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        layout.addWidget(self.apps_table)
        
        widget.setLayout(layout)
        return widget
    
    def create_reviews_tab(self) -> QWidget:
        """Create the reviews tab."""
        widget = QWidget()
        layout = QVBoxLayout()
        
        # Review Form
        form_layout = QHBoxLayout()
        
        self.review_worker_input = QLineEdit()
        self.review_worker_input.setPlaceholderText("Worker NIC")
        form_layout.addWidget(self.review_worker_input)
        
        self.review_rating_input = QDoubleSpinBox()
        self.review_rating_input.setMinimum(0)
        self.review_rating_input.setMaximum(5)
        self.review_rating_input.setValue(5)
        form_layout.addWidget(self.review_rating_input)
        
        self.review_comment_input = QLineEdit()
        self.review_comment_input.setPlaceholderText("Comment")
        form_layout.addWidget(self.review_comment_input)
        
        submit_review_btn = QPushButton("Submit Review")
        submit_review_btn.clicked.connect(self.submit_review)
        form_layout.addWidget(submit_review_btn)
        
        layout.addLayout(form_layout)
        
        # Reviews Table
        self.reviews_table = QTableWidget()
        self.reviews_table.setColumnCount(5)
        self.reviews_table.setHorizontalHeaderLabels(["Worker NIC", "Rating", "Comment", "Date", "Actions"])
        self.reviews_table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        layout.addWidget(self.reviews_table)
        
        widget.setLayout(layout)
        return widget
    
    def load_data(self):
        """Load jobs, applications, and reviews from Supabase."""
        try:
            # Load jobs for this employer
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/jobs",
                headers=api_headers(),
                params={"employer_nic": f"eq.{self.employer_nic}", "select": "*"},
                timeout=10
            )
            if response.status_code == 200:
                self.jobs = [Job(**job) for job in response.json()]
                self.refresh_jobs_table()
            
            # Load applications for this employer's jobs
            job_ids = [job.id for job in self.jobs]
            if job_ids:
                response = requests.get(
                    f"{SUPABASE_URL}/rest/v1/applications",
                    headers=api_headers(),
                    params={"job_id": f"in.({','.join(job_ids)})", "select": "*"},
                    timeout=10
                )
                if response.status_code == 200:
                    self.applications = [Application(**app) for app in response.json()]
                    self.refresh_applications_table()
            
            # Load reviews submitted by this employer
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/reviews",
                headers=api_headers(),
                params={"reviewer_nic": f"eq.{self.employer_nic}", "select": "*"},
                timeout=10
            )
            if response.status_code == 200:
                self.refresh_reviews_table([Review(**r) for r in response.json()])
            
            QMessageBox.information(self, "Success", "Data loaded successfully")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to load data: {e}")
    
    def post_job(self):
        """Post a new job."""
        title = self.job_title_input.text()
        description = self.job_desc_input.text()
        location = self.job_location_input.text()
        
        if not all([title, description, location]):
            QMessageBox.warning(self, "Validation", "Please fill in all job fields")
            return
        
        job_data = {
            "title": title,
            "description": description,
            "employer_nic": self.employer_nic,
            "location": location,
            "status": "open",
            "required_skills": [],
            "applied_worker_ids": [],
            "accepted_worker_ids": [],
            "created_at": datetime.utcnow().isoformat() + "Z"
        }
        
        try:
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/jobs",
                headers=api_headers(),
                json=job_data,
                timeout=10
            )
            if response.status_code == 201:
                QMessageBox.information(self, "Success", "Job posted successfully!")
                self.job_title_input.clear()
                self.job_desc_input.clear()
                self.job_location_input.clear()
                self.load_data()
            else:
                QMessageBox.critical(self, "Error", f"Failed to post job: {response.text}")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Error posting job: {e}")
    
    def submit_review(self):
        """Submit a review for a worker."""
        worker_nic = self.review_worker_input.text()
        rating = self.review_rating_input.value()
        comment = self.review_comment_input.text()
        
        if not worker_nic:
            QMessageBox.warning(self, "Validation", "Please enter a worker NIC")
            return
        
        review_data = {
            "reviewer_nic": self.employer_nic,
            "worker_nic": worker_nic.upper(),
            "rating": float(rating),
            "comment": comment,
            "created_at": datetime.utcnow().isoformat() + "Z"
        }
        
        try:
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/reviews",
                headers=api_headers(),
                json=review_data,
                timeout=10
            )
            if response.status_code == 201:
                QMessageBox.information(self, "Success", "Review submitted!")
                self.review_worker_input.clear()
                self.review_comment_input.clear()
                self.load_data()
            else:
                QMessageBox.critical(self, "Error", f"Failed to submit review: {response.text}")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Error submitting review: {e}")
    
    def refresh_jobs_table(self):
        """Refresh the jobs table."""
        self.jobs_table.setRowCount(len(self.jobs))
        for i, job in enumerate(self.jobs):
            self.jobs_table.setItem(i, 0, QTableWidgetItem(job.title))
            self.jobs_table.setItem(i, 1, QTableWidgetItem(job.location))
            self.jobs_table.setItem(i, 2, QTableWidgetItem(job.status))
            self.jobs_table.setItem(i, 3, QTableWidgetItem(str(len(job.applied_worker_ids))))
            self.jobs_table.setItem(i, 4, QTableWidgetItem(str(len(job.accepted_worker_ids))))
            
            # Actions button (placeholder)
            action_btn = QPushButton("Manage")
            action_btn.clicked.connect(lambda checked, job_id=job.id: self.manage_job(job_id))
            self.jobs_table.setCellWidget(i, 5, action_btn)
    
    def refresh_applications_table(self):
        """Refresh the applications table."""
        self.apps_table.setRowCount(len(self.applications))
        for i, app in enumerate(self.applications):
            # Find job title
            job = next((j for j in self.jobs if j.id == app.job_id), None)
            job_title = job.title if job else app.job_id
            
            self.apps_table.setItem(i, 0, QTableWidgetItem(job_title))
            self.apps_table.setItem(i, 1, QTableWidgetItem(app.worker_nic))
            self.apps_table.setItem(i, 2, QTableWidgetItem(app.applied_at[:10]))
            self.apps_table.setItem(i, 3, QTableWidgetItem(app.status))
            
            # Actions button
            action_btn = QPushButton("Review")
            action_btn.clicked.connect(lambda checked, app_id=app.id: self.review_application(app_id))
            self.apps_table.setCellWidget(i, 4, action_btn)
    
    def refresh_reviews_table(self, reviews: List[Review]):
        """Refresh the reviews table."""
        self.reviews_table.setRowCount(len(reviews))
        for i, review in enumerate(reviews):
            self.reviews_table.setItem(i, 0, QTableWidgetItem(review.worker_nic))
            self.reviews_table.setItem(i, 1, QTableWidgetItem(f"{review.rating}/5"))
            self.reviews_table.setItem(i, 2, QTableWidgetItem(review.comment))
            self.reviews_table.setItem(i, 3, QTableWidgetItem(review.created_at[:10]))
            
            # Actions button
            action_btn = QPushButton("Edit")
            action_btn.clicked.connect(lambda checked, review_id=review.id: self.edit_review(review_id))
            self.reviews_table.setCellWidget(i, 4, action_btn)
    
    def manage_job(self, job_id: str):
        """Manage a job."""
        QMessageBox.information(self, "Job Management", f"Managing job: {job_id}")
    
    def review_application(self, app_id: str):
        """Review an application."""
        QMessageBox.information(self, "Application Review", f"Reviewing application: {app_id}")
    
    def edit_review(self, review_id: str):
        """Edit a review."""
        QMessageBox.information(self, "Edit Review", f"Editing review: {review_id}")


def main():
    app = QApplication(sys.argv)
    
    # Check for required environment variables
    if not SUPABASE_ANON_KEY:
        print("Error: SUPABASE_ANON_KEY environment variable not set")
        print("Please set SUPABASE_ANON_KEY before running this application")
        sys.exit(1)
    
    window = EmployeeManagementSystem(employer_nic="EMPLOYER001")
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
