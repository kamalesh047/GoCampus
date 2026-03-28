import firebase_admin
from firebase_admin import credentials, firestore, auth

# ---------------------------------------------------------
# ✏️ CONFIGURATION SECTION - FILL IN YOUR ORIGINAL DATA HERE ✏️
# ---------------------------------------------------------

# 1. ADMIN SETUP
ADMIN_EMAIL = "kamaleshsaravanan2007.n@gmail.com"
ADMIN_PASSWORD = "kamal@2007"
ADMIN_NAME = "College Admin"

# 2. BUS IN-CHARGE SETUP
INCHARGE_EMAIL = "ellammal.saravanan@gmail.com"
INCHARGE_PASSWORD = "kamalesh@2007"
INCHARGE_NAME = "Transport Incharge"

# 3. DRIVER SETUP
DRIVER_PHONE = "9751908511" # Must be exactly a real 10-digit number
DRIVER_PASSWORD = "kamal@2007"
DRIVER_NAME = "ramachandran"
BUS_NUMBER_PLATE = "TN-12-AB-1234" # Change to real Bus Plate

# 4. STUDENTS SETUP
# Add as many original number dictionaries as you want in this list below (up to your 50 students).
# Put their actual numbers and custom passwords here! The stop ID maps them to a Stop marker.
STUDENTS = [
    {"phone": "9751522049", "name": "kamalesh", "password": "9751522049", "stop": "STOP-01"},
    {"phone": "9751908512", "name": "ellammal", "password": "9751908511", "stop": "STOP-02"},
    {"phone": "8123456782", "name": "Original Student 3", "password": "customPassword03", "stop": "STOP-03"},
    # ... KEEP COPY PASTING ABOVE FOR ALL 50 STUDENTS ...
]

# ---------------------------------------------------------
# 🛑 STOP editing below this line 🛑
# ---------------------------------------------------------

key_path = r"C:\Users\KAMALESH\.gemini\antigravity\scratch\gocampus01-e0437-firebase-adminsdk-fbsvc-135401e9a7.json"
try:
    if not firebase_admin._apps:
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
    db = firestore.client()

    print("--- 🚀 Setting up REAL Manual Environment ---")

    # 1. Route & Stops Configuration
    route_id = "ROUTE-01"
    db.collection('Routes').document(route_id).set({
        'name': 'Original Live Route',
        'startPoint': 'Starting City',
        'endPoint': 'College Campus',
        'totalDistance': 20.0,
        'stop_ids': ['STOP-01', 'STOP-02', 'STOP-03']
    })
    
    stops = [
        {'id': 'STOP-01', 'name': 'Stop 1 (Original)', 'lat': 12.9716, 'lng': 77.5946, 'order': '1'},
        {'id': 'STOP-02', 'name': 'Stop 2 (Original)', 'lat': 12.9800, 'lng': 77.6000, 'order': '2'},
        {'id': 'STOP-03', 'name': 'Stop 3 (Original)', 'lat': 13.0489, 'lng': 80.0572, 'order': '3'}
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
        'driver_id': DRIVER_PHONE,
        'bus_number': BUS_NUMBER_PLATE, 
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
    auth.create_user(email=ADMIN_EMAIL, password=ADMIN_PASSWORD, uid='admin_uid')
    db.collection('Users').document('admin_uid').set({'name': ADMIN_NAME, 'email': ADMIN_EMAIL, 'role': 'admin'})
    
    auth.create_user(email=INCHARGE_EMAIL, password=INCHARGE_PASSWORD, uid='incharge_uid')
    db.collection('Users').document('incharge_uid').set({'name': INCHARGE_NAME, 'email': INCHARGE_EMAIL, 'role': 'incharge'})

    driver_email = f'{DRIVER_PHONE}@driver.gocampus.com'
    auth.create_user(email=driver_email, password=DRIVER_PASSWORD, uid=DRIVER_PHONE)
    db.collection('Users').document(DRIVER_PHONE).set({
        'name': DRIVER_NAME,
        'email': driver_email,
        'role': 'driver',
        'assigned_bus_id': bus_id,
        'phone': DRIVER_PHONE
    })
    print(f"Created Real Driver: {DRIVER_PHONE}")

    # 4. Inject Actual Students
    batch = db.batch()
    created_count = 0
    for st in STUDENTS:
        phone = st['phone']
        student_email = f"{phone}@student.gocampus.com"
        
        try:
            auth.create_user(email=student_email, password=st['password'], uid=phone)
        except Exception as e:
            print(f"Note: Error setting up {phone} auth: {e}")
            
        doc_ref = db.collection('Users').document(phone)
        batch.set(doc_ref, {
            'name': st['name'],
            'email': student_email,
            'role': 'student',
            'assigned_bus_id': bus_id,
            'assigned_stop': st.get('stop', 'STOP-01'),
            'phone': phone
        })
        created_count += 1
    batch.commit()

    print(f"\n✅ {created_count} Original Students & Accounts Configured Successfully!")

except Exception as e:
    print(f"Critical System Error: {e}")
