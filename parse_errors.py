import sys

# Using ignore errors to handle any strange characters in the machine output
with open("machine_out2.txt", "r", encoding="utf-8", errors="ignore") as f:
    lines = f.readlines()

issues = []
for line in lines:
    if line.strip() and not line.startswith("Starting") and not "Downloading" in line and not "Resolving" in line:
        issues.append(line.strip())

# Group errors by file
errors_by_file = {}
for issue in issues:
    parts = issue.split(" - ")
    if len(parts) >= 3:
        severity = parts[0].strip()
        file_info = parts[2].strip()
        file_path = file_info.split(":")[0]
        
        if severity == "error":
            if file_path not in errors_by_file:
                errors_by_file[file_path] = []
            errors_by_file[file_path].append(issue)

# Write parsed errors to a file for viewing
with open("errors_grouped.txt", "w", encoding="utf-8") as f:
    for file_path, file_errors in errors_by_file.items():
        f.write(f"FILE: {file_path}\n")
        for err in file_errors:
            f.write(f"  {err}\n")
        f.write("-" * 40 + "\n")

print(f"Parsed {len(issues)} issues. Found errors in {len(errors_by_file)} files.")
