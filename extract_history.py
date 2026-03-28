import os
import json
import shutil
import urllib.parse

history_dir = r"C:\Users\KAMALESH\AppData\Roaming\Code\User\History"
project_lib = r"c:\Users\KAMALESH\.gemini\antigravity\scratch\go_campus\lib"

# To store the biggest legitimate file version for each file
recovered = {}

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
                
                # Check if it belongs to go_campus lib
                if "go_campus" in resource and "/lib/" in resource and resource.endswith(".dart"):
                    # Parse the actual relative path
                    parsed_path = urllib.parse.unquote(resource).replace("file:///", "")
                    parsed_path = parsed_path.replace("/", "\\")
                    
                    if "go_campus\\lib\\" in parsed_path:
                        rel_path = parsed_path.split("go_campus\\lib\\")[1]
                        dest_path = os.path.join(project_lib, rel_path)
                        
                        entries = data.get("entries", [])
                        
                        # Find the largest file among entries that is valid
                        best_entry_file = None
                        max_size = 0
                        
                        for entry in entries:
                            entry_id = entry.get("id")
                            entry_file_path = os.path.join(folder_path, entry_id)
                            if os.path.exists(entry_file_path):
                                size = os.path.getsize(entry_file_path)
                                if size > max_size and size > 100: # Ignoring empty or corrupted
                                    max_size = size
                                    best_entry_file = entry_file_path
                        
                        if best_entry_file:
                            recovered[dest_path] = best_entry_file
        except Exception as e:
            pass

for dest, src in recovered.items():
    print(f"Restoring {dest}")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copy2(src, dest)

print(f"Restored {len(recovered)} files from VS Code history.")
