import sys
import os
from PyQt6.QtWidgets import QApplication, QMainWindow, QStackedWidget, QMessageBox
from localization import LanguageProvider
from api_client import ApiClient

# --- CONFIGURATION ---
USE_MOCK_DATA = True 
# ---------------------

class MockApiClient:
    def __init__(self): self.token = "mock_token"
    def login(self, nic, pin): return True, "Mock Login Successful"
    def get_my_posted_jobs(self):
        return [
            {"id": "1", "title": "Tea Estate Workers (50)", "area": "Nuwara Eliya", "status": "open", "applied_worker_ids": ["w1", "w2", "w3"]},
            {"id": "2", "title": "Construction Team", "area": "Colombo", "status": "assigned", "applied_worker_ids": ["w4", "w5"]},
            {"id": "3", "title": "Cinnamon Peeling Project", "area": "Galle", "status": "completed", "applied_worker_ids": ["w1", "w6", "w7", "w8"]},
        ]
    def get_job_applicants(self, job_id):
        return [
            {"nic": "200012345678", "first_name": "Kumara", "last_name": "Perera", "rating": 4.8},
            {"nic": "199588887777", "first_name": "Samantha", "last_name": "Fernando", "rating": 4.5},
            {"nic": "198855554444", "first_name": "Nimal", "last_name": "Siriwardena", "rating": 4.2},
        ]

from ui.login_view import LoginView
from ui.dashboard_view import DashboardView
from ui.job_details_view import JobDetailsView
from ui.worker_profile_view import WorkerProfileView

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Workforce Management Portal")
        self.resize(1200, 850)
        self.setStyleSheet("background-color: #f8f9fa;")
        
        self.lp = LanguageProvider()
        self.api_client = MockApiClient() if USE_MOCK_DATA else ApiClient("https://informal-worker.onrender.com") 
        
        self.stack = QStackedWidget()
        self.setCentralWidget(self.stack)

        self.login_view = LoginView(self.api_client, self.show_dashboard, self.lp)
        self.dashboard_view = DashboardView(self.api_client, self.lp, self.show_job_details, self.post_job_action)
        self.details_view = JobDetailsView(self.api_client, self.lp, self.show_dashboard, self.show_worker_profile)
        self.profile_view = WorkerProfileView(self.api_client, self.lp, self.back_to_job)

        self.stack.addWidget(self.login_view)
        self.stack.addWidget(self.dashboard_view)
        self.stack.addWidget(self.details_view)
        self.stack.addWidget(self.profile_view)

    def show_dashboard(self):
        self.dashboard_view.update_ui()
        self.stack.setCurrentWidget(self.dashboard_view)

    def show_job_details(self, job):
        self.details_view.set_job(job)
        self.stack.setCurrentWidget(self.details_view)

    def show_worker_profile(self, worker):
        self.profile_view.set_worker(worker)
        self.stack.setCurrentWidget(self.profile_view)

    def back_to_job(self):
        self.stack.setCurrentWidget(self.details_view)

    def post_job_action(self):
        QMessageBox.information(self, self.lp.t('post_job'), "Job Posting Form")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
