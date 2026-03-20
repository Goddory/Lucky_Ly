import os
import re

lib_dir = r"c:\Users\Admin\source\repos\Lucky_Ly\backend\lucky_ly_mobile\lib"
properties = ['primary', 'primaryLight', 'accent', 'bg', 'card', 'divider', 'textDark', 'textMuted', 'textLight', 'primaryGradient', 'accentGradient']

# Match AppTheme.primary but not AppTheme.of and not AppTheme.getTheme
pattern = re.compile(r'AppTheme\.(?P<prop>' + '|'.join(properties) + r')\b')

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = pattern.sub(r'AppTheme.of(context).\g<prop>', content)

    if new_content != content:
        print(f"Updated {file_path}")
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)

for root, _, files in os.walk(lib_dir):
    for filename in files:
        if filename.endswith(".dart") and filename != "app_theme.dart":
            process_file(os.path.join(root, filename))
