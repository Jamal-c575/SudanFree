import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    if 'AppLocalizations' not in content:
        return False
        
    # Check if any app_localizations.dart is imported
    if re.search(r"import.*app_localizations\.dart';?", content):
        return False
        
    # Find the last import statement
    import_matches = list(re.finditer(r'^import .*?;$', content, re.MULTILINE))
    
    if not import_matches:
        return False
        
    last_import = import_matches[-1]
    import_stmt = "import 'package:sudan_free/l10n/generated/app_localizations.dart';"
    
    new_content = content[:last_import.end()] + '\n' + import_stmt + content[last_import.end():]
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    return True

def main():
    modified = 0
    for dirpath, _, filenames in os.walk('lib'):
        for f in filenames:
            if f.endswith('.dart'):
                if process_file(os.path.join(dirpath, f)):
                    modified += 1
                    
    print(f"Added imports to {modified} files.")

if __name__ == '__main__':
    main()
