import json

def update_arb(file_path, new_entries):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(new_entries)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

ar_entries = {
  "postToCommunity": "نشر في المجتمع",
  "orderNow": "اطلب الآن",
  "description": "الوصف",
  "productInfo": "تفاصيل المنتج",
  "ageGroup": "الفئة العمرية",
  "availableQty": "الكمية المتاحة",
  "availableSizes": "المقاسات المتوفرة",
  "shopProducts": "منتجات المتجر"
}

en_entries = {
  "postToCommunity": "Post to Community",
  "orderNow": "Order Now",
  "description": "Description",
  "productInfo": "Product Info",
  "ageGroup": "Age Group",
  "availableQty": "Available Qty",
  "availableSizes": "Available Sizes",
  "shopProducts": "Shop Products"
}

update_arb('sudan_free/lib/l10n/app_ar.arb', ar_entries)
update_arb('sudan_free/lib/l10n/app_en.arb', en_entries)
print("Updated .arb files with additional product keys")
