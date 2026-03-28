import os
import json
import shutil
import glob

hist_dir = r"C:\Users\KAMALESH\AppData\Roaming\Code\User\History"
target_prefix = "file:///c%3A/Users/KAMALESH/.gemini/antigravity/scratch/go_campus/lib"

restored = 0
found_files = {}

for d in glob.glob(os.path.join(hist_dir, "*")):
    entries_file = os.path.join(d, "entries.json")
    if os.path.isfile(entries_file):
        try:
            with open(entries_file, "r", encoding="utf-8") as f:
                data = json.load(f)
            
            res = data.get("resource", "")
            if res.startswith(target_prefix):
                entries = data.get("entries", [])
                if entries:
                    latest = os.path.join(d, entries[-1]["id"])
                    
                    # Also keep track of all files matching so we get the most recent one overall?
                    # VSCode sometimes creates multiple folders for the same file, we need the latest one based on timestamp.
                    # Mtime of the latest entry file:
                    if os.path.isfile(latest):
                        mtime = os.path.getmtime(latest)
                        if res not in found_files or found_files[res][0] < mtime:
                            found_files[res] = (mtime, latest, res)
        except Exception as e:
            pass

for mtime, latest, res in found_files.values():
    dest = res.replace("file:///c%3A", "c:").replace("/", "\\")
    try:
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copy2(latest, dest)
        restored += 1
        print("Restored:", dest)
    except Exception as e:
        print("Error restoring", dest, e)

print(f"Total restored from VSCode History: {restored}")
