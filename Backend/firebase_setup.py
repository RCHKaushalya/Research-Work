import os
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# Anchor service account path to the Backend directory
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SERVICE_ACCOUNT_PATH = os.path.join(BASE_DIR, "firebase_service_account.json")

# Initialize Firebase Admin
if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)

# Get Firestore database instance
db = firestore.client()
