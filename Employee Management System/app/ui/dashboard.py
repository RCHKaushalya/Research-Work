import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List
import requests
from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QTabWidget, QPushButton, QLineEdit,
    QTextEdit, QLabel, QTableWidget, QTableWidgetItem, QDialog, QComboBox,
    QDoubleSpinBox, QMessageBox, QDateTimeEdit, QHeaderView, QListWidget,
    QListWidgetItem, QSplitter, QFormLayout, QGroupBox
)
from PyQt6.QtCore import Qt, QDateTime, QTimer
from PyQt6.QtGui import QFont
from app.config import SUPABASE_URL, api_headers, send_sms_via_gateway
from app.models import Job, Application, Review

class EmployeeManagementSystem(QWidget):
    def __init__(self, parent_window, employer_nic: str, employer_name: str):
        super().__init__()
        self.parent_window = parent_window
        self.employer_nic = employer_nic
        self.employer_name = employer_name
        self.jobs: List[Job] = []
        self.applications: List[Application] = []
        self.all_users: List[Dict[str, Any]] = []

        self.load_groups()
        self.init_ui()
        self.load_data()

    def load_groups(self):
        self.groups_file = Path(__file__).parent / "groups.json"
        if self.groups_file.exists():
            try:
                all_groups = json.loads(self.groups_file.read_text(encoding="utf-8"))
                self.groups = all_groups.get(self.employer_nic, {})
            except Exception:
                self.groups = {}
        else:
            self.groups = {}

    def save_groups(self):
        all_groups = {}
        if self.groups_file.exists():
            try:
                all_groups = json.loads(self.groups_file.read_text(encoding="utf-8"))
            except Exception:
                all_groups = {}
        all_groups[self.employer_nic] = self.groups
        try:
            self.groups_file.write_text(json.dumps(all_groups, indent=4), encoding="utf-8")
        except Exception as e:
            print(f"Error saving groups: {e}")

    def init_ui(self):
        """Initialize the UI."""
        layout = QVBoxLayout()
        self.setLayout(layout)

        # Header
        header_layout = QHBoxLayout()
        employer_label = QLabel(f"Employer: {self.employer_name} ({self.employer_nic})")
        employer_label.setFont(QFont("Arial", 12, QFont.Weight.Bold))
        employer_label.setStyleSheet("color: #3182ce;")
        header_layout.addWidget(employer_label)
        header_layout.addStretch()

        refresh_btn = QPushButton("Refresh Data")
        refresh_btn.clicked.connect(self.load_data)
        header_layout.addWidget(refresh_btn)

        logout_btn = QPushButton("Logout")
        logout_btn.clicked.connect(self.parent_window.logout)
        logout_btn.setStyleSheet("background-color: #e53e3e; color: white;")
        header_layout.addWidget(logout_btn)

        layout.addLayout(header_layout)

        # Tabs
        self.tabs = QTabWidget()

        # Job Management Tab
        jobs_widget = self.create_jobs_tab()
        self.tabs.addTab(jobs_widget, "Jobs")

        # Applications Tab
        apps_widget = self.create_applications_tab()
        self.tabs.addTab(apps_widget, "Requested Workers (Requests)")

        # Workers Tab
        workers_widget = self.create_workers_tab()
        self.tabs.addTab(workers_widget, "Workers & Employees")

        # Worker Reviews Tab
        reviews_widget = self.create_reviews_tab()
        self.tabs.addTab(reviews_widget, "Reviews")

        layout.addWidget(self.tabs)

    def create_jobs_tab(self) -> QWidget:
        """Create the job management tab."""
        widget = QWidget()
        layout = QVBoxLayout()

        # New Job Form Group Box
        form_group = QGroupBox("Post a New Job")
        form_layout = QFormLayout()
        form_group.setLayout(form_layout)

        self.job_title_input = QLineEdit()
        self.job_title_input.setPlaceholderText("e.g. Masonry Work")
        form_layout.addRow("Job Title:", self.job_title_input)

        self.job_desc_input = QLineEdit()
        self.job_desc_input.setPlaceholderText("e.g. Building a brick wall at the site")
        form_layout.addRow("Description:", self.job_desc_input)

        self.job_location_input = QLineEdit()
        self.job_location_input.setPlaceholderText("e.g. Colombo (District)")
        form_layout.addRow("Location:", self.job_location_input)

        self.job_category_input = QLineEdit()
        self.job_category_input.setPlaceholderText("e.g. Construction")
        form_layout.addRow("Category:", self.job_category_input)

        self.job_skills_input = QLineEdit()
        self.job_skills_input.setPlaceholderText("e.g. bricklaying, masonry (comma separated)")
        form_layout.addRow("Required Skills:", self.job_skills_input)

        post_job_btn = QPushButton("Post Job & Notify Matching Workers")
        post_job_btn.clicked.connect(self.post_job)
        form_layout.addRow("", post_job_btn)

        layout.addWidget(form_group)

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

    def create_workers_tab(self) -> QWidget:
        widget = QWidget()
        main_layout = QHBoxLayout()
        widget.setLayout(main_layout)

        splitter = QSplitter(Qt.Orientation.Horizontal)
        main_layout.addWidget(splitter)

        # Left Panel - Search & All Workers
        left_widget = QWidget()
        left_layout = QVBoxLayout()
        left_widget.setLayout(left_layout)

        search_layout = QHBoxLayout()
        self.worker_search_input = QLineEdit()
        self.worker_search_input.setPlaceholderText("Search all workers by name, NIC, location, skills...")
        self.worker_search_input.textChanged.connect(self.filter_workers)
        search_layout.addWidget(self.worker_search_input)
        left_layout.addLayout(search_layout)

        self.workers_table = QTableWidget()
        self.workers_table.setColumnCount(4)
        self.workers_table.setHorizontalHeaderLabels(["Name", "NIC", "Location", "Skills"])
        self.workers_table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.workers_table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.workers_table.setSelectionMode(QTableWidget.SelectionMode.SingleSelection)
        left_layout.addWidget(self.workers_table)

        # Left Actions (Removed Unilateral Job Assignment to enforce application flow)
        left_actions = QHBoxLayout()

        add_group_btn = QPushButton("Add to Group")
        add_group_btn.clicked.connect(self.add_selected_worker_to_group)
        left_actions.addWidget(add_group_btn)

        log_pay_btn = QPushButton("Log Payment")
        log_pay_btn.clicked.connect(self.log_payment_for_selected_worker)
        left_actions.addWidget(log_pay_btn)

        msg_btn = QPushButton("Message")
        msg_btn.clicked.connect(self.message_selected_worker)
        left_actions.addWidget(msg_btn)

        left_layout.addLayout(left_actions)

        splitter.addWidget(left_widget)

        # Right Panel - Custom Groups & My Workers
        right_widget = QWidget()
        right_layout = QVBoxLayout()
        right_widget.setLayout(right_layout)

        group_header = QHBoxLayout()
        group_header.addWidget(QLabel("Group:"))
        self.group_combo = QComboBox()
        self.group_combo.currentTextChanged.connect(self.refresh_group_workers_list)
        group_header.addWidget(self.group_combo)

        create_grp_btn = QPushButton("New Group")
        create_grp_btn.clicked.connect(self.create_new_group)
        group_header.addWidget(create_grp_btn)

        delete_grp_btn = QPushButton("Delete Group")
        delete_grp_btn.clicked.connect(self.delete_current_group)
        group_header.addWidget(delete_grp_btn)

        right_layout.addLayout(group_header)

        self.group_workers_list = QListWidget()
        right_layout.addWidget(self.group_workers_list)

        # Right Actions
        right_actions = QHBoxLayout()
        remove_from_grp_btn = QPushButton("Remove from Group")
        remove_from_grp_btn.clicked.connect(self.remove_selected_worker_from_group)
        right_actions.addWidget(remove_from_grp_btn)
        right_layout.addLayout(right_actions)

        splitter.addWidget(right_widget)

        # Adjust splitter sizes
        splitter.setSizes([650, 450])

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
        """Load jobs, applications, workers, and reviews from Supabase."""
        try:
            # 1. Load all users
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/users",
                headers=api_headers(),
                params={"select": "*"},
                timeout=10
            )
            if response.status_code == 200:
                self.all_users = response.json()
                self.refresh_workers_table()

            # 2. Load jobs for this employer
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/jobs",
                headers=api_headers(),
                params={"employer_nic": f"eq.{self.employer_nic}", "select": "*"},
                timeout=10
            )
            if response.status_code == 200:
                jobs_data = response.json()
                self.jobs = []
                for j in jobs_data:
                    self.jobs.append(Job(
                        id=j["id"],
                        title=j["title"],
                        description=j["description"],
                        employer_nic=j["employer_nic"],
                        location=j["location"],
                        status=j["status"],
                        required_skills=j.get("required_skills") or [],
                        applied_worker_ids=j.get("applied_worker_ids") or [],
                        accepted_worker_ids=j.get("accepted_worker_ids") or [],
                        payments=j.get("payments") or [],
                        created_at=j["created_at"]
                    ))
                self.refresh_jobs_table()

            # 3. Load applications for this employer's jobs
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
            else:
                self.applications = []
                self.refresh_applications_table()

            # 4. Load reviews submitted by this employer
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/reviews",
                headers=api_headers(),
                params={"reviewer_nic": f"eq.{self.employer_nic}", "select": "*"},
                timeout=10
            )
            if response.status_code == 200:
                self.refresh_reviews_table([Review(**r) for r in response.json()])

            self.refresh_group_combo()
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to load data: {e}")

    def post_job(self):
        """Post a new job and notify matching workers in the area with same skills."""
        title = self.job_title_input.text().strip()
        description = self.job_desc_input.text().strip()
        location = self.job_location_input.text().strip()
        category = self.job_category_input.text().strip() or "General"
        skills_raw = self.job_skills_input.text().strip()

        skills = [s.strip().lower() for s in skills_raw.split(",") if s.strip()]

        if not all([title, description, location]):
            QMessageBox.warning(self, "Validation", "Please fill in Title, Description, and Location")
            return

        job_data = {
            "title": title,
            "description": description,
            "employer_nic": self.employer_nic,
            "location": location,
            "category": category,
            "status": "open",
            "required_skills": skills,
            "applied_worker_ids": [],
            "accepted_worker_ids": [],
            "payments": [],
            "created_at": datetime.utcnow().isoformat() + "Z"
        }

        try:
            # POST with return=representation preference to retrieve job id
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/jobs",
                headers=api_headers(prefer_representation=True),
                json=job_data,
                timeout=10
            )
            if response.status_code == 201:
                created_jobs = response.json()
                job_id = created_jobs[0]["id"] if created_jobs else None
                job_prefix = job_id[:4] if job_id else "xxxx"

                QMessageBox.information(self, "Success", f"Job posted successfully! (ID Prefix: {job_prefix})")
                
                # Clear form
                self.job_title_input.clear()
                self.job_desc_input.clear()
                self.job_location_input.clear()
                self.job_category_input.clear()
                self.job_skills_input.clear()
                
                # Load fresh data
                self.load_data()

                # Filter matching workers in the area with the same skills
                matching_workers = []
                for worker in self.all_users:
                    if worker["nic"] == self.employer_nic:
                        continue

                    # 1. Match Location (district or ds_area)
                    worker_loc = worker.get("district", "").strip().lower()
                    worker_ds = worker.get("ds_area", "").strip().lower()
                    job_loc = location.strip().lower()

                    loc_match = (worker_loc == job_loc or worker_ds == job_loc)

                    # 2. Match Skills
                    skills_match = False
                    if not skills:
                        skills_match = True
                    else:
                        worker_skills = [s.strip().lower() for s in worker.get("skill_ids", [])]
                        for s in skills:
                            if s in worker_skills:
                                skills_match = True
                                break

                    if loc_match and skills_match:
                        matching_workers.append(worker)

                # Broadcast notifications via SMS
                notified_count = 0
                for w in matching_workers:
                    phone = w.get("phone")
                    if phone:
                        msg = f"New Job: {title} in {location}. Reply '{job_prefix} 1' to apply."
                        try:
                            send_sms_via_gateway(phone, msg, timeout=5)
                            notified_count += 1
                        except Exception as ex:
                            print(f"Failed to send matching job notification to {phone}: {ex}")

                if matching_workers:
                    QMessageBox.information(self, "SMS Broadcast Status", f"Notified {notified_count} matching workers in the area via SMS.")
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

            # Actions button
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
            action_btn = QPushButton("Review Request")
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

            action_btn = QPushButton("Details")
            action_btn.clicked.connect(lambda checked, r_id=review.id: self.edit_review(r_id))
            self.reviews_table.setCellWidget(i, 4, action_btn)

    def filter_workers(self):
        self.refresh_workers_table()

    def refresh_workers_table(self):
        self.workers_table.setRowCount(0)
        search_text = self.worker_search_input.text().strip().lower()

        self.filtered_users = []
        for u in self.all_users:
            if u["nic"] == self.employer_nic:
                continue

            # Match search filter
            name = f"{u.get('first_name', '')} {u.get('last_name', '')}".lower()
            nic = u["nic"].lower()
            district = u.get("district", "").lower()
            skills = ", ".join(u.get("skill_ids", [])).lower()

            if search_text and search_text not in name and search_text not in nic and search_text not in district and search_text not in skills:
                continue

            self.filtered_users.append(u)

        self.workers_table.setRowCount(len(self.filtered_users))
        for i, u in enumerate(self.filtered_users):
            self.workers_table.setItem(i, 0, QTableWidgetItem(f"{u.get('first_name', '')} {u.get('last_name', '')}"))
            self.workers_table.setItem(i, 1, QTableWidgetItem(u["nic"]))
            self.workers_table.setItem(i, 2, QTableWidgetItem(u.get("district", "")))
            self.workers_table.setItem(i, 3, QTableWidgetItem(", ".join(u.get("skill_ids", []))))

    def refresh_group_combo(self):
        self.group_combo.blockSignals(True)
        current = self.group_combo.currentText()
        self.group_combo.clear()
        self.group_combo.addItem("All Accepted Workers")
        for group_name in self.groups.keys():
            self.group_combo.addItem(group_name)
        if current:
            idx = self.group_combo.findText(current)
            if idx != -1:
                self.group_combo.setCurrentIndex(idx)
        self.group_combo.blockSignals(False)
        self.refresh_group_workers_list()

    def refresh_group_workers_list(self):
        self.group_workers_list.clear()
        selected_group = self.group_combo.currentText()

        worker_nics = []
        if selected_group == "All Accepted Workers" or not selected_group:
            for job in self.jobs:
                for nic in job.accepted_worker_ids:
                    if nic not in worker_nics:
                        worker_nics.append(nic)
            for app in self.applications:
                if app.status == "accepted" and app.worker_nic not in worker_nics:
                    worker_nics.append(app.worker_nic)
        else:
            worker_nics = self.groups.get(selected_group, [])

        for nic in worker_nics:
            user = next((u for u in self.all_users if u["nic"] == nic), None)
            if user:
                display_name = f"{user.get('first_name', '')} {user.get('last_name', '')} ({nic})"
            else:
                display_name = f"Unknown Worker ({nic})"

            item = QListWidgetItem(display_name)
            item.setData(Qt.ItemDataRole.UserRole, nic)
            self.group_workers_list.addItem(item)

    def create_new_group(self):
        from PyQt6.QtWidgets import QInputDialog
        group_name, ok = QInputDialog.getText(self, "Create Group", "Enter Group Name:")
        if ok and group_name.strip():
            name = group_name.strip()
            if name in self.groups:
                QMessageBox.warning(self, "Warning", "Group already exists.")
                return
            self.groups[name] = []
            self.save_groups()
            self.refresh_group_combo()
            idx = self.group_combo.findText(name)
            if idx != -1:
                self.group_combo.setCurrentIndex(idx)

    def delete_current_group(self):
        selected = self.group_combo.currentText()
        if selected == "All Accepted Workers" or not selected:
            QMessageBox.warning(self, "Warning", "Cannot delete the default list.")
            return
        confirm = QMessageBox.question(
            self, "Confirm Delete", f"Are you sure you want to delete group '{selected}'?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        if confirm == QMessageBox.StandardButton.Yes:
            self.groups.pop(selected, None)
            self.save_groups()
            self.refresh_group_combo()

    def add_selected_worker_to_group(self):
        row = self.workers_table.currentRow()
        if row == -1:
            QMessageBox.warning(self, "Selection Required", "Please select a worker from the search table.")
            return
        worker = self.filtered_users[row]
        worker_nic = worker["nic"]

        groups_list = list(self.groups.keys())
        if not groups_list:
            QMessageBox.warning(self, "No Groups", "Please create a custom group first.")
            return

        from PyQt6.QtWidgets import QInputDialog
        group_name, ok = QInputDialog.getItem(self, "Add to Group", "Select Group:", groups_list, 0, False)
        if ok and group_name:
            if worker_nic in self.groups[group_name]:
                QMessageBox.information(self, "Info", "Worker is already in this group.")
                return
            self.groups[group_name].append(worker_nic)
            self.save_groups()
            self.refresh_group_workers_list()
            QMessageBox.information(self, "Success", f"Worker added to group '{group_name}'.")

    def remove_selected_worker_from_group(self):
        selected_group = self.group_combo.currentText()
        if selected_group == "All Accepted Workers":
            QMessageBox.warning(self, "Warning", "Cannot manually remove from the auto-generated accepted list.")
            return

        item = self.group_workers_list.currentItem()
        if not item:
            QMessageBox.warning(self, "Selection Required", "Please select a worker from the group list.")
            return
        worker_nic = item.data(Qt.ItemDataRole.UserRole)

        confirm = QMessageBox.question(
            self, "Confirm Remove", f"Remove worker {worker_nic} from group '{selected_group}'?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        if confirm == QMessageBox.StandardButton.Yes:
            if worker_nic in self.groups[selected_group]:
                self.groups[selected_group].remove(worker_nic)
                self.save_groups()
                self.refresh_group_workers_list()

    def log_payment_for_selected_worker(self):
        worker_nic = None
        row = self.workers_table.currentRow()
        if row == -1:
            item = self.group_workers_list.currentItem()
            if item:
                worker_nic = item.data(Qt.ItemDataRole.UserRole)
            else:
                QMessageBox.warning(self, "Selection Required", "Please select a worker from either list.")
                return
        else:
            worker = self.filtered_users[row]
            worker_nic = worker["nic"]

        worker_jobs = []
        for job in self.jobs:
            if worker_nic in job.accepted_worker_ids:
                worker_jobs.append(job)

        if not worker_jobs:
            QMessageBox.warning(self, "No Jobs", "This worker is not assigned to any of your jobs yet.")
            return

        dialog = QDialog(self)
        dialog.setWindowTitle(f"Log Payment for {worker_nic}")
        dialog.setGeometry(300, 300, 400, 250)

        layout = QFormLayout()
        dialog.setLayout(layout)

        job_combo = QComboBox()
        for j in worker_jobs:
            job_combo.addItem(f"{j.title} ({j.location})", j.id)
        layout.addRow("Select Job:", job_combo)

        amount_input = QDoubleSpinBox()
        amount_input.setRange(0.0, 1000000.0)
        amount_input.setSingleStep(500.0)
        amount_input.setValue(1000.0)
        layout.addRow("Amount (LKR):", amount_input)

        desc_input = QLineEdit()
        desc_input.setPlaceholderText("e.g. Daily wage, Advance, etc.")
        layout.addRow("Description:", desc_input)

        date_input = QDateTimeEdit()
        date_input.setDateTime(QDateTime.currentDateTime())
        layout.addRow("Date:", date_input)

        btn_box = QHBoxLayout()
        submit_btn = QPushButton("Submit")
        cancel_btn = QPushButton("Cancel")

        btn_box.addWidget(submit_btn)
        btn_box.addWidget(cancel_btn)
        layout.addRow(btn_box)

        def handle_submit():
            job_id = job_combo.currentData()
            amount = amount_input.value()
            desc = desc_input.text().strip()
            date_str = date_input.dateTime().toString("yyyy-MM-ddTHH:mm:ss") + "Z"

            if not desc:
                QMessageBox.warning(dialog, "Input Error", "Please enter a description.")
                return

            job = next(j for j in worker_jobs if j.id == job_id)
            existing_payments = list(job.payments) if job.payments else []

            new_payment = {
                "worker_nic": worker_nic,
                "amount": amount,
                "date": date_str,
                "description": desc
            }
            existing_payments.append(new_payment)

            try:
                response = requests.patch(
                    f"{SUPABASE_URL}/rest/v1/jobs",
                    headers=api_headers(),
                    params={"id": f"eq.{job_id}"},
                    json={"payments": existing_payments},
                    timeout=10
                )
                if response.status_code in [200, 204]:
                    QMessageBox.information(dialog, "Success", "Payment successfully logged!")
                    dialog.accept()
                    self.load_data()
                else:
                    QMessageBox.critical(dialog, "Error", f"Failed to log payment: {response.text}")
            except Exception as e:
                QMessageBox.critical(dialog, "Error", f"Failed to log payment: {e}")

        submit_btn.clicked.connect(handle_submit)
        cancel_btn.clicked.connect(dialog.reject)

        dialog.exec()

    def message_selected_worker(self):
        worker_nic = None
        row = self.workers_table.currentRow()
        if row == -1:
            item = self.group_workers_list.currentItem()
            if item:
                worker_nic = item.data(Qt.ItemDataRole.UserRole)
            else:
                QMessageBox.warning(self, "Selection Required", "Please select a worker from either list.")
                return
        else:
            worker = self.filtered_users[row]
            worker_nic = worker["nic"]

        user = next((u for u in self.all_users if u["nic"] == worker_nic), None)
        worker_name = f"{user.get('first_name', '')} {user.get('last_name', '')}" if user else worker_nic
        worker_phone = user.get("phone", "") if user else ""

        dialog = QDialog(self)
        dialog.setWindowTitle(f"Message {worker_name} ({worker_nic})")
        dialog.setGeometry(300, 300, 500, 450)

        layout = QVBoxLayout()
        dialog.setLayout(layout)

        msg_tabs = QTabWidget()
        layout.addWidget(msg_tabs)

        # Tab 1: In-App Chat
        chat_widget = QWidget()
        chat_layout = QVBoxLayout()
        chat_widget.setLayout(chat_layout)

        chat_display = QTextEdit()
        chat_display.setReadOnly(True)
        chat_layout.addWidget(chat_display)

        input_layout = QHBoxLayout()
        chat_input = QLineEdit()
        chat_input.setPlaceholderText("Type a message...")
        input_layout.addWidget(chat_input)

        send_chat_btn = QPushButton("Send")
        input_layout.addWidget(send_chat_btn)
        chat_layout.addLayout(input_layout)

        msg_tabs.addTab(chat_widget, "In-App Chat")

        # Tab 2: Send SMS Gateway
        sms_widget = QWidget()
        sms_layout = QVBoxLayout()
        sms_widget.setLayout(sms_layout)

        sms_layout.addWidget(QLabel(f"Send SMS directly to phone: {worker_phone}"))

        sms_input = QTextEdit()
        sms_input.setPlaceholderText("Write SMS message here...")
        sms_layout.addWidget(sms_input)

        send_sms_btn = QPushButton("Send SMS via Gateway")
        sms_layout.addWidget(send_sms_btn)

        msg_tabs.addTab(sms_widget, "SMS Gateway")

        chat_id = f"direct_{self.employer_nic}_{worker_nic}"

        def check_or_create_chat():
            try:
                response = requests.get(
                    f"{SUPABASE_URL}/rest/v1/chats",
                    headers=api_headers(),
                    params={"id": f"eq.{chat_id}", "select": "*"},
                    timeout=10
                )
                if response.status_code == 200 and not response.json():
                    chat_data = {
                        "id": chat_id,
                        "participant_ids": [self.employer_nic, worker_nic],
                        "type": "direct",
                        "title": f"Chat with {worker_name}",
                        "created_at": datetime.utcnow().isoformat() + "Z"
                    }
                    requests.post(
                        f"{SUPABASE_URL}/rest/v1/chats",
                        headers=api_headers(),
                        json=chat_data,
                        timeout=10
                    )
            except Exception as e:
                print(f"Error checking/creating chat: {e}")

        def load_messages():
            try:
                response = requests.get(
                    f"{SUPABASE_URL}/rest/v1/chat_messages",
                    headers=api_headers(),
                    params={"chat_id": f"eq.{chat_id}", "order": "created_at.asc", "select": "*"},
                    timeout=10
                )
                if response.status_code == 200:
                    messages = response.json()
                    chat_text = ""
                    for m in messages:
                        sender = "You" if m["sender_id"] == self.employer_nic else worker_name
                        time_part = m.get("created_at", "")[11:16]
                        chat_text += f"[{time_part}] <b>{sender}</b>: {m['text']}<br>"
                    chat_display.setHtml(chat_text)
                    chat_display.verticalScrollBar().setValue(chat_display.verticalScrollBar().maximum())
            except Exception as e:
                print(f"Error loading messages: {e}")

        def send_chat():
            text = chat_input.text().strip()
            if not text:
                return
            check_or_create_chat()

            msg_data = {
                "chat_id": chat_id,
                "sender_id": self.employer_nic,
                "text": text,
                "created_at": datetime.utcnow().isoformat() + "Z"
            }
            try:
                response = requests.post(
                    f"{SUPABASE_URL}/rest/v1/chat_messages",
                    headers=api_headers(),
                    json=msg_data,
                    timeout=10
                )
                if response.status_code == 201:
                    chat_input.clear()
                    load_messages()
                    requests.patch(
                        f"{SUPABASE_URL}/rest/v1/chats",
                        headers=api_headers(),
                        params={"id": f"eq.{chat_id}"},
                        json={"last_message": text, "last_message_time": datetime.utcnow().isoformat() + "Z"},
                        timeout=10
                    )
            except Exception as e:
                QMessageBox.critical(dialog, "Error", f"Failed to send message: {e}")

        def send_sms():
            text = sms_input.toPlainText().strip()
            if not text:
                QMessageBox.warning(dialog, "Input Error", "Please enter SMS message text.")
                return
            if not worker_phone:
                QMessageBox.warning(dialog, "Input Error", "This worker does not have a phone number registered.")
                return

            try:
                send_sms_via_gateway(worker_phone, text, timeout=10)
                QMessageBox.information(dialog, "Success", "SMS message sent successfully!")
                sms_input.clear()
            except Exception as e:
                QMessageBox.critical(dialog, "SMS Gateway Error", f"Could not send SMS: {e}")

        timer = QTimer(dialog)
        timer.timeout.connect(load_messages)
        timer.start(3000)

        check_or_create_chat()
        load_messages()

        send_chat_btn.clicked.connect(send_chat)
        chat_input.returnPressed.connect(send_chat)
        send_sms_btn.clicked.connect(send_sms)

        dialog.exec()
        timer.stop()

    def manage_job(self, job_id: str):
        """Manage a job's status."""
        job = next((j for j in self.jobs if j.id == job_id), None)
        if not job:
            return

        dialog = QDialog(self)
        dialog.setWindowTitle(f"Manage Job: {job.title}")
        dialog.setGeometry(300, 300, 350, 150)

        layout = QVBoxLayout()
        dialog.setLayout(layout)

        layout.addWidget(QLabel(f"Current Status: {job.status.upper()}"))

        status_combo = QComboBox()
        status_combo.addItems(["open", "in_progress", "completed", "cancelled"])
        idx = status_combo.findText(job.status)
        if idx != -1:
            status_combo.setCurrentIndex(idx)
        layout.addWidget(status_combo)

        btn_box = QHBoxLayout()
        save_btn = QPushButton("Save")
        cancel_btn = QPushButton("Cancel")
        btn_box.addWidget(save_btn)
        btn_box.addWidget(cancel_btn)
        layout.addLayout(btn_box)

        def save_status():
            new_status = status_combo.currentText()
            try:
                response = requests.patch(
                    f"{SUPABASE_URL}/rest/v1/jobs",
                    headers=api_headers(),
                    params={"id": f"eq.{job_id}"},
                    json={"status": new_status},
                    timeout=10
                )
                if response.status_code in [200, 204]:
                    QMessageBox.information(dialog, "Success", "Job status updated!")
                    dialog.accept()
                    self.load_data()
                else:
                    QMessageBox.critical(dialog, "Error", f"Failed to update status: {response.text}")
            except Exception as e:
                QMessageBox.critical(dialog, "Error", f"Failed to update: {e}")

        save_btn.clicked.connect(save_status)
        cancel_btn.clicked.connect(dialog.reject)
        dialog.exec()

    def review_application(self, app_id: str):
        """Review an application (request)."""
        app = next((a for a in self.applications if a.id == app_id), None)
        if not app:
            return

        dialog = QDialog(self)
        dialog.setWindowTitle(f"Review Request")
        dialog.setGeometry(300, 300, 400, 180)

        layout = QVBoxLayout()
        dialog.setLayout(layout)

        job = next((j for j in self.jobs if j.id == app.job_id), None)
        job_title = job.title if job else app.job_id

        layout.addWidget(QLabel(f"Worker NIC: {app.worker_nic}"))
        layout.addWidget(QLabel(f"Job: {job_title}"))
        layout.addWidget(QLabel(f"Applied At: {app.applied_at[:10]}"))
        layout.addWidget(QLabel(f"Current Status: {app.status.upper()}"))

        btn_box = QHBoxLayout()
        accept_btn = QPushButton("Accept Request (Select Worker)")
        accept_btn.setStyleSheet("background-color: #3182ce; color: white;")
        reject_btn = QPushButton("Reject Request")
        reject_btn.setStyleSheet("background-color: #e53e3e; color: white;")
        cancel_btn = QPushButton("Cancel")

        btn_box.addWidget(accept_btn)
        btn_box.addWidget(reject_btn)
        btn_box.addWidget(cancel_btn)
        layout.addLayout(btn_box)

        def update_app_status(new_status):
            try:
                response = requests.patch(
                    f"{SUPABASE_URL}/rest/v1/applications",
                    headers=api_headers(),
                    params={"id": f"eq.{app_id}"},
                    json={"status": new_status},
                    timeout=10
                )

                if new_status == "accepted" and job:
                    new_accepted = list(job.accepted_worker_ids)
                    if app.worker_nic not in new_accepted:
                        new_accepted.append(app.worker_nic)
                        requests.patch(
                            f"{SUPABASE_URL}/rest/v1/jobs",
                            headers=api_headers(),
                            params={"id": f"eq.{job.id}"},
                            json={"accepted_worker_ids": new_accepted},
                            timeout=10
                        )

                QMessageBox.information(dialog, "Success", f"Worker successfully selected/marked as {new_status}!")
                dialog.accept()
                self.load_data()
            except Exception as e:
                QMessageBox.critical(dialog, "Error", f"Failed to update application: {e}")

        accept_btn.clicked.connect(lambda: update_app_status("accepted"))
        reject_btn.clicked.connect(lambda: update_app_status("rejected"))
        cancel_btn.clicked.connect(dialog.reject)

        dialog.exec()

    def edit_review(self, review_id: str):
        """Edit or delete a review."""
        QMessageBox.information(self, "Edit Review", "To edit or delete reviews, please write a new review which will update the worker's average rating automatically.")

