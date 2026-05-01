from PyQt6.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QLabel, QPushButton, QScrollArea, QGridLayout, QFrame
from PyQt6.QtCore import Qt, pyqtSignal
from PyQt6.QtGui import QFont, QColor

class JobCard(QFrame):
    clicked = pyqtSignal(dict)

    def __init__(self, job, lp):
        super().__init__()
        self.job = job
        self.lp = lp
        self.init_ui()

    def init_ui(self):
        self.setFixedSize(280, 180)
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setObjectName("jobCard")
        self.setStyleSheet("""
            #jobCard {
                background-color: white;
                border: 1px solid #ddd;
                border-radius: 12px;
            }
            #jobCard:hover {
                border: 2px solid #2196F3;
                background-color: #f0f7ff;
            }
        """)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)

        area_label = QLabel(self.job['area'].upper())
        area_label.setStyleSheet("color: #2196F3; font-weight: bold; font-size: 11px;")
        layout.addWidget(area_label)

        title_label = QLabel(self.job['title'])
        title_label.setFont(QFont("Segoe UI", 14, QFont.Weight.Bold))
        title_label.setWordWrap(True)
        title_label.setStyleSheet("color: #333;")
        layout.addWidget(title_label)
        
        layout.addStretch()
        
        status_label = QLabel(self.job['status'].upper())
        status_label.setStyleSheet("color: #888; font-size: 10px;")
        layout.addWidget(status_label)

    def mousePressEvent(self, event):
        self.clicked.emit(self.job)

class DashboardView(QWidget):
    def __init__(self, api_client, lp, on_manage_job, on_post_job):
        super().__init__()
        self.api_client = api_client
        self.lp = lp
        self.on_manage_job = on_manage_job
        self.on_post_job = on_post_job
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()
        layout.setContentsMargins(40, 40, 40, 40)
        layout.setSpacing(30)

        # Header
        header = QHBoxLayout()
        self.main_title = QLabel(self.lp.t('main_title'))
        self.main_title.setFont(QFont("Segoe UI", 26, QFont.Weight.Bold))
        header.addWidget(self.main_title)
        
        header.addStretch()
        
        self.post_btn = QPushButton(f"+ {self.lp.t('post_job')}")
        self.post_btn.setFixedHeight(50)
        self.post_btn.setFixedWidth(260)
        self.post_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self.post_btn.setStyleSheet("""
            QPushButton { background-color: #4CAF50; color: white; border-radius: 10px; font-weight: bold; font-size: 14px; }
            QPushButton:hover { background-color: #45a049; }
        """)
        self.post_btn.clicked.connect(self.on_post_job)
        header.addWidget(self.post_btn)

        self.logout_btn = QPushButton(self.lp.t('logout'))
        self.logout_btn.setFixedHeight(50)
        self.logout_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self.logout_btn.setStyleSheet("""
            QPushButton { background-color: #fff; color: #f44336; border: 1px solid #f44336; border-radius: 10px; padding: 0 20px; }
            QPushButton:hover { background-color: #fff1f0; }
        """)
        self.logout_btn.clicked.connect(lambda: QApplication.quit())
        header.addWidget(self.logout_btn)
        
        layout.addLayout(header)

        # Scroll Area for Tiles
        self.scroll = QScrollArea()
        self.scroll.setWidgetResizable(True)
        self.scroll.setStyleSheet("border: none; background-color: transparent;")
        
        self.container = QWidget()
        self.grid = QGridLayout(self.container)
        self.grid.setSpacing(25)
        self.grid.setAlignment(Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignLeft)
        
        self.scroll.setWidget(self.container)
        layout.addWidget(self.scroll)

        self.setLayout(layout)

    def update_ui(self):
        self.main_title.setText(self.lp.t('main_title'))
        self.post_btn.setText(f"+ {self.lp.t('post_job')}")
        self.logout_btn.setText(self.lp.t('logout'))
        self.load_jobs()

    def load_jobs(self):
        # Clear current grid
        for i in reversed(range(self.grid.count())): 
            self.grid.itemAt(i).widget().setParent(None)
            
        jobs = self.api_client.get_my_posted_jobs()
        for index, job in enumerate(jobs):
            card = JobCard(job, self.lp)
            card.clicked.connect(self.on_manage_job)
            self.grid.addWidget(card, index // 3, index % 3)
