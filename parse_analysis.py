import json
import os

# Try UTF-16LE first, then fallback to UTF-8
try:
    with open("analysis_output.txt", "r", encoding="utf-16le") as f:
        lines = f.readlines()
except:
    with open("analysis_output.txt", "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

errors_by_file = {}
error_count = 0
warning_count = 0

for line in lines:
    line = line.strip()
    if not line.startswith("{"):
        continue
    try:
        issue = json.loads(line)
        severity = issue.get("severity", "").lower()
        file_path = issue.get("location", {}).get("file", "")
        message = issue.get("problem", "")
        code = issue.get("code", "")
        line_num = issue.get("location", {}).get("range", {}).get("start", {}).get("line", 0)
        
        if severity == "error":
            error_count += 1
            if file_path not in errors_by_file:
                errors_by_file[file_path] = []
            errors_by_file[file_path].append(f"Line {line_num}: {message} ({code})")
        elif severity == "warning":
            warning_count += 1
    except:
        continue

with open("errors_grouped.txt", "w", encoding="utf-8") as f:
    f.write(f"SUMMARY: {error_count} Errors, {warning_count} Warnings\n\n")
    for file_path, file_errors in errors_by_file.items():
        rel_path = os.path.relpath(file_path) if os.path.isabs(file_path) else file_path
        f.write(f"FILE: {rel_path}\n")
        for err in file_errors:
            f.write(f"  {err}\n")
        f.write("-" * 40 + "\n")

print(f"Parsed {error_count} errors and {warning_count} warnings. Errors found in {len(errors_by_file)} files.")
