import json
import re
import os
from collections import OrderedDict

dart_keywords = {
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch', 'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do', 'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external', 'factory', 'false', 'final', 'finally', 'for', 'Function', 'get', 'hide', 'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library', 'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow', 'return', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this', 'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with', 'yield'
}

def main():
    with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
        en_dict = json.load(f, object_pairs_hook=OrderedDict)
        
    with open('lib/l10n/app_ar.arb', 'r', encoding='utf-8') as f:
        ar_dict = json.load(f, object_pairs_hook=OrderedDict)
        
    key_mapping = {}
    
    new_en_dict = OrderedDict()
    new_ar_dict = OrderedDict()
    
    for k, v in en_dict.items():
        if k == "@@locale":
            new_en_dict[k] = v
            new_ar_dict[k] = ar_dict.get(k, "ar")
            continue
            
        new_key = k
        if k in dart_keywords:
            new_key = f"str{k.capitalize()}"
            key_mapping[k] = new_key
            
        new_en_dict[new_key] = v
        new_ar_dict[new_key] = ar_dict.get(k, v)
        
    with open('lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
        json.dump(new_en_dict, f, ensure_ascii=False, indent=2)
        
    with open('lib/l10n/app_ar.arb', 'w', encoding='utf-8') as f:
        json.dump(new_ar_dict, f, ensure_ascii=False, indent=2)
        
    print(f"Fixed {len(key_mapping)} keys: {key_mapping}")
    
    if not key_mapping:
        return
        
    for dirpath, _, filenames in os.walk('lib'):
        for f in filenames:
            if f.endswith('.dart'):
                filepath = os.path.join(dirpath, f)
                with open(filepath, 'r', encoding='utf-8') as file:
                    content = file.read()
                    
                new_content = content
                for old_k, new_k in key_mapping.items():
                    new_content = re.sub(r'AppLocalizations\.of\(context\)!.' + re.escape(old_k) + r'\b', f'AppLocalizations.of(context)!.{new_k}', new_content)
                    
                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as file:
                        file.write(new_content)

if __name__ == '__main__':
    main()
