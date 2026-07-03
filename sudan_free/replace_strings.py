import os
import re
import json
from collections import OrderedDict

def generate_key(en_str):
    # Remove non-alphanumeric
    clean = re.sub(r'[^a-zA-Z0-9\s]', '', en_str)
    words = clean.strip().split()
    if not words:
        return "dynamicString"
    
    key = words[0].lower() + ''.join(word.capitalize() for word in words[1:6])
    return key

def process_dart_file(filepath, en_dict, ar_dict):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # We look for simple string literals without interpolation ($)
    # isAr ? 'عربي' : 'English'
    # locale == 'ar' ? 'عربي' : 'English'
    
    # Pattern to match both isAr and locale == 'ar'
    # Group 1: isAr or locale == 'ar'
    # Group 2: quote for Arabic
    # Group 3: Arabic string
    # Group 4: quote for English
    # Group 5: English string
    pattern = r"(locale\s*==\s*['\"]ar['\"]|isAr)\s*\?\s*(['\"])(.*?)(?<!\\)\2\s*:\s*(['\"])(.*?)(?<!\\)\4"
    
    def replacer(match):
        condition = match.group(1)
        ar_quote = match.group(2)
        ar_text = match.group(3)
        en_quote = match.group(4)
        en_text = match.group(5)
        
        # Skip if there's string interpolation
        if '$' in ar_text or '$' in en_text:
            return match.group(0)
            
        key = generate_key(en_text)
        
        # Handle duplicate keys with different values
        original_key = key
        counter = 1
        while key in en_dict and en_dict[key] != en_text:
            if ar_dict.get(key) == ar_text and en_dict.get(key) == en_text:
                break
            key = f"{original_key}{counter}"
            counter += 1
            
        en_dict[key] = en_text
        ar_dict[key] = ar_text
        
        return f"AppLocalizations.of(context)!.{key}"
        
    new_content = re.sub(pattern, replacer, content)
    
    # Handle the reverse case: locale != 'ar' ? 'English' : 'عربي'
    # or !isAr ? 'English' : 'عربي'
    pattern_rev = r"(!isAr|locale\s*!=\s*['\"]ar['\"])\s*\?\s*(['\"])(.*?)(?<!\\)\2\s*:\s*(['\"])(.*?)(?<!\\)\4"
    
    def replacer_rev(match):
        condition = match.group(1)
        en_quote = match.group(2)
        en_text = match.group(3)
        ar_quote = match.group(4)
        ar_text = match.group(5)
        
        if '$' in ar_text or '$' in en_text:
            return match.group(0)
            
        key = generate_key(en_text)
        original_key = key
        counter = 1
        while key in en_dict and en_dict[key] != en_text:
            if ar_dict.get(key) == ar_text and en_dict.get(key) == en_text:
                break
            key = f"{original_key}{counter}"
            counter += 1
            
        en_dict[key] = en_text
        ar_dict[key] = ar_text
        
        return f"AppLocalizations.of(context)!.{key}"

    new_content = re.sub(pattern_rev, replacer_rev, new_content)
    
    # If the file changed, we might need to add import 'package:flutter_gen/gen_l10n/app_localizations.dart';
    # Actually, the user has AppLocalizations generated in lib/l10n/generated/app_localizations.dart or similar.
    # From previous grep: import '../../l10n/generated/app_localizations.dart' or something?
    # Let's just add import 'package:flutter_gen/gen_l10n/app_localizations.dart'; if it's not there.
    # Wait, in this project, it seems it's generated at `lib/l10n/generated/app_localizations.dart`.
    # Let's skip adding the import for now, we will run `flutter analyze` to see where it's missing and fix it iteratively.

    if new_content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

def main():
    root_dir = './lib'
    
    # Load existing ARB files
    with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
        en_dict = json.load(f, object_pairs_hook=OrderedDict)
        
    with open('lib/l10n/app_ar.arb', 'r', encoding='utf-8') as f:
        ar_dict = json.load(f, object_pairs_hook=OrderedDict)
        
    changed_files = 0
    for dirpath, _, filenames in os.walk(root_dir):
        for f in filenames:
            if f.endswith('.dart'):
                changed = process_dart_file(os.path.join(dirpath, f), en_dict, ar_dict)
                if changed:
                    changed_files += 1
                    print(f"Modified {f}")
                    
    print(f"Total files modified: {changed_files}")
    
    # Save back ARB files
    with open('lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
        json.dump(en_dict, f, ensure_ascii=False, indent=2)
        
    with open('lib/l10n/app_ar.arb', 'w', encoding='utf-8') as f:
        json.dump(ar_dict, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    main()
