import sys
import os
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QLabel, QLineEdit, QPushButton, 
                             QStackedWidget, QTableWidget, QTableWidgetItem, 
                             QHeaderView, QMessageBox, QFrame)
from PyQt6.QtCore import Qt, QSize
from PyQt6.QtGui import QFont, QIcon
from qt_material import apply_stylesheet
from api_client import ApiClient

class LoginWindow(QWidget):
    def __init__(self, api_client, on_login_success):
        super().__init__()
        self.api_client = api_client
        self.on_login_success = on_login_success
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()
        layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        self.card = QFrame()
        self.card.setFixedWidth(400)
        self.card.setStyleSheet("background-color: #2b2b2b; border-radius: 15px; padding: 30px;")
        card_layout = QVBoxLayout(self.card)

        title = QLabel("Employer Management System")
        title.setFont(QFont("Segoe UI", 18, QFont.Weight.Bold))
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        card_layout.addWidget(title)
        
        subtitle = QLabel("Desktop Portal for High-Volume Jobs")
        subtitle.setAlignment(Qt.AlignmentFlag.AlignCenter)
        subtitle.setStyleSheet("color: #888888; margin-bottom: 20px;")
        card_layout.addWidget(subtitle)

        self.nic_input = QLineEdit()
        self.nic_input.setPlaceholderText("Enter NIC Number")
        self.nic_input.setFixedHeight(45)
        card_layout.addWidget(self.nic_input)

        self.pin_input = QLineEdit()
        self.pin_input.setPlaceholderText("Enter PIN")
        self.pin_input.setEchoMode(QLineEdit.EchoMode.Password)
        self.pin_input.setFixedHeight(45)
        card_layout.addWidget(self.pin_input)

        login_btn = QPushButton("Login to Dashboard")
        login_btn.setFixedHeight(50)
        login_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        login_btn.clicked.connect(self.handle_login)
        card_layout.addWidget(login_btn)

        layout.addWidget(self.card)
        self.setLayout(layout)

    def handle_login(self):
        nic = self.nic_input.text()
        pin = self.pin_input.text()
        success, message = self.api_client.login(nic, pin)
        if success:
            self.on_login_success()
        else:
            QMessageBox.critical(self, "Error", message)

class DashboardWindow(QWidget):
    def __init__(self, api_client):
        super().__init__()
        self.api_client = api_client
        self.init_ui()

    def init_ui(self):
        layout = QHBoxLayout()
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # Sidebar
        sidebar = QFrame()
        sidebar.setFixedWidth(250)
        sidebar.setStyleSheet("background-color: #1e1e1e; border-right: 1px solid #333;")
        sidebar_layout = QVBoxLayout(sidebar)
        
        brand = QLabel("SYSTEM PORTAL")
        brand.setFont(QFont("Segoe UI", 14, QFont.Weight.Bold))
        brand.setStyleSheet("padding: 20px; color: #2196F3;")
        sidebar_layout.addWidget(brand)

        nav_btns = ["Dashboard", "Active Jobs", "Team Management", "Settings"]
        for btn_text in nav_btns:
            btn = QPushButton(btn_text)
            btn.setFixedHeight(50)
            btn.setCursor(Qt.CursorShape.PointingHandCursor)
            btn.setStyleSheet("text-align: left; padding-left: 20px; border: none; font-size: 14px;")
            sidebar_layout.addWidget(btn)
        
        sidebar_layout.addStretch()
        
        logout_btn = QPushButton("Logout")
        logout_btn.setStyleSheet("color: #f44336; border: none; padding: 20px;")
        logout_btn.clicked.connect(lambda: QApplication.quit())
        sidebar_layout.addWidget(logout_btn)

        # Main Content
        main_area = QVBoxLayout()
        main_area.setContentsMargins(30, 30, 30, 30)
        
        header = QHBoxLayout()
        title = QLabel("Huge Jobs Command Center")
        title.setFont(QFont("Segoe UI", 20, QFont.Weight.Bold))
        header.addWidget(title)
        header.addStretch()
        
        refresh_btn = QPushButton("Refresh Data")
        refresh_btn.setFixedWidth(150)
        refresh_btn.clicked.connect(self.load_jobs)
        header.addWidget(refresh_btn)
        main_area.addLayout(header)

        # Job Table
        self.job_table = QTableWidget()
        self.job_table.setColumnCount(5)
        self.job_table.setHorizontalHeaderLabels(["Job Title", "Area", "Workers", "Status", "Actions"])
        self.job_table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.job_table.setStyleSheet("background-color: #2b2b2b; gridline-color: #333;")
        main_area.addWidget(self.job_table)

        layout.addWidget(sidebar)
        layout.addLayout(main_area)
        self.setLayout(layout)

    def load_jobs(self):
        jobs = self.api_client.get_my_posted_jobs()
        self.job_table.setRowCount(len(jobs))
        for i, job in enumerate(jobs):
            self.job_table.setItem(i, 0, QTableWidgetItem(job['title']))
            self.job_table.setItem(i, 1, QTableWidgetItem(job['area']))
            self.job_table.setItem(i, 2, QTableWidgetItem(str(len(job.get('applied_worker_ids', [])))))
            self.job_table.setItem(i, 3, QTableWidgetItem(job['status'].upper()))
            
            manage_btn = QPushButton("Manage Team")
            manage_btn.clicked.connect(lambda _, j=job: self.manage_team(j))
            self.job_table.setCellWidget(i, 4, manage_btn)

    def manage_team(self, job):
        QMessageBox.information(self, "Team Management", f"Opening Team Manager for: {job['title']}\nHere you can assign/remove multiple workers.")

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Workforce Employee Management System")
        self.resize(1100, 700)
        
        # Use localhost for local dev, or Render URL if hosted
        self.api_client = ApiClient("https://informal-worker.onrender.com") 
        
        self.stack = QStackedWidget()
        self.setCentralWidget(self.stack)

        self.login_window = LoginWindow(self.api_client, self.show_dashboard)
        self.dashboard_window = DashboardWindow(self.api_client)

        self.stack.addWidget(self.login_window)
        self.stack.addWidget(self.dashboard_window)

    def show_dashboard(self):
        self.dashboard_window.load_jobs()
        self.stack.setCurrentIndex(1)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    
    # Apply a premium dark theme
    apply_stylesheet(app, theme='dark_blue.xml')
    
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
