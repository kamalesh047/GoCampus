import os
import re
import glob

def process_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content
        
        # Replace .withOpacity(x) -> .withValues(alpha: x)
        content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)

        # Replace print( -> debugPrint(
        content = re.sub(r'(\b)print\(', r'\1debugPrint(', content)

        if original != content:
            # Check if debugPrint is used and import foundation if needed
            if 'debugPrint(' in content and 'package:flutter/foundation.dart' not in content:
                # Add import right after the first import or package:flutter
                if 'import ' in content:
                    content = re.sub(r'(import .*?;)', r"\1\nimport 'package:flutter/foundation.dart';", content, count=1)
                else:
                    content = "import 'package:flutter/foundation.dart';\n" + content
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated {filepath}")
    except Exception as e:
        print(f"Failed to process {filepath}: {e}")

for filepath in glob.glob('lib/**/*.dart', recursive=True):
    process_file(filepath)
