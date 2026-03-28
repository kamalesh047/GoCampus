import firebase_admin
from firebase_admin import credentials, firestore, auth

key_path = r"C:\Users\KAMALESH\.gemini\antigravity\scratch\gocampus01-e0437-firebase-adminsdk-fbsvc-135401e9a7.json"
try:
    if not firebase_admin._apps:
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
    db = firestore.client()

    print("--- 🧹 Clearing Existing Database & Auth ---")
    
    try:
        page = auth.list_users()
        while page:
            uids = [user.uid for user in page.users]
            if uids:
                auth.delete_users(uids)
                print(f"Deleted {len(uids)} users from Auth.")
            page = page.get_next_page()
    except Exception as e:
        print(f"Auth clean error: {e}")

    # Wipe Firestore safely
    collections = ['Users', 'Buses', 'Routes', 'Stops', 'TripHistory', 'Attendance', 'Announcements', 'passenger_locations']
    for coll_name in collections:
        docs = db.collection(coll_name).get()
        if docs:
            batch = db.batch()
            count = 0
            for doc in docs:
                batch.delete(doc.reference)
                count += 1
                if count % 100 == 0:
                    batch.commit()
                    batch = db.batch()
            if count % 100 != 0:
                batch.commit()
            print(f"Deleted {count} documents from {coll_name}.")

    print("\n--- 🚀 Setting up Pilot Environment ---")

    # 1. Route & Stops
    route_id = "ROUTE-01"
    db.collection('Routes').document(route_id).set({
        'name': 'Pilot Demo Route',
        'startPoint': 'City Center',
        'endPoint': 'RIT Campus',
        'totalDistance': 20.0,
        'stop_ids': ['STOP-01', 'STOP-02', 'STOP-03']
    })
    
    stops = [
        {'id': 'STOP-01', 'name': 'City Center', 'lat': 12.9716, 'lng': 77.5946, 'order': '1'},
        {'id': 'STOP-02', 'name': 'Midway Junction', 'lat': 12.9800, 'lng': 77.6000, 'order': '2'},
        {'id': 'STOP-03', 'name': 'College Gate', 'lat': 13.0489, 'lng': 80.0572, 'order': '3'}
    ]
    for stop in stops:
        db.collection('Stops').document(stop['id']).set({
            'route_id': route_id,
            'stop_name': stop['name'],
            'latitude': stop['lat'],
            'longitude': stop['lng'],
            'orderNumber': stop['order']
        })

    # 2. Bus Profile
    bus_id = "BUS-01"
    db.collection('Buses').document(bus_id).set({
        'driver_id': '9876543210',
        'bus_number': 'TN-PILOT-01',
        'latitude': 12.9716,
        'longitude': 77.5946,
        'speed': 0.0,
        'status': 'inactive',
        'capacity': 50,
        'occupancy': 0,
        'current_route_id': route_id,
        'last_updated': firestore.SERVER_TIMESTAMP
    })

    # 3. Staff & Roles
    auth.create_user(email='admin@gocampus.com', password='Admin@123', uid='admin_uid')
    db.collection('Users').document('admin_uid').set({'name': 'System Admin', 'email': 'admin@gocampus.com', 'role': 'admin'})
    
    auth.create_user(email='incharge@gocampus.com', password='Incharge@123', uid='incharge_uid')
    db.collection('Users').document('incharge_uid').set({'name': 'Transport Incharge', 'email': 'incharge@gocampus.com', 'role': 'incharge'})

    driver_phone = '9876543210'
    driver_email = f'{driver_phone}@driver.gocampus.com'
    auth.create_user(email=driver_email, password='Driver@123', uid=driver_phone)
    db.collection('Users').document(driver_phone).set({
        'name': 'Pilot Driver',
        'email': driver_email,
        'role': 'driver',
        'assigned_bus_id': bus_id,
        'phone': driver_phone
    })

    # 4. 50 Students in batch
    batch = db.batch()
    for i in range(1, 51):
        padded = str(i).zfill(2)
        phone = f"99900010{padded}"
        student_email = f"{phone}@student.gocampus.com"
        
        try:
            auth.create_user(email=student_email, password='Student@123', uid=phone)
        except Exception as e:
            pass # ignore if it exists from previous interrupted run
            
        doc_ref = db.collection('Users').document(phone)
        batch.set(doc_ref, {
            'name': f'Pilot Student {padded}',
            'email': student_email,
            'role': 'student',
            'assigned_bus_id': bus_id,
            'assigned_stop': f"STOP-0{(i % 3) + 1}",
            'phone': phone
        })
    batch.commit()

    print("\n✅ Pilot Setup Completed Successfully!")

except Exception as e:
    print(f"Error: {e}")
