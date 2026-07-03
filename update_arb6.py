import json

def update_arb(file_path, new_entries):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(new_entries)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

ar_entries = {
  "saveToFavorites": "حفظ للمفضلة",
  "productType": "منتج",
  "linkedProduct": "🛍️ منتج مرتبط",
  "buyProduct": "شراء المنتج",
  "like": "إعجاب",
  "comment": "تعليق",
  "share": "مشاركة"
}

en_entries = {
  "saveToFavorites": "Save to Favorites",
  "productType": "Product",
  "linkedProduct": "🛍️ Linked Product",
  "buyProduct": "Buy Product",
  "like": "Like",
  "comment": "Comment",
  "share": "Share"
}

update_arb('sudan_free/lib/l10n/app_ar.arb', ar_entries)
update_arb('sudan_free/lib/l10n/app_en.arb', en_entries)
print("Updated .arb files")
