QSS_STYLESHEET = """
QMainWindow {
    background-color: #f0f4f8;
}
QWidget {
    background-color: #f0f4f8;
    color: #2d3748;
    font-family: 'Segoe UI', Arial, sans-serif;
    font-size: 13px;
}
QTabWidget::pane {
    border: 1px solid #cbd5e0;
    background: #ffffff;
    border-radius: 6px;
}
QTabBar::tab {
    background: #e2e8f0;
    border: 1px solid #cbd5e0;
    padding: 10px 20px;
    margin-right: 4px;
    border-top-left-radius: 6px;
    border-top-right-radius: 6px;
    color: #718096;
    font-weight: bold;
}
QTabBar::tab:selected {
    background: #ffffff;
    border-bottom-color: #3182ce;
    color: #3182ce;
}
QTabBar::tab:hover:not(:selected) {
    background: #edf2f7;
    color: #4a5568;
}
QPushButton {
    background-color: #3182ce;
    color: #ffffff;
    border: none;
    padding: 8px 18px;
    border-radius: 6px;
    font-weight: bold;
}
QPushButton:hover {
    background-color: #4299e1;
}
QPushButton:pressed {
    background-color: #2b6cb0;
}
QPushButton:disabled {
    background-color: #cbd5e0;
    color: #a0aec0;
}
QLineEdit, QTextEdit, QComboBox, QDoubleSpinBox, QSpinBox, QDateTimeEdit {
    background-color: #ffffff;
    border: 1px solid #cbd5e0;
    padding: 8px;
    border-radius: 6px;
    color: #2d3748;
}
QLineEdit:focus, QTextEdit:focus, QComboBox:focus, QDoubleSpinBox:focus, QSpinBox:focus {
    border: 1px solid #3182ce;
}
QTableWidget {
    background-color: #ffffff;
    gridline-color: #edf2f7;
    border: 1px solid #cbd5e0;
    border-radius: 6px;
    alternate-background-color: #f7fafc;
}
QHeaderView::section {
    background-color: #ebf8ff;
    color: #2b6cb0;
    padding: 8px;
    border: 1px solid #cbd5e0;
    font-weight: bold;
}
QTableWidget::item {
    padding: 8px;
}
QListWidget {
    background-color: #ffffff;
    border: 1px solid #cbd5e0;
    border-radius: 6px;
    padding: 4px;
}
QListWidget::item {
    padding: 8px;
    border-bottom: 1px solid #edf2f7;
}
QListWidget::item:selected {
    background-color: #3182ce;
    color: white;
    border-radius: 4px;
}
QListWidget::item:hover:not(:selected) {
    background-color: #edf2f7;
}
QLabel {
    color: #4a5568;
}
QGroupBox {
    border: 1px solid #cbd5e0;
    border-radius: 6px;
    margin-top: 12px;
    font-weight: bold;
    color: #2b6cb0;
}
QStackedWidget {
    background-color: #f0f4f8;
}

QWidget#AuthCard {
    background-color: #ffffff;
    border: 1px solid #bee3f8;
    border-radius: 12px;
}
QPushButton#DangerButton {
    background-color: #e53e3e;
    color: white;
}
QPushButton#DangerButton:hover {
    background-color: #f56565;
}
QPushButton#LinkButton {
    background-color: transparent;
    color: #3182ce;
    font-weight: normal;
    text-decoration: underline;
}
QPushButton#LinkButton:hover {
    color: #4299e1;
}
"""
