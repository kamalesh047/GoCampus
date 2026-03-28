import sys

with open("machine_out.txt", "r", encoding="utf-8", errors="ignore") as f:
    lines = f.readlines()

issues = []
for line in lines:
    if line.strip() and not line.startswith("Starting") and not "Downloading" in line and not "Resolving" in line:
        issues.append(line.strip())

with open("machine_parsed.txt", "w", encoding="utf-8") as f:
    for issue in issues[:40]:
        f.write(issue + "\n")
