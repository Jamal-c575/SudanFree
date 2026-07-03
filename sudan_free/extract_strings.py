import os
import re
import json

def generate_key(en_str):
    # Remove variables ($var or ${var})
    clean = re.sub(r'\$\{?[a-zA-Z0-9_.]+\}?', '', en_str)
    # Remove non-alphanumeric
    clean = re.sub(r'[^a-zA-Z0-9\s]', '', clean)
    words = clean.strip().split()
    if not words:
        return "dynamicString"
    
    # camelCase
    key = words[0].lower() + ''.join(word.capitalize() for word in words[1:5])
    return key

def extract_from_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern for isAr ? 'ar' : 'en' or locale == 'ar' ? 'ar' : 'en'
    # This regex is simplified and might not catch all edge cases (nested quotes, interpolation) 
    # but it will give us a huge head start.
    pattern = r"(?:locale\s*==\s*'ar'|isAr)\s*\?\s*(['\"])(.*?)(?<!\\)\1\s*:\s*(['\"])(.*?)(?<!\\)\3"
    
    matches = re.findall(pattern, content, flags=re.DOTALL)
    
    extracted = []
    for m in matches:
        ar_quote, ar_text, en_quote, en_text = m
        key = generate_key(en_text)
        extracted.append((key, ar_text, en_text))
        
    return extracted

def main():
    root_dir = './lib'
    all_extracted = []
    
    for dirpath, _, filenames in os.walk(root_dir):
        for f in filenames:
            if f.endswith('.dart'):
                extracted = extract_from_file(os.path.join(dirpath, f))
                all_extracted.extend(extracted)
                
    # Deduplicate by key
    en_dict = {}
    ar_dict = {}
    
    for key, ar_text, en_text in all_extracted:
        # Handle duplicates by appending number if different
        original_key = key
        counter = 1
        while key in en_dict and en_dict[key] != en_text:
            key = f"{original_key}{counter}"
            counter += 1
            
        en_dict[key] = en_text
        ar_dict[key] = ar_text

    print(f"Extracted {len(en_dict)} unique strings.")
    
    with open('extracted_en.json', 'w', encoding='utf-8') as f:
        json.dump(en_dict, f, ensure_ascii=False, indent=2)
        
    with open('extracted_ar.json', 'w', encoding='utf-8') as f:
        json.dump(ar_dict, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    main()
