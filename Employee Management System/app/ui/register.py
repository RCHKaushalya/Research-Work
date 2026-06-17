from datetime import datetime
import requests
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QLineEdit, QLabel, QMessageBox, QFormLayout, QComboBox
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QFont
from app.config import SUPABASE_URL, api_headers

class RegisterWidget(QWidget):
    def __init__(self, parent_window):
        super().__init__()
        self.parent_window = parent_window
        self.init_ui()

    def init_ui(self):
        main_layout = QVBoxLayout()
        self.setLayout(main_layout)

        main_layout.addStretch()

        card = QWidget()
        card.setObjectName("AuthCard")
        card.setStyleSheet("""
            QWidget#AuthCard {
                background-color: #ffffff;
                border: 1px solid #cbd5e0;
                border-radius: 8px;
            }
        """)
        card.setFixedWidth(450)

        card_layout = QVBoxLayout()
        card.setLayout(card_layout)

        title = QLabel("WORKFORCE PLATFORM")
        title.setFont(QFont("Segoe UI", 16, QFont.Weight.Bold))
        title.setStyleSheet("color: #3182ce; margin-bottom: 5px;")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        card_layout.addWidget(title)

        subtitle = QLabel("Employer Registration")
        subtitle.setFont(QFont("Segoe UI", 11))
        subtitle.setStyleSheet("color: #718096; margin-bottom: 20px;")
        subtitle.setAlignment(Qt.AlignmentFlag.AlignCenter)
        card_layout.addWidget(subtitle)

        form_layout = QFormLayout()

        self.nic_input = QLineEdit()
        self.nic_input.setPlaceholderText("Required (e.g. 200012345678)")
        form_layout.addRow("NIC:", self.nic_input)

        self.first_name_input = QLineEdit()
        self.first_name_input.setPlaceholderText("Required")
        form_layout.addRow("First Name:", self.first_name_input)

        self.last_name_input = QLineEdit()
        self.last_name_input.setPlaceholderText("Required")
        form_layout.addRow("Last Name:", self.last_name_input)

        self.phone_input = QLineEdit()
        self.phone_input.setPlaceholderText("Required (e.g. +94771234567)")
        form_layout.addRow("Phone:", self.phone_input)

        self.password_input = QLineEdit()
        self.password_input.setEchoMode(QLineEdit.EchoMode.Password)
        self.password_input.setPlaceholderText("Required")
        form_layout.addRow("Password:", self.password_input)

        self.confirm_password_input = QLineEdit()
        self.confirm_password_input.setEchoMode(QLineEdit.EchoMode.Password)
        self.confirm_password_input.setPlaceholderText("Required")
        form_layout.addRow("Confirm Password:", self.confirm_password_input)

        self.district_combo = QComboBox()
        self.district_combo.addItems([
            "Colombo", "Gampaha", "Kalutara", "Kandy", "Matale", "Nuwara Eliya",
            "Galle", "Matara", "Hambantota", "Jaffna", "Kilinochchi", "Mannar",
            "Vavuniya", "Mullaitivu", "Batticaloa", "Ampara", "Trincomalee",
            "Kurunegala", "Puttalam", "Anuradhapura", "Polonnaruwa", "Badulla",
            "Moneragala", "Ratnapura", "Kegalle"
        ])
        form_layout.addRow("District:", self.district_combo)

        self.ds_area_input = QLineEdit()
        self.ds_area_input.setPlaceholderText("Optional DS Area")
        form_layout.addRow("DS Area:", self.ds_area_input)

        card_layout.addLayout(form_layout)
        card_layout.addSpacing(15)

        register_btn = QPushButton("Register")
        register_btn.clicked.connect(self.handle_register)
        card_layout.addWidget(register_btn)

        card_layout.addSpacing(10)

        login_link = QPushButton("Already have an account? Login")
        login_link.setStyleSheet("""
            QPushButton {
                background-color: transparent;
                color: #3182ce;
                font-weight: normal;
                text-decoration: underline;
            }
            QPushButton:hover {
                color: #4299e1;
            }
        """)
        login_link.clicked.connect(self.parent_window.switch_to_login)
        card_layout.addWidget(login_link)

        hbox = QHBoxLayout()
        hbox.addStretch()
        hbox.addWidget(card)
        hbox.addStretch()

        main_layout.addLayout(hbox)
        main_layout.addStretch()

    def handle_register(self):
        nic = self.nic_input.text().strip().upper()
        first_name = self.first_name_input.text().strip()
        last_name = self.last_name_input.text().strip()
        phone = self.phone_input.text().strip()
        password = self.password_input.text().strip()
        confirm_password = self.confirm_password_input.text().strip()
        district = self.district_combo.currentText()
        ds_area = self.ds_area_input.text().strip()

        if not all([nic, first_name, last_name, phone, password, confirm_password]):
            QMessageBox.warning(self, "Input Error", "Please fill in all required fields.")
            return

        if password != confirm_password:
            QMessageBox.warning(self, "Input Error", "Passwords do not match.")
            return

        try:
            # Query if NIC already exists
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/users",
                headers=api_headers(),
                params={"nic": f"eq.{nic}", "select": "nic"},
                timeout=10
            )
            if response.status_code == 200 and response.json():
                QMessageBox.warning(self, "Registration Error", "A user with this NIC already exists.")
                return

            # Register user
            user_data = {
                "nic": nic,
                "first_name": first_name,
                "last_name": last_name,
                "phone": phone,
                "password_hash": password,
                "district": district,
                "ds_area": ds_area,
                "verified": True,  # Auto-verified for this demo
                "availability_status": "available",
                "posted_jobs_count": 0,
                "applied_jobs_count": 0,
                "created_at": datetime.utcnow().isoformat() + "Z",
                "updated_at": datetime.utcnow().isoformat() + "Z"
            }

            register_response = requests.post(
                f"{SUPABASE_URL}/rest/v1/users",
                headers=api_headers(),
                json=user_data,
                timeout=10
            )
            if register_response.status_code == 201:
                QMessageBox.information(self, "Success", "Registration successful! You can now log in.")
                self.parent_window.switch_to_login()
            else:
                QMessageBox.critical(self, "Error", f"Registration failed: {register_response.text}")
        except Exception as e:
            QMessageBox.critical(self, "Connection Error", f"Failed to connect to backend: {e}")


