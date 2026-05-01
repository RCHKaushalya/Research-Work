from PyQt6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QLabel, 
                             QPushButton, QScrollArea, QGridLayout, QFrame, 
                             QTabWidget, QListWidget, QTextEdit, QComboBox, QMessageBox, QLineEdit, QTableWidget, QTableWidgetItem, QHeaderView)
from PyQt6.QtCore import Qt, pyqtSignal
from PyQt6.QtGui import QFont, QPixmap

class WorkerCard(QFrame):
    clicked = pyqtSignal(dict)

    def __init__(self, worker, lp):
        super().__init__()
        self.worker = worker
        self.lp = lp
        self.init_ui()

    def init_ui(self):
        self.setFixedSize(200, 240)
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setObjectName("workerCard")
        self.setStyleSheet("""
            #workerCard { background-color: white; border: 1px solid #eee; border-radius: 15px; }
            #workerCard:hover { border: 1px solid #2196F3; background-color: #f9f9f9; }
        """)
        layout = QVBoxLayout(self)
        layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        img_label = QLabel("👤")
        img_label.setFixedSize(80, 80)
        img_label.setStyleSheet("background-color: #eee; border-radius: 40px; font-size: 30px;")
        img_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(img_label)
        name_label = QLabel(f"{self.worker['first_name']} {self.worker['last_name']}")
        name_label.setFont(QFont("Segoe UI", 12, QFont.Weight.Bold))
        name_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(name_label)
        rating_label = QLabel(f"⭐ {self.worker['rating']}")
        rating_label.setStyleSheet("color: #FF9800; font-weight: bold;")
        rating_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(rating_label)
        layout.addStretch()
        id_label = QLabel(self.worker['nic'])
        id_label.setStyleSheet("color: #888; font-size: 10px;")
        id_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(id_label)

    def mousePressEvent(self, event):
        self.clicked.emit(self.worker)

class JobDetailsView(QWidget):
    def __init__(self, api_client, lp, on_back, on_view_profile):
        super().__init__()
        self.api_client = api_client
        self.lp = lp
        self.on_back = on_back
        self.on_view_profile = on_view_profile
        self.job = None
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()
        layout.setContentsMargins(40, 40, 40, 40)
        layout.setSpacing(25)

        # Header
        header = QHBoxLayout()
        back_btn = QPushButton(f"← {self.lp.t('back')}")
        back_btn.setFixedSize(120, 45)
        back_btn.setStyleSheet("background: #f5f5f5; border-radius: 8px;")
        back_btn.clicked.connect(self.on_back)
        header.addWidget(back_btn)
        
        self.title_label = QLabel("")
        self.title_label.setFont(QFont("Segoe UI", 22, QFont.Weight.Bold))
        header.addWidget(self.title_label)
        
        header.addStretch()
        self.status_box = QComboBox()
        self.status_box.addItems(["OPEN", "ASSIGNED", "COMPLETED", "CANCELLED"])
        self.status_box.setFixedHeight(45)
        header.addWidget(self.status_box)
        layout.addLayout(header)

        # Job Overview Section
        overview_card = QFrame()
        overview_card.setStyleSheet("background: white; border: 1px solid #eee; border-radius: 12px; padding: 20px;")
        ov_layout = QVBoxLayout(overview_card)
        
        self.desc_label = QLabel("")
        self.desc_label.setWordWrap(True)
        self.desc_label.setStyleSheet("color: #555;")
        ov_layout.addWidget(QLabel(self.lp.t('description'), font=QFont("Segoe UI", 12, QFont.Weight.Bold)))
        ov_layout.addWidget(self.desc_label)
        
        self.skills_req_label = QLabel("")
        self.skills_req_label.setStyleSheet("color: #1976D2; font-weight: bold;")
        ov_layout.addWidget(QLabel(self.lp.t('skills_req'), font=QFont("Segoe UI", 12, QFont.Weight.Bold)))
        ov_layout.addWidget(self.skills_req_label)
        layout.addWidget(overview_card)

        # Tabs
        self.tabs = QTabWidget()
        self.tabs.setStyleSheet("QTabBar::tab { padding: 15px 30px; font-weight: bold; }")
        
        # 1. Applicants Tab
        self.team_tab = QWidget()
        team_layout = QVBoxLayout(self.team_tab)
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet("border: none;")
        self.worker_container = QWidget()
        self.worker_grid = QGridLayout(self.worker_container)
        self.worker_grid.setAlignment(Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignLeft)
        scroll.setWidget(self.worker_container)
        team_layout.addWidget(scroll)
        self.tabs.addTab(self.team_tab, self.lp.t('applicants'))

        # 2. Groups Tab
        self.group_tab = QWidget()
        group_layout = QVBoxLayout(self.group_tab)
        header_gp = QHBoxLayout()
        header_gp.addWidget(QLabel(self.lp.t('group'), font=QFont("Segoe UI", 14, QFont.Weight.Bold)))
        btn_gp = QPushButton(self.lp.t('create_group'))
        btn_gp.setStyleSheet("background: #2196F3; color: white; padding: 8px 15px; border-radius: 6px;")
        header_gp.addWidget(btn_gp)
        group_layout.addLayout(header_gp)
        group_layout.addWidget(QLabel("Manage sub-teams for this job (e.g., Night Shift, Cleaning Team)."))
        group_layout.addStretch()
        self.tabs.addTab(self.group_tab, self.lp.t('group'))

        # 3. Salary Tab
        self.salary_tab = QWidget()
        salary_layout = QVBoxLayout(self.salary_tab)
        self.salary_table = QTableWidget()
        self.salary_table.setColumnCount(4)
        self.salary_table.setHorizontalHeaderLabels([
            self.lp.t('worker_name'), self.lp.t('total_salary'), 
            self.lp.t('paid'), self.lp.t('pending')
        ])
        self.salary_table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        salary_layout.addWidget(self.salary_table)
        self.tabs.addTab(self.salary_tab, self.lp.t('salary'))

        layout.addWidget(self.tabs)
        self.setLayout(layout)

    def set_job(self, job):
        self.job = job
        self.title_label.setText(job['title'])
        self.desc_label.setText("මෙම රැකියාව සඳහා විශාල සේවක පිරිසක් අවශ්‍ය වේ. නියමිත වේලාවට වැඩ අවසන් කිරීම අත්‍යවශ්‍යයි.")
        self.skills_req_label.setText("ප්‍රදර්ශන, වඩු වැඩ, සාමාන්‍ය සේවා")
        self.status_box.setCurrentText(job['status'].upper())
        self.load_applicants()
        self.load_salaries()

    def load_applicants(self):
        for i in reversed(range(self.worker_grid.count())): 
            self.worker_grid.itemAt(i).widget().setParent(None)
        from main import USE_MOCK_DATA
        applicants = self.api_client.get_job_applicants(self.job['id'])
        for index, worker in enumerate(applicants):
            card = WorkerCard(worker, self.lp)
            card.clicked.connect(self.on_view_profile)
            self.worker_grid.addWidget(card, index // 4, index % 4)

    def load_salaries(self):
        from main import USE_MOCK_DATA
        applicants = self.api_client.get_job_applicants(self.job['id'])
        self.salary_table.setRowCount(len(applicants))
        for i, app in enumerate(applicants):
            self.salary_table.setItem(i, 0, QTableWidgetItem(f"{app['first_name']} {app['last_name']}"))
            self.salary_table.setItem(i, 1, QTableWidgetItem("Rs. 50,000"))
            self.salary_table.setItem(i, 2, QTableWidgetItem("Rs. 20,000"))
            self.salary_table.setItem(i, 3, QTableWidgetItem("Rs. 30,000"))

    def update_ui(self):
        # Update strings if language changed
        pass
