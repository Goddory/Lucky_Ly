import sys

try:
    with open('analyze_res.txt', 'r', encoding='utf-16le') as f:
        lines = f.readlines()
except:
    with open('analyze_res.txt', 'r', encoding='utf-8') as f:
        lines = f.readlines()

errors = [l.strip() for l in lines if 'error - ' in l]

print(f"Found {len(errors)} errors:")
for e in errors[:20]:  # print first 20 errors
    print(e)
