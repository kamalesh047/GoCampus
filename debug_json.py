import json
key_path = r"C:\Users\KAMALESH\.gemini\antigravity\scratch\gocampus01-e0437-firebase-adminsdk-fbsvc-135401e9a7.json"
data = json.load(open(key_path))
print("Key Start:", data['private_key'][:50])
print("Key contains literal backslash followed by n:", "\\n" in data['private_key'])
print("Key contains actual newline character:", "\n" in data['private_key'])
