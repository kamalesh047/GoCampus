import subprocess
import re

def strip_ansi(text):
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', text)

result = subprocess.run(['flutter', 'analyze'], capture_output=True, text=True, shell=True)

with open('clean_analyze.log', 'w', encoding='utf-8') as f:
    f.write(strip_ansi(result.stdout))
    f.write('\n')
    f.write(strip_ansi(result.stderr))
