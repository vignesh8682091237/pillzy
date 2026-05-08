import os
import re

def replace_in_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace withValues(alpha: X) with withOpacity(X)
    new_content = re.sub(r'withValues\(alpha: ([0-9.]+)\)', r'withOpacity(\1)', content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated: {file_path}")

def walk_dir(path):
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.endswith('.dart'):
                replace_in_file(os.path.join(root, file))

if __name__ == "__main__":
    walk_dir('lib')
