import json

def update_arb(file_path, new_entries):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(new_entries)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

ar_entries = {
  "detailsTitle": "التفاصيل",
  "saveToFavorites": "حفظ في المفضلة",
  "writeACommentToMention": "اكتب تعليقاً... (أو استخدم @ للإشارة إلى أحدهم)",
  "copyComment": "نسخ التعليق",
  "copied": "تم النسخ",
  "writeAComment": "اكتب تعليقا..."
}

en_entries = {
  "detailsTitle": "Details",
  "saveToFavorites": "Save to Favorites",
  "writeACommentToMention": "Write a comment... (use @ to mention)",
  "copyComment": "Copy comment",
  "copied": "Copied",
  "writeAComment": "Write a comment..."
}

update_arb('sudan_free/lib/l10n/app_ar.arb', ar_entries)
update_arb('sudan_free/lib/l10n/app_en.arb', en_entries)
print("Updated .arb files")
