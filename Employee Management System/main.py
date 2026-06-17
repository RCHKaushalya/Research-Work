import sys
from PyQt6.QtWidgets import QApplication, QMainWindow, QStackedWidget
from app.config import SUPABASE_ANON_KEY
from app.theme import QSS_STYLESHEET
from app.ui.login import LoginWidget
from app.ui.register import RegisterWidget
from app.ui.dashboard import EmployeeManagementSystem

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Workforce Platform - Employer System")
        self.setGeometry(100, 100, 1200, 750)

        self.stacked_widget = QStackedWidget()
        self.setCentralWidget(self.stacked_widget)

        self.login_widget = LoginWidget(self)
        self.register_widget = RegisterWidget(self)

        self.stacked_widget.addWidget(self.login_widget)
        self.stacked_widget.addWidget(self.register_widget)

        self.stacked_widget.setCurrentWidget(self.login_widget)

    def switch_to_login(self):
        self.stacked_widget.setCurrentWidget(self.login_widget)

    def switch_to_register(self):
        self.stacked_widget.setCurrentWidget(self.register_widget)

    def login_success(self, user_data):
        name = f"{user_data.get('first_name', '')} {user_data.get('last_name', '')}"
        self.dashboard_widget = EmployeeManagementSystem(self, user_data["nic"], name)
        self.stacked_widget.addWidget(self.dashboard_widget)
        self.stacked_widget.setCurrentWidget(self.dashboard_widget)

    def logout(self):
        self.stacked_widget.setCurrentWidget(self.login_widget)
        if hasattr(self, 'dashboard_widget'):
            self.stacked_widget.removeWidget(self.dashboard_widget)
            self.dashboard_widget.deleteLater()
            del self.dashboard_widget




def main():
    app = QApplication(sys.argv)
    app.setStyleSheet(QSS_STYLESHEET)

    if not SUPABASE_ANON_KEY:
        print("Error: SUPABASE_ANON_KEY environment variable not set")
        print("Please set SUPABASE_ANON_KEY before running this application")
        sys.exit(1)

    window = MainWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
