import json

def update_arb(file_path, new_entries):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(new_entries)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

ar_entries = {
  "enabled": "مفعلة",
  "disabled": "متوقفة",
  "interestsSelected": "{count} اهتمام محدد",
  "@interestsSelected": {
    "placeholders": {
      "count": {"type": "int"}
    }
  }
}

en_entries = {
  "enabled": "Enabled",
  "disabled": "Disabled",
  "interestsSelected": "{count} interests selected",
  "@interestsSelected": {
    "placeholders": {
      "count": {"type": "int"}
    }
  }
}

update_arb('sudan_free/lib/l10n/app_ar.arb', ar_entries)
update_arb('sudan_free/lib/l10n/app_en.arb', en_entries)
print("Updated .arb files with more keys")
