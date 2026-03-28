import os

path = r'c:\Users\KAMALESH\.gemini\antigravity\scratch\go_campus\lib'
error_snippet = "if (snapshot.hasError) return Center(child: Text('DB Error: ${snapshot.error}\\nPlease check if Firestore is enabled and rules are public.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)));"

for root, dirs, files in os.walk(path):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # This is a naive injection, but it will help explicitly identify if a screen is failing
            content_lines = content.split('\n')
            new_lines = []
            for line in content_lines:
                new_lines.append(line)
                if 'builder: (context, snapshot) {' in line or 'builder: (context, busSnapshot) {' in line or 'builder: (context, complaintSnapshot) {' in line:
                    if 'snapshot.hasError' not in content:
                        new_lines.append("                " + error_snippet.replace('snapshot', line.split('(')[1].split(',')[1].split(')')[0].strip()))
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write('\n'.join(new_lines))
