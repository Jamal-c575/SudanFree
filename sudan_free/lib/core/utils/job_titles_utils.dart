class JobTitlesUtils {
  static String getLocalizedTitle(String title, String locale) {
    final Map<String, String> enToAr = {
      // Traditional
      'Carpenter': 'نجار',
      'Plumber': 'سباك',
      'Electrician': 'كهربائي',
      'Blacksmith': 'حداد',
      'Painter': 'نقاش',
      'Builder': 'بناء',
      'Mechanic': 'ميكانيكي',
      'AC Technician': 'فني تكييف',
      'Satellite Technician': 'فني دش',
      'Tailor': 'خياط',
      'Barber': 'حلاق',
      'Chef': 'طباخ',
      'Driver': 'سائق',
      'Accountant': 'محاسب',
      'Lawyer': 'محامي',
      'Engineer': 'مهندس',
      'Doctor': 'طبيب',
      'Teacher': 'معلم',
      'Developer': 'مبرمج',
      'Graphic Designer': 'مصمم جرافيك',
      'Photographer': 'مصور',
      'Freelancer': 'حرفي',
      'Client': 'عميل',

      // Added Missing Titles
      'airConditioning': 'تكييف وتبريد',
      'carWash': 'غسيل سيارات',
      'carMaintenance': 'صيانة سيارات',
      'movingServices': 'نقل عفش',
      'driving': 'قيادة',
      'tourGuide': 'مرشد سياحي',
      'beauty': 'تجميل',
      'tailoring': 'خياطة وتفصيل',
      'cooking': 'طبخ',

      // Common categories
      'other': 'أخرى',
      'Other': 'أخرى',
      'electrical': 'كهرباء',
      'Electrical': 'كهرباء',
      'plumbing': 'سباكة',
      'Plumbing': 'سباكة',
      'carpentry': 'نجارة',
      'Carpentry': 'نجارة',
      'painting': 'دهان',
      'Painting': 'دهان',
      'mechanical': 'ميكانيكا',
      'Mechanical': 'ميكانيكا',
      'construction': 'بناء',
      'Construction': 'بناء',
      'cleaning': 'تنظيف',
      'Cleaning': 'تنظيف',
      'delivery': 'توصيل',
      'Delivery': 'توصيل',
      'technology': 'تقنية',
      'Technology': 'تقنية',

      // Tech Skills
      'mobileDevelopment': 'تطوير تطبيقات',
      'webDevelopment': 'تطوير مواقع',
      'design': 'تصميم',
      'writing': 'كتابة',
      'photography': 'تصوير',
      'tutoring': 'تدريس خصوصي',
      'teaching': 'تدريس',
      'dataEntry': 'إدخال بيانات',
      'applianceRepair': 'صيانة أجهزة منزلية',
      'graphicDesign': 'تصميم جرافيك',
      'videoEditing': 'مونتاج فيديو',
      'digitalMarketing': 'تسويق رقمي',
      'translation': 'ترجمة',
      'contentWriting': 'كتابة محتوى',
      'virtualAssistant': 'مساعد افتراضي',
      'projectManagement': 'إدارة مشاريع',
      'businessAnalysis': 'تحليل أعمال',
      'marketing': 'تسويق',
      'consulting': 'استشارات',
      'socialMedia': 'إدارة تواصل اجتماعي',
      'uiUxDesign': 'تصميم واجهات',
      'seo': 'تحسين محركات البحث',

      // Private / Specialized Services
      'privateTutoring': 'مدرس خصوصي',
      'teachingConsultant': 'مستشار تدريس',
      'eventCatering': 'تلبية طلبات مناسبات',
      'baker': 'فران',
      'pastryChef': 'بنكجي',
      'waiter': 'طاولجي',
      'clinicReception': 'استقبال عيادات',
      'appointmentBooking': 'حجز مواعيد',
      'clinicInquiry': 'استفسار عيادات',
      'lawyer': 'محامي',
      'chef': 'طباخ',
      'translator': 'مترجم',

      // Transport & Logistics
      'furnitureMoving': 'نقل أثاث',
      'goodsTransport': 'نقل بضائع',
      'privateRides': 'مشاوير خاصة / ترحيل',
      'vacuumTruck': 'شفط بالهواء',
      'buildingMaterialsTransport': 'نقل مواد بناء',
      'dumpTruckDirt': 'قلابات تراب',
      'dumpTruckSand': 'قلابات رملة',
      'dumpTruckConcrete': 'قلابات خرسانة',
    };

    if (locale == 'ar') {
      return enToAr[title] ?? title;
    } else {
      // Reverse mapping: Arabic to English
      final Map<String, String> arToEn = enToAr.map((k, v) => MapEntry(v, k));
      return arToEn[title] ?? title;
    }
  }
}
