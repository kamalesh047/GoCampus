import sys

with open("out.txt", "r", encoding="utf-16") as f:
    text = f.read()

for line in text.splitlines():
    if "info " in line or "warning " in line or "error " in line or ".dart" in line:
        print(line)
