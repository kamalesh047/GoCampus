import io

try:
    with open('analyze_out.txt', 'r', encoding='utf-16le') as f:
        content = f.read()
except:
    with open('analyze_out.txt', 'r', encoding='utf-8') as f:
        content = f.read()

import re
issues = [line.strip() for line in content.split('\n') if '-' in line and 'issues found' not in line]
for issue in issues:
    print(issue)
