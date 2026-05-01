from PyQt6.QtWidgets import QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton, QFrame, QMessageBox
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QFont

class LoginView(QWidget):
    def __init__(self, api_client, on_login_success, lp):
        super().__init__()
        self.api_client = api_client
        self.on_login_success = on_login_success
        self.lp = lp
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()
        layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        self.card = QFrame()
        self.card.setFixedWidth(420)
        self.card.setStyleSheet("""
            QFrame {
                background-color: white; 
                border: 1px solid #eee; 
                border-radius: 20px; 
                padding: 40px;
            }
        """)
        card_layout = QVBoxLayout(self.card)

        self.title_label = QLabel(self.lp.t('title'))
        self.title_label.setFont(QFont("Segoe UI", 22, QFont.Weight.Bold))
        self.title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.title_label.setStyleSheet("color: #333; border: none;")
        card_layout.addWidget(self.title_label)
        
        self.subtitle_label = QLabel(self.lp.t('subtitle'))
        self.subtitle_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.subtitle_label.setStyleSheet("color: #666; border: none; margin-bottom: 30px;")
        card_layout.addWidget(self.subtitle_label)

        self.nic_input = QLineEdit()
        self.nic_input.setPlaceholderText(self.lp.t('nic_hint'))
        self.nic_input.setFixedHeight(55)
        self.nic_input.setStyleSheet("padding: 15px; border: 1px solid #ddd; border-radius: 10px; background: #f9f9f9;")
        card_layout.addWidget(self.nic_input)

        self.pin_input = QLineEdit()
        self.pin_input.setPlaceholderText(self.lp.t('pin_hint'))
        self.pin_input.setEchoMode(QLineEdit.EchoMode.Password)
        self.pin_input.setFixedHeight(55)
        self.pin_input.setStyleSheet("padding: 15px; border: 1px solid #ddd; border-radius: 10px; background: #f9f9f9;")
        card_layout.addWidget(self.pin_input)

        self.login_btn = QPushButton(self.lp.t('login_btn'))
        self.login_btn.setFixedHeight(60)
        self.login_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        # FIX: Explicitly set text color to white and font weight
        self.login_btn.setStyleSheet("""
            QPushButton {
                background-color: #2196F3; 
                color: #FFFFFF; 
                border-radius: 10px; 
                font-weight: bold; 
                font-size: 16px;
                border: none;
            }
            QPushButton:hover {
                background-color: #1976D2;
            }
        """)
        self.login_btn.clicked.connect(self.handle_login)
        card_layout.addWidget(self.login_btn)

        self.lang_btn = QPushButton(self.lp.t('lang_switch'))
        self.lang_btn.setStyleSheet("color: #2196F3; border: none; margin-top: 20px; font-weight: bold;")
        self.lang_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self.lang_btn.clicked.connect(self.toggle_language)
        card_layout.addWidget(self.lang_btn)

        layout.addWidget(self.card)
        self.setLayout(layout)

    def toggle_language(self):
        self.lp.toggle()
        self.update_ui()

    def update_ui(self):
        self.title_label.setText(self.lp.t('title'))
        self.subtitle_label.setText(self.lp.t('subtitle'))
        self.nic_input.setPlaceholderText(self.lp.t('nic_hint'))
        self.pin_input.setPlaceholderText(self.lp.t('pin_hint'))
        self.login_btn.setText(self.lp.t('login_btn'))
        self.lang_btn.setText(self.lp.t('lang_switch'))

    def handle_login(self):
        nic = self.nic_input.text()
        pin = self.pin_input.text()
        success, message = self.api_client.login(nic, pin)
        if success: self.on_login_success()
        else: QMessageBox.critical(self, self.lp.t('error'), str(message))
