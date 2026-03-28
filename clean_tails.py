import os
import glob

files = glob.glob('lib/**/*.dart', recursive=True)
for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    modified = False
    
    # Check if the last character is not a closing brace, semicolon, newline or comment
    # Often the dill extraction left a single random char at the very end.
    if len(content) > 0:
        last_char = content[-1]
        
        # If it ends with something like 'f', '1', '3', '(', '>', etc.
        # Let's cleanly strip any non-whitespace characters after the last '}'
        # This is safe for MOST of our files, except maybe things that don't end in } (like files that end inside a class)
        # Actually it's safer to just strip the exact last character if it's not a whitespace and not a } or ;
        if last_char not in ['}', ';', '\n', ' ', '\r', '/']:
            # Strip it
            content = content[:-1]
            modified = True
            
        # Also let's check if the file ends with a trailing incomplete line like "f" or "1\n"
        # We can just look for everything after the LAST '}' and just clear it, if there are no other valid tokens.
        last_brace = content.rfind('}')
        if last_brace != -1:
            tail = content[last_brace+1:].strip()
            # If tail is weird garbage like "f", "1", "3", "(", ">"
            if len(tail) > 0 and len(tail) < 5:
                content = content[:last_brace+1] + '\n'
                modified = True

    if modified:
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
        print(f"Fixed tail of {f}")
