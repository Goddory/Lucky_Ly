import os

lib_dir = "lib"

def find_matching_paren(text, start):
    count = 0
    for i in range(start, len(text)):
        if text[i] == '(':
            count += 1
        elif text[i] == ')':
            count -= 1
            if count == 0:
                return i
    return -1

def replace_loaders():
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart') and file != 'custom_loading.dart':
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                while True:
                    idx = content.find("CircularProgressIndicator(")
                    if idx == -1:
                        break
                    
                    # Also find any preceding 'const ' and strip it
                    prefix_idx = idx
                    if idx >= 6 and content[idx-6:idx] == 'const ':
                        prefix_idx = idx - 6
                    
                    paren_start = idx + 25
                    paren_end = find_matching_paren(content, paren_start)
                    
                    if paren_end != -1:
                        # Replace content[prefix_idx:paren_end+1] with "const CustomLoading(size: 80)"
                        content = content[:prefix_idx] + "const CustomLoading(size: 80)" + content[paren_end+1:]
                    else:
                        break
                
                if content != original_content:
                    import_statement = "import 'package:lucky_ly_mobile/widgets/custom_loading.dart';\n"
                    if import_statement not in content:
                        last_import_idx = content.rfind("import ")
                        if last_import_idx != -1:
                            end_of_line = content.find(";", last_import_idx)
                            if end_of_line != -1:
                                content = content[:end_of_line+1] + "\n" + import_statement + content[end_of_line+1:]
                        else:
                            content = import_statement + content
                            
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Updated {path}")

if __name__ == "__main__":
    replace_loaders()
