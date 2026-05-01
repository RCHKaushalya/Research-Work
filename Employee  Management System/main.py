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

# Localization Strings
STRINGS = {
    'si': {
        'title': 'සේවක කළමනාකරණ පද්ධතිය',
        'subtitle': 'විශාල රැකියා සඳහා ඩෙස්ක්ටොප් ද්වාරය',
        'nic_hint': 'NIC අංකය ඇතුළත් කරන්න',
        'pin_hint': 'PIN අංකය ඇතුළත් කරන්න',
        'login_btn': 'පාලක පුවරුවට පිවිසෙන්න',
        'brand': 'පද්ධති ද්වාරය',
        'nav_dash': 'පාලක පුවරුව',
        'nav_jobs': 'ක්‍රියාකාරී රැකියා',
        'nav_team': 'කණ්ඩායම් කළමනාකරණය',
        'nav_settings': 'සැකසුම්',
        'logout': 'පිටවෙන්න',
        'main_title': 'රැකියා මෙහෙයුම් මධ්‍යස්ථානය',
        'refresh': 'දත්ත යාවත්කාලීන කරන්න',
        'col_title': 'රැකියා මාතෘකාව',
        'col_area': 'ප්‍රදේශය',
        'col_workers': 'සේවකයින්',
        'col_status': 'තත්ත්වය',
        'col_actions': 'ක්‍රියාමාර්ග',
        'manage_team': 'කණ්ඩායම කළමනාකරණය',
        'error': 'දෝෂයකි',
        'success': 'සාර්ථකයි',
        'lang_switch': 'தமிழ் බසට මාරු වන්න'
    },
    'ta': {
        'title': 'பணியாளர் மேலாண்மை அமைப்பு',
        'subtitle': 'பெரிய வேலைகளுக்கான டெஸ்க்டாப் போர்டல்',
        'nic_hint': 'NIC எண்ணை உள்ளிடவும்',
        'pin_hint': 'PIN எண்ணை உள்ளிடவும்',
        'login_btn': 'டாஷ்போர்டிற்கு உள்நுழையவும்',
        'brand': 'அமைப்பு போர்டல்',
        'nav_dash': 'டாஷ்போர்டு',
        'nav_jobs': 'செயலில் உள்ள வேலைகள்',
        'nav_team': 'குழு மேலாண்மை',
        'nav_settings': 'அமைப்புகள்',
        'logout': 'வெளியேறு',
        'main_title': 'வேலை கட்டளை மையம்',
        'refresh': 'தரவைப் புதுப்பிக்கவும்',
        'col_title': 'வேலை தலைப்பு',
        'col_area': 'பகுதி',
        'col_workers': 'பணியாளர்கள்',
        'col_status': 'நிலை',
        'col_actions': 'நடவடிக்கைகள்',
        'manage_team': 'குழுவை நிர்வகிக்கவும்',
        'error': 'பிழை',
        'success': 'வெற்றி',
        'lang_switch': 'සිංහල බසට මාරු වන්න'
    }
}

class LoginWindow(QWidget):
    def __init__(self, api_client, on_login_success, lang_provider):
        super().__init__()
        self.api_client = api_client
        self.on_login_success = on_login_success
        self.lp = lang_provider
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()
        layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        self.card = QFrame()
        self.card.setFixedWidth(450)
        self.card.setStyleSheet("background-color: #2b2b2b; border-radius: 15px; padding: 30px;")
        card_layout = QVBoxLayout(self.card)

        self.title_label = QLabel(self.lp.t('title'))
        self.title_label.setFont(QFont("Segoe UI", 18, QFont.Weight.Bold))
        self.title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        card_layout.addWidget(self.title_label)
        
        self.subtitle_label = QLabel(self.lp.t('subtitle'))
        self.subtitle_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.subtitle_label.setStyleSheet("color: #888888; margin-bottom: 20px;")
        card_layout.addWidget(self.subtitle_label)

        self.nic_input = QLineEdit()
        self.nic_input.setPlaceholderText(self.lp.t('nic_hint'))
        self.nic_input.setFixedHeight(45)
        card_layout.addWidget(self.nic_input)

        self.pin_input = QLineEdit()
        self.pin_input.setPlaceholderText(self.lp.t('pin_hint'))
        self.pin_input.setEchoMode(QLineEdit.EchoMode.Password)
        self.pin_input.setFixedHeight(45)
        card_layout.addWidget(self.pin_input)

        self.login_btn = QPushButton(self.lp.t('login_btn'))
        self.login_btn.setFixedHeight(50)
        self.login_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self.login_btn.clicked.connect(self.handle_login)
        card_layout.addWidget(self.login_btn)

        self.lang_btn = QPushButton(self.lp.t('lang_switch'))
        self.lang_btn.setStyleSheet("color: #2196F3; border: none; margin-top: 10px;")
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
        
        # FIX: Handle list messages from API
        if isinstance(message, list):
            message = "\n".join([str(m) for m in message])
        else:
            message = str(message)

        if success:
            self.on_login_success()
        else:
            QMessageBox.critical(self, self.lp.t('error'), message)

class DashboardWindow(QWidget):
    def __init__(self, api_client, lang_provider):
        super().__init__()
        self.api_client = api_client
        self.lp = lang_provider
        self.init_ui()

    def init_ui(self):
        self.layout = QHBoxLayout()
        self.layout.setContentsMargins(0, 0, 0, 0)
        self.layout.setSpacing(0)

        # Sidebar
        sidebar = QFrame()
        sidebar.setFixedWidth(280)
        sidebar.setStyleSheet("background-color: #1e1e1e; border-right: 1px solid #333;")
        sidebar_layout = QVBoxLayout(sidebar)
        
        self.brand_label = QLabel(self.lp.t('brand'))
        self.brand_label.setFont(QFont("Segoe UI", 14, QFont.Weight.Bold))
        self.brand_label.setStyleSheet("padding: 20px; color: #2196F3;")
        sidebar_layout.addWidget(self.brand_label)

        self.nav_btns = []
        nav_keys = [('nav_dash', 'Dashboard'), ('nav_jobs', 'Jobs'), ('nav_team', 'Team'), ('nav_settings', 'Settings')]
        for key, default in nav_keys:
            btn = QPushButton(self.lp.t(key))
            btn.setFixedHeight(50)
            btn.setProperty("key", key)
            btn.setCursor(Qt.CursorShape.PointingHandCursor)
            btn.setStyleSheet("text-align: left; padding-left: 20px; border: none; font-size: 14px;")
            sidebar_layout.addWidget(btn)
            self.nav_btns.append(btn)
        
        sidebar_layout.addStretch()
        
        self.logout_btn = QPushButton(self.lp.t('logout'))
        self.logout_btn.setStyleSheet("color: #f44336; border: none; padding: 20px;")
        self.logout_btn.clicked.connect(lambda: QApplication.quit())
        sidebar_layout.addWidget(self.logout_btn)

        # Main Content
        main_area = QVBoxLayout()
        main_area.setContentsMargins(30, 30, 30, 30)
        
        header = QHBoxLayout()
        self.main_title = QLabel(self.lp.t('main_title'))
        self.main_title.setFont(QFont("Segoe UI", 20, QFont.Weight.Bold))
        header.addWidget(self.main_title)
        header.addStretch()
        
        self.refresh_btn = QPushButton(self.lp.t('refresh'))
        self.refresh_btn.setFixedWidth(200)
        self.refresh_btn.clicked.connect(self.load_jobs)
        header.addWidget(self.refresh_btn)
        main_area.addLayout(header)

        # Job Table
        self.job_table = QTableWidget()
        self.job_table.setColumnCount(5)
        self.update_table_headers()
        self.job_table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.job_table.setStyleSheet("background-color: #2b2b2b; gridline-color: #333;")
        main_area.addWidget(self.job_table)

        self.layout.addWidget(sidebar)
        self.layout.addLayout(main_area)
        self.setLayout(self.layout)

    def update_table_headers(self):
        self.job_table.setHorizontalHeaderLabels([
            self.lp.t('col_title'), self.lp.t('col_area'), 
            self.lp.t('col_workers'), self.lp.t('col_status'), 
            self.lp.t('col_actions')
        ])

    def update_ui(self):
        self.brand_label.setText(self.lp.t('brand'))
        for btn in self.nav_btns:
            btn.setText(self.lp.t(btn.property("key")))
        self.logout_btn.setText(self.lp.t('logout'))
        self.main_title.setText(self.lp.t('main_title'))
        self.refresh_btn.setText(self.lp.t('refresh'))
        self.update_table_headers()
        self.load_jobs()

    def load_jobs(self):
        jobs = self.api_client.get_my_posted_jobs()
        self.job_table.setRowCount(len(jobs))
        for i, job in enumerate(jobs):
            self.job_table.setItem(i, 0, QTableWidgetItem(job['title']))
            self.job_table.setItem(i, 1, QTableWidgetItem(job['area']))
            self.job_table.setItem(i, 2, QTableWidgetItem(str(len(job.get('applied_worker_ids', [])))))
            self.job_table.setItem(i, 3, QTableWidgetItem(job['status'].upper()))
            
            manage_btn = QPushButton(self.lp.t('manage_team'))
            manage_btn.clicked.connect(lambda _, j=job: self.manage_team(j))
            self.job_table.setCellWidget(i, 4, manage_btn)

    def manage_team(self, job):
        QMessageBox.information(self, self.lp.t('nav_team'), f"{self.lp.t('manage_team')}: {job['title']}")

class LanguageProvider:
    def __init__(self):
        self.current = 'si'
    
    def toggle(self):
        self.current = 'ta' if self.current == 'si' else 'si'
    
    def t(self, key):
        return STRINGS[self.current].get(key, key)

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("EMS Desktop Portal")
        self.resize(1100, 750)
        
        self.lp = LanguageProvider()
        self.api_client = ApiClient("https://informal-worker.onrender.com") 
        
        self.stack = QStackedWidget()
        self.setCentralWidget(self.stack)

        self.login_window = LoginWindow(self.api_client, self.show_dashboard, self.lp)
        self.dashboard_window = DashboardWindow(self.api_client, self.lp)

        self.stack.addWidget(self.login_window)
        self.stack.addWidget(self.dashboard_window)

    def show_dashboard(self):
        self.dashboard_window.update_ui()
        self.stack.setCurrentIndex(1)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    apply_stylesheet(app, theme='dark_blue.xml')
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
