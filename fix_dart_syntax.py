import os

lib_dir = 'lib'
for root, dirs, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            lines = content.split('\n')
            # Check the last 3 lines for a single stray character
            modified = False
            
            for i in range(len(lines)-1, max(-1, len(lines)-5), -1):
                stripped = lines[i].strip()
                if len(stripped) == 1 and stripped.isalpha() and stripped not in ['{', '}', ']', ')', ';', ':']:
                    lines[i] = lines[i].replace(stripped, '')
                    modified = True
            
            if modified:
                print(f"Fixed stray character in {path}")
                with open(path, 'w', encoding='utf-8') as new_file:
                    new_file.write('\n'.join(lines))
