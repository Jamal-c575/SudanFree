import json

def update_arb(file_path, new_entries):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(new_entries)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

ar_entries = {
  "productLinkCopied": "تم نسخ رابط المنتج ✅",
  "shopNotFound": "حدث خطأ، المتجر غير موجود",
  "orderProductWhatsAppMessage": "مرحباً، أريد طلب هذا المنتج:\n{productName}\n{productUrl}\n\nهل هو متوفر؟",
  "@orderProductWhatsAppMessage": {
    "placeholders": {
      "productName": {"type": "String"},
      "productUrl": {"type": "String"}
    }
  },
  "orderNowVia": "اطلب الآن عبر",
  "whatsappNotFound": "لم يتم العثور على واتساب",
  "inAppChat": "محادثة داخل التطبيق",
  "errorOpeningChat": "حدث خطأ أثناء فتح المحادثة",
  "deleteProductPrompt": "هل تريد حذف هذا المنتج؟",
  "deleteProduct": "حذف المنتج",
  "minutesAgo": "منذ {minutes} دقيقة",
  "@minutesAgo": {
    "placeholders": {
      "minutes": {"type": "int"}
    }
  },
  "hoursAgo": "منذ {hours} ساعة",
  "@hoursAgo": {
    "placeholders": {
      "hours": {"type": "int"}
    }
  },
  "daysAgo": "منذ {days} يوم",
  "@daysAgo": {
    "placeholders": {
      "days": {"type": "int"}
    }
  },
  "detailsTitle": "التفاصيل",
  "replyingTo": "رداً على {name}",
  "@replyingTo": {
    "placeholders": {
      "name": {"type": "String"}
    }
  },
  "writeComment": "اكتب تعليقاً...",
  "commentsTitle": "التعليقات",
  "noCommentsYet": "لا توجد تعليقات بعد",
  "commentPosted": "تم نشر التعليق بنجاح",
  "errorPostingComment": "حدث خطأ أثناء نشر التعليق"
}

en_entries = {
  "productLinkCopied": "Product link copied ✅",
  "shopNotFound": "Shop not found",
  "orderProductWhatsAppMessage": "Hello, I want to order this product:\n{productName}\n{productUrl}\n\nIs it available?",
  "@orderProductWhatsAppMessage": {
    "placeholders": {
      "productName": {"type": "String"},
      "productUrl": {"type": "String"}
    }
  },
  "orderNowVia": "Order Now via",
  "whatsappNotFound": "WhatsApp not found",
  "inAppChat": "In-App Chat",
  "errorOpeningChat": "Error opening chat",
  "deleteProductPrompt": "Delete this product?",
  "deleteProduct": "Delete Product",
  "minutesAgo": "{minutes}m ago",
  "@minutesAgo": {
    "placeholders": {
      "minutes": {"type": "int"}
    }
  },
  "hoursAgo": "{hours}h ago",
  "@hoursAgo": {
    "placeholders": {
      "hours": {"type": "int"}
    }
  },
  "daysAgo": "{days}d ago",
  "@daysAgo": {
    "placeholders": {
      "days": {"type": "int"}
    }
  },
  "detailsTitle": "Details",
  "replyingTo": "Replying to {name}",
  "@replyingTo": {
    "placeholders": {
      "name": {"type": "String"}
    }
  },
  "writeComment": "Write a comment...",
  "commentsTitle": "Comments",
  "noCommentsYet": "No comments yet",
  "commentPosted": "Comment posted successfully",
  "errorPostingComment": "Error posting comment"
}

update_arb('sudan_free/lib/l10n/app_ar.arb', ar_entries)
update_arb('sudan_free/lib/l10n/app_en.arb', en_entries)
print("Updated .arb files with comment and product keys")
