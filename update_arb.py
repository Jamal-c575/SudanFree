import json

def update_arb(file_path, new_entries):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    data.update(new_entries)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

ar_entries = {
  "seeAll": "عرض الكل",
  "contactMeViaWhatsapp": "تواصل معي عبر الواتساب، رأيت حسابك في منصة سودان فري",
  "typing": "يكتب الآن...",
  "onlineNow": "نشط الآن",
  "offline": "غير متصل",
  "lastSeen": "آخر ظهور",
  "image": "صورة",
  "file": "ملف",
  "recordingAudio": "جاري التسجيل...",
  "availableForWork": "متوفر للعمل",
  "currentlyUnavailable": "غير متوفر حالياً",
  "visibleToAll": "مرئي للجميع",
  "hiddenFromMap": "مخفي من الخريطة",
  "account": "الحساب",
  "appearance": "المظهر",
  "privacyAndSecurity": "الخصوصية والأمان",
  "chatWarning": "يفضل استخدام واتساب أو الاتصال المباشر للتواصل، الدردشة هنا فقط لإنشاء وتنسيق الاتفاقات لضمان حقوقك."
}

en_entries = {
  "seeAll": "See All",
  "contactMeViaWhatsapp": "Contact me via WhatsApp, I saw your profile on SudanFree",
  "typing": "Typing...",
  "onlineNow": "Online now",
  "offline": "Offline",
  "lastSeen": "Last seen",
  "image": "Image",
  "file": "File",
  "recordingAudio": "Recording...",
  "availableForWork": "Available for Work",
  "currentlyUnavailable": "Currently Unavailable",
  "visibleToAll": "Visible to all",
  "hiddenFromMap": "Hidden from map",
  "account": "Account",
  "appearance": "Appearance",
  "privacyAndSecurity": "Privacy and Security",
  "chatWarning": "It is recommended to use WhatsApp or direct call to communicate. Chat here is only to create agreements to ensure your rights."
}

update_arb('sudan_free/lib/l10n/app_ar.arb', ar_entries)
update_arb('sudan_free/lib/l10n/app_en.arb', en_entries)
print("Updated .arb files")
