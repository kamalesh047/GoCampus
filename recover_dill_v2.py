import re
import os

with open('dill_strings.txt', 'r', encoding='utf-8') as f:
    content = f.read()

blocks = content.split('\n---\n')
recovered_files = {}

for i in range(len(blocks)):
    block = blocks[i].strip()
    match = re.search(r'file:///C:/Users/KAMALESH/\.gemini/antigravity/scratch/go_campus/lib/(.+?\.dart)', block)
    if match:
        file_path = match.group(1)
        
        # The next block should be the source code
        if i + 1 < len(blocks):
            source_block = blocks[i+1]
            
            # Clean up potential LEB128 garbage at the very beginning
            m = re.search(r'(import |class |//|@|void |enum |mixin |abstract |final )', source_block[:50])
            if m:
                start_idx = m.start()
                if start_idx <= 10:
                    source_block = source_block[start_idx:]
            
            recovered_files[file_path] = source_block

# Write them back
out_dir = 'lib_recovered_temp_v2'
os.makedirs(out_dir, exist_ok=True)

for path, code in recovered_files.items():
    full_path = os.path.join(out_dir, path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(code)
        
print(f"Recovered {len(recovered_files)} files to {out_dir}")
