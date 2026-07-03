import json

def update_arb(file_path, new_entries):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(new_entries)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

ar_entries = {
  "createAgreement": "إنشاء اتفاق",
  "fileSizeError": "حجم الملف كبير جداً، الحد الأقصى 10 ميجابايت",
  "filePickError": "حدث خطأ أثناء اختيار الملف",
  "directCall": "اتصال مباشر",
  "createAgreementChat": "إنشاء اتفاق (دردشة)",
  "contactWith": "تواصل مع {name}",
  "@contactWith": {
    "placeholders": {
      "name": {"type": "String"}
    }
  }
}

en_entries = {
  "createAgreement": "Create Agreement",
  "fileSizeError": "File size too large, maximum is 10 MB",
  "filePickError": "Error selecting file",
  "directCall": "Direct Call",
  "createAgreementChat": "Create Agreement (Chat)",
  "contactWith": "Contact {name}",
  "@contactWith": {
    "placeholders": {
      "name": {"type": "String"}
    }
  }
}

update_arb('sudan_free/lib/l10n/app_ar.arb', ar_entries)
update_arb('sudan_free/lib/l10n/app_en.arb', en_entries)
print("Updated .arb files with more keys")
