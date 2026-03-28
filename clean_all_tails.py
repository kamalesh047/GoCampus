import os
import glob
import re

files = glob.glob('lib/**/*.dart', recursive=True)
for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Remove any trailing characters after the last valid closing brace or semicolon
    # that are not whitespace or comments.
    
    # Find last index of } or ;
    last_brace = content.rfind('}')
    last_semi = content.rfind(';')
    
    cutoff = max(last_brace, last_semi)
    if cutoff != -1:
        tail = content[cutoff+1:]
        # If the tail contains ONLY whitespace, leave it.
        # If it contains garbage (non-whitespace), strip it.
        if re.search(r'[^\s]', tail):
            content = content[:cutoff+1] + '\n'
            with open(f, 'w', encoding='utf-8') as file:
                file.write(content)
            print(f"Cleaned tail of {f}")
