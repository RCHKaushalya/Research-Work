import requests
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QLineEdit, QLabel, QMessageBox, QFormLayout
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QFont
from app.config import SUPABASE_URL, api_headers

class LoginWidget(QWidget):
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
        card.setFixedWidth(400)

        card_layout = QVBoxLayout()
        card.setLayout(card_layout)

        title = QLabel("WORKFORCE PLATFORM")
        title.setFont(QFont("Segoe UI", 16, QFont.Weight.Bold))
        title.setStyleSheet("color: #3182ce; margin-bottom: 5px;")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        card_layout.addWidget(title)

        subtitle = QLabel("Employer Portal Login")
        subtitle.setFont(QFont("Segoe UI", 11))
        subtitle.setStyleSheet("color: #718096; margin-bottom: 20px;")
        subtitle.setAlignment(Qt.AlignmentFlag.AlignCenter)
        card_layout.addWidget(subtitle)

        form_layout = QFormLayout()

        self.nic_input = QLineEdit()
        self.nic_input.setPlaceholderText("e.g. 200012345678")
        form_layout.addRow("NIC:", self.nic_input)

        self.password_input = QLineEdit()
        self.password_input.setEchoMode(QLineEdit.EchoMode.Password)
        self.password_input.setPlaceholderText("Password")
        form_layout.addRow("Password:", self.password_input)

        card_layout.addLayout(form_layout)
        card_layout.addSpacing(15)

        login_btn = QPushButton("Login")
        login_btn.clicked.connect(self.handle_login)
        card_layout.addWidget(login_btn)

        card_layout.addSpacing(10)

        register_link = QPushButton("Don't have an account? Register")
        register_link.setStyleSheet("""
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
        register_link.clicked.connect(self.parent_window.switch_to_register)
        card_layout.addWidget(register_link)

        hbox = QHBoxLayout()
        hbox.addStretch()
        hbox.addWidget(card)
        hbox.addStretch()

        main_layout.addLayout(hbox)
        main_layout.addStretch()

    def handle_login(self):
        nic = self.nic_input.text().strip().upper()
        password = self.password_input.text().strip()

        if not nic or not password:
            QMessageBox.warning(self, "Input Error", "Please enter your NIC and password.")
            return

        try:
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/users",
                headers=api_headers(),
                params={"nic": f"eq.{nic}", "password_hash": f"eq.{password}", "select": "*"},
                timeout=10
            )
            if response.status_code == 200:
                users = response.json()
                if users:
                    user = users[0]
                    if user.get("is_blocked", 0) == 1:
                        QMessageBox.critical(self, "Blocked", "Your account has been blocked. Contact support.")
                        return
                    self.parent_window.login_success(user)
                else:
                    QMessageBox.critical(self, "Login Failed", "Invalid NIC or Password.")
            else:
                QMessageBox.critical(self, "Error", f"Login failed: {response.text}")
        except Exception as e:
            QMessageBox.critical(self, "Connection Error", f"Failed to connect to backend: {e}")


