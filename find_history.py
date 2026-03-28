import os
import json

history_dir = r"C:\Users\KAMALESH\AppData\Roaming\Code\User\History"
found_files = {}

for folder in os.listdir(history_dir):
    folder_path = os.path.join(history_dir, folder)
    if not os.path.isdir(folder_path):
        continue
    
    entries_file = os.path.join(folder_path, "entries.json")
    if os.path.exists(entries_file):
        try:
            with open(entries_file, "r", encoding="utf-8") as f:
                data = json.load(f)
                resource = data.get("resource", "")
                if "go_campus" in resource and resource.endswith(".dart"):
                    found_files[resource] = folder_path
        except Exception as e:
            pass

for res, path in found_files.items():
    print(f"{res} -> {path}")
