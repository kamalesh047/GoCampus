key_path = r"C:\Users\KAMALESH\.gemini\antigravity\scratch\gocampus01-e0437-firebase-adminsdk-fbsvc-135401e9a7.json"
with open(key_path, 'r') as f:
    content = f.read()

import json
try:
    json.loads(content)
except json.JSONDecodeError as e:
    print(f"Error: {e}")
    # Print 20 chars before and after the failure
    start = max(0, e.pos - 20)
    end = min(len(content), e.pos + 20)
    print(f"Context: ... {content[start:end]} ...")
    print(f"At pos {e.pos}: char code {ord(content[e.pos])}")
