import os

path = r'c:\Users\KAMALESH\.gemini\antigravity\scratch\go_campus\lib'
for root, dirs, files in os.walk(path):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            content = content.replace("collection('buses')", "collection('Buses')")
            content = content.replace("collection('users')", "collection('Users')")
            content = content.replace("collection('trips')", "collection('TripHistory')")
            content = content.replace("collection('routes')", "collection('Routes')")
            content = content.replace("collection('stops')", "collection('Stops')")
            content = content.replace("collection('attendance')", "collection('Attendance')")
            content = content.replace("collection('system')", "collection('System')")
            content = content.replace("collection('complaints')", "collection('Complaints')")
            content = content.replace("collection('sos_alerts')", "collection('Notifications')")
            content = content.replace("collection('notifications')", "collection('Notifications')")
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
