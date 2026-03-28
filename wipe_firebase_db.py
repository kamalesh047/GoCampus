import firebase_admin
from firebase_admin import credentials, firestore, auth

key_path = r"C:\Users\KAMALESH\.gemini\antigravity\scratch\gocampus01-e0437-firebase-adminsdk-fbsvc-135401e9a7.json"
try:
    if not firebase_admin._apps:
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
    db = firestore.client()

    print("--- 🚨 COMPLETELY WIPING FIREBASE DATABASE & AUTH 🚨 ---")
    
    # 1. Delete all users from Firebase Authentication
    try:
        page = auth.list_users()
        while page:
            uids = [user.uid for user in page.users]
            if uids:
                auth.delete_users(uids)
                print(f"Deleted {len(uids)} users from Authentication.")
            page = page.get_next_page()
        print("✅ All Authentication Users Deleted.")
    except Exception as e:
        print(f"Auth clean error: {e}")

    # 2. Delete all documents from Firestore collections
    collections = ['Users', 'Buses', 'Routes', 'Stops', 'TripHistory', 'Attendance', 'Announcements', 'passenger_locations']
    for coll_name in collections:
        docs = db.collection(coll_name).get()
        if docs:
            batch = db.batch()
            count = 0
            for doc in docs:
                batch.delete(doc.reference)
                count += 1
                # Commit batches of 100
                if count % 100 == 0:
                    batch.commit()
                    batch = db.batch()
            # Commit any remaining docs
            if count % 100 != 0:
                batch.commit()
            print(f"Deleted {count} documents from '{coll_name}' collection.")
        else:
            print(f"Collection '{coll_name}' is already empty.")

    print("\n--- ✅ FIREBASE IS COMPLETELY EMPTY AND READY FOR MANUAL ENTRY ---")

except Exception as e:
    print(f"Critical Error: {e}")
