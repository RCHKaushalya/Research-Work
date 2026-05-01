from PyQt6.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QLabel, QPushButton, QFrame, QScrollArea, QTableWidget, QTableWidgetItem, QHeaderView
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QFont

class WorkerProfileView(QWidget):
    def __init__(self, api_client, lp, on_back):
        super().__init__()
        self.api_client = api_client
        self.lp = lp
        self.on_back = on_back
        self.worker = None
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()
        layout.setContentsMargins(50, 50, 50, 50)
        layout.setSpacing(30)

        # Header
        header = QHBoxLayout()
        back_btn = QPushButton(f"← {self.lp.t('back')}")
        back_btn.setFixedSize(120, 45)
        back_btn.setStyleSheet("background: #f5f5f5; border-radius: 8px;")
        back_btn.clicked.connect(self.on_back)
        header.addWidget(back_btn)
        
        self.profile_title = QLabel(self.lp.t('public_profile'))
        self.profile_title.setFont(QFont("Segoe UI", 24, QFont.Weight.Bold))
        header.addWidget(self.profile_title)
        header.addStretch()
        layout.addLayout(header)

        # Main Content
        content = QHBoxLayout()
        
        # Left Side: Photo & Quick Stats
        left_side = QVBoxLayout()
        photo = QLabel("👤")
        photo.setFixedSize(150, 150)
        photo.setStyleSheet("background: #eee; border-radius: 75px; font-size: 50px;")
        photo.setAlignment(Qt.AlignmentFlag.AlignCenter)
        left_side.addWidget(photo)
        
        self.name_label = QLabel("")
        self.name_label.setFont(QFont("Segoe UI", 18, QFont.Weight.Bold))
        self.name_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        left_side.addWidget(self.name_label)
        
        self.rating_label = QLabel("")
        self.rating_label.setStyleSheet("color: #FF9800; font-weight: bold; font-size: 16px;")
        self.rating_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        left_side.addWidget(self.rating_label)
        
        left_side.addStretch()
        content.addLayout(left_side, 1)

        # Right Side: Bio & Skills
        right_side = QVBoxLayout()
        
        right_side.addWidget(QLabel(self.lp.t('bio'), font=QFont("Segoe UI", 14, QFont.Weight.Bold)))
        self.bio_text = QLabel("Worker bio will appear here...")
        self.bio_text.setWordWrap(True)
        self.bio_text.setStyleSheet("color: #555; background: #fff; padding: 15px; border-radius: 10px; border: 1px solid #eee;")
        right_side.addWidget(self.bio_text)
        
        right_side.addWidget(QLabel(self.lp.t('skills_req'), font=QFont("Segoe UI", 14, QFont.Weight.Bold)))
        self.skills_label = QLabel("Skill 1, Skill 2, Skill 3")
        self.skills_label.setStyleSheet("background: #E3F2FD; color: #1976D2; padding: 10px; border-radius: 8px; font-weight: bold;")
        right_side.addWidget(self.skills_label)
        
        # Reviews Table
        right_side.addWidget(QLabel(self.lp.t('review'), font=QFont("Segoe UI", 14, QFont.Weight.Bold)))
        self.review_table = QTableWidget()
        self.review_table.setColumnCount(3)
        self.review_table.setHorizontalHeaderLabels(["Employer", "Rating", "Comment"])
        self.review_table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        right_side.addWidget(self.review_table)
        
        content.addLayout(right_side, 2)
        
        layout.addLayout(content)
        self.setLayout(layout)

    def set_worker(self, worker):
        self.worker = worker
        self.name_label.setText(f"{worker['first_name']} {worker['last_name']}")
        self.rating_label.setText(f"⭐ {worker['rating']}")
        self.bio_text.setText("පළපුරුදු සේවකයෙකි. ඕනෑම දුෂ්කර කාර්යයක් සාර්ථකව නිම කළ හැකිය.") # Localized dummy bio
        self.skills_label.setText("පින්තාරු කිරීම, බිත්ති බැඳීම, විදුලි කාර්මික") # Localized dummy skills
