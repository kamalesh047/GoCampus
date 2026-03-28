import re
import os

with open('dill_strings.txt', 'r', encoding='utf-8') as f:
    content = f.read()

blocks = content.split('\n---\n')

recovered_files = {}

for i in range(len(blocks)):
    block = blocks[i].strip()
    if block.startswith('file:///C:/Users/KAMALESH/.gemini/antigravity/scratch/go_campus/lib/') or \
       block[1:].startswith('file:///C:/Users/KAMALESH/.gemini/antigravity/scratch/go_campus/lib/'):
       
        # Extract the file path
        if block.startswith('file://'):
            uri = block
        else:
            uri = block[1:]
            
        file_path = uri.replace('file:///C:/Users/KAMALESH/.gemini/antigravity/scratch/go_campus/lib/', '')
        
        # The next block should be the source code
        if i + 1 < len(blocks):
            source_block = blocks[i+1]
            
            # Clean up potential LEB128 garbage at the very beginning
            # We look for the first valid Dart keyword at the start: import, class, //, @, void, enum
            # or we just remove the first character if it's a single letter before 'import' or 'class'
            
            # A simple regex to find the start of code
            m = re.search(r'(import |class |//|@|void |enum |mixin |abstract class |final class )', source_block[:20])
            if m:
                # remove everything before the match
                start_idx = m.start()
                # But wait, what if there are valid newlines or comments before?
                # Usually there's only 1 or 2 garbage chars.
                if start_idx <= 5:
                    source_block = source_block[start_idx:]
            
            recovered_files[file_path] = source_block

# Write them back
out_dir = 'lib_recovered_temp'
os.makedirs(out_dir, exist_ok=True)

for path, code in recovered_files.items():
    full_path = os.path.join(out_dir, path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(code)
        
print(f"Recovered {len(recovered_files)} files to {out_dir}")
