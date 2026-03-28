import firebase_admin
from firebase_admin import credentials, firestore

key_path = r"C:\Users\KAMALESH\.gemini\antigravity\scratch\gocampus01-e0437-firebase-adminsdk-fbsvc-135401e9a7.json"
try:
    if not firebase_admin._apps:
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
    db = firestore.client()

    print("--- Setting up Hackathon Environment ---")

    # 1. Create Route & Stops
    route_id = "ROUTE-01"
    db.collection('Routes').document(route_id).set({
        'name': 'Sholingur To RIT Campus',
        'startPoint': 'Sholingur',
        'endPoint': 'RIT Campus',
        'totalDistance': 75.0,
        'stop_ids': ['STOP-01', 'STOP-02']
    })
    
    # Create Default Stops
    db.collection('Stops').document('STOP-01').set({
        'route_id': route_id,
        'stop_name': 'Sholingur Bus Stand',
        'latitude': 13.1118,
        'longitude': 79.4264,
        'orderNumber': '1'
    })
    db.collection('Stops').document('STOP-02').set({
        'route_id': route_id,
        'stop_name': 'Tiruvallur Halt',
        'latitude': 13.0880,
        'longitude': 79.9120,
        'orderNumber': '2'
    })
    print("Created Sholingur -> RIT route and stops.")

    # 2. Create the Bus (Starting at Sholingur)
    bus_id = "BUS-01"
    db.collection('Buses').document(bus_id).set({
        'driver_id': '9876543210',
        'bus_number': 'TN-RIT-001',
        'latitude': 13.1118,
        'longitude': 79.4264,
        'speed': 0.0,
        'status': 'active',
        'capacity': 40,
        'occupancy': 0,
        'current_route_id': route_id,
        'last_updated': firestore.SERVER_TIMESTAMP
    })
    print("Created BUS-01 at Sholingur.")

    # 3. Create the Driver
    db.collection('Users').document('9876543210').set({
        'name': 'John (Demo Driver)',
        'email': '9876543210@driver.gocampus.com',
        'role': 'driver',
        'assigned_bus_id': bus_id,
        'phone': '9876543210',
        # Hashed 'Driver@123' (simplified setup for Firebase Auth matching)
    })
    print("Created Driver profile.")

    # 4. Create 40 Students
    batch = db.batch()
    for i in range(1, 41):
        padded = str(i).zfill(2)
        phone = f"99900010{padded}"
        doc_ref = db.collection('Users').document(phone)
        batch.set(doc_ref, {
            'name': f'Demo Student {padded}',
            'email': f'{phone}@student.gocampus.com',
            'role': 'student',
            'assigned_bus_id': bus_id,
            'assigned_stop': f'Stop {(i % 8) + 1}',
            'phone': phone
        })
    batch.commit()
    print("Injected exactly 40 students assigned to BUS-01.")

    print("Hackathon Database Environment Initialized Successfully!")

except Exception as e:
    print(f"Error: {e}")
