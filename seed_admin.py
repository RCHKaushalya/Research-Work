import sqlite3
from database import init_db, DB_PATH

def seed_admin():
    init_db()
    connection = sqlite3.connect(DB_PATH)
    cursor = connection.cursor()
    
    # Check if admin already exists
    cursor.execute("SELECT nic FROM users WHERE role = 'admin'")
    if cursor.fetchone():
        print("Admin already exists.")
    else:
        cursor.execute(
            """
            INSERT INTO users(nic, first_name, last_name, phone, language, district, ds_area, pin, role)
            VALUES ('123456789V', 'System', 'Admin', '0771234567', 'English', 'Colombo', 'Colombo', '1234', 'admin')
            """
        )
        connection.commit()
        print("Admin user created: NIC: 123456789V, PIN: 1234")
    
    connection.close()

if __name__ == "__main__":
    seed_admin()
