import os
import re

lib_dir = r"c:\Users\Admin\source\repos\Lucky_Ly\backend\lucky_ly_mobile\lib"

# This regex finds 'const ' followed by some word and '(' and then somewhere inside it has 'AppTheme.of(context)'
# Actually, since Dart formats cleanly, we can try to just replace 'const ' with '' on lines that have 'AppTheme.of'
# But `const ` might be on a previous line if formatted that way.
# A simpler brute-force regex for common ones:
# const Something(... AppTheme.of ...)
pattern1 = re.compile(r'const\s+([A-Z][a-zA-Z0-9_]*\s*\([^)]*AppTheme\.of\(context\)[^)]*\))')
pattern2 = re.compile(r'const\s+(BoxDecoration\s*\([^)]*AppTheme\.of\(context\)[^)]*\))')
pattern3 = re.compile(r'const\s+(Center\s*\([^)]*AppTheme\.of\(context\)[^)]*\))')
pattern4 = re.compile(r'const\s+(CircularProgressIndicator\s*\([^)]*AppTheme\.of\(context\)[^)]*\))')

def remove_const_on_line(line):
    if "AppTheme.of(context)" in line and "const " in line:
        return line.replace("const ", "")
    return line

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = content
    # Remove const on the same line
    lines = new_content.split('\n')
    lines = [remove_const_on_line(line) for line in lines]
    new_content = '\n'.join(lines)

    # Cross line const BoxDecorations or similar are harder but we can use regex
    # Actually just running format then fixing might be easier.
    # We can also do a multi-line regex
    new_content = re.sub(r'const\s+([A-Z]\w*\([^)]*?AppTheme\.of\(context\)[^)]*?\))', r'\1', new_content, flags=re.DOTALL)

    if new_content != content:
        print(f"Fixed const in {file_path}")
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)

for root, _, files in os.walk(lib_dir):
    for filename in files:
        if filename.endswith(".dart"):
            process_file(os.path.join(root, filename))
