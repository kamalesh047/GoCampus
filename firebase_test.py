import firebase_admin
from firebase_admin import credentials, firestore, auth
import os
import json

# Path to the service account key
key_path = r"C:\Users\KAMALESH\.gemini\antigravity\scratch\gocampus01-e0437-firebase-adminsdk-fbsvc-135401e9a7.json"

def test_connection():
    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(key_path)
            firebase_admin.initialize_app(cred)
        
        db = firestore.client()
        print("Successfully connected to Firestore.")
        
        # Get users count
        users_count = len(list(db.collection('users').stream()))
        print(f"Current total students/users in database: {users_count}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_connection()
